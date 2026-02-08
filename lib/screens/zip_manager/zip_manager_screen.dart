import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rzv/l10n/generated/L10n.dart';
import 'package:rzv/providers/shared_preferences_provider.dart';
import 'package:rzv/utils/toast/common.dart';
import 'zip_manager_controller.dart';
import 'zip_download_controller.dart';
import 'zip_download_state.dart';
import '../../services/state/async_status.dart';
import '../../services/filesystem/zip_storage_manager.dart';

class ZipEntriesNotifier extends AutoDisposeAsyncNotifier<List<ZipEntry>> {
  @override
  Future<List<ZipEntry>> build() async {
    return await ZipStorageManager.instance.listZips();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ZipStorageManager.instance.listZips());
  }

  Future<void> addEntryFromPath(String path) async {
    try {
      final f = File(path);
      final stat = await f.stat();
      final filename = p.basename(path);
      final currentEntries = state.value ?? [];
      if (currentEntries.any((e) => e.filename == filename)) return;
      final entry = ZipEntry(
        filename: filename,
        size: stat.size,
        modified: stat.modified,
      );
      state = AsyncValue.data([entry, ...currentEntries]);
    } catch (_) {
      // If adding fails, reload the full list
      await reload();
    }
  }
}

final zipEntriesProvider = AutoDisposeAsyncNotifierProvider<ZipEntriesNotifier, List<ZipEntry>>(
  ZipEntriesNotifier.new,
);

class ZipManagerScreen extends ConsumerStatefulWidget {
  const ZipManagerScreen({super.key});

  @override
  ConsumerState<ZipManagerScreen> createState() => _ZipManagerScreenState();
}

class _ZipManagerScreenState extends ConsumerState<ZipManagerScreen> {
  final _downloadTc = TextEditingController();
  final _branchTc = TextEditingController();
  bool _registeredDownloadListener = false;
  ZipProvider _selectedProvider = ZipProvider.github;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _downloadTc.dispose();
    _branchTc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(zipManagerControllerProvider);

    if (!_registeredDownloadListener) {
      _registeredDownloadListener = true;
      ref.listen<ZipDownloadState>(
        zipDownloadControllerProvider.select((c) => c.state),
        (previous, next) async {
          if (next.status == AsyncStatus.success) {
            final saved = next.savedPath;
            if (saved != null) {
              await ref.read(zipEntriesProvider.notifier).addEntryFromPath(saved);
            } else {
              await ref.read(zipEntriesProvider.notifier).reload();
            }
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(L10n.of(context).zipManagerHeader), actions: [
        IconButton(onPressed: () => ref.read(zipEntriesProvider.notifier).reload(), icon: const Icon(Icons.refresh)),
        IconButton(onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
            title: Text(L10n.of(context).zipManagerMenuDeleteAllZips),
            content: Text(L10n.of(context).zipManagerMenuDeleteAllZipsHint),
            actions: [TextButton(onPressed: ()=>Navigator.of(c).pop(false), child: Text(L10n.of(context).commonCancel)), TextButton(onPressed: ()=>Navigator.of(c).pop(true), child: Text(L10n.of(context).commonDelete))],
          ));
          if (ok == true) {
            await ref.read(zipManagerControllerProvider).deleteAllZips();
            ref.read(zipEntriesProvider.notifier).reload();
          }
        }, icon: const Icon(Icons.delete_forever))
      ]),
      body: _buildBody(ctrl),
    );
  }

  Widget _buildBody(dynamic ctrl) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Consumer(builder: (c, ref, _) {
            var dlState = ref.watch(zipDownloadControllerProvider.select((c) => c.state));
            final downloadCtrlLocal = ref.read(zipDownloadControllerProvider);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                   Text(L10n.of(context).zipManagerDownloadZipTitle, style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _downloadTc,
                            decoration: InputDecoration(hintText: L10n.of(context).zipManagerDownloadZipHint),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: DropdownButton<ZipProvider>(
                            value: _selectedProvider,
                            underline: const SizedBox.shrink(),
                            items: [
                              DropdownMenuItem(
                                value: ZipProvider.github,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(radius: 10, backgroundColor: Colors.white, child: Image.asset('assets/images/zip_services/github.png')),
                                    SizedBox(width: 6),
                                    Text('GitHub', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: ZipProvider.gitlab,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(radius: 10, backgroundColor: WidgetStateColor.transparent, child: Image.asset('assets/images/zip_services/gitlab.png')),
                                    SizedBox(width: 6),
                                    Text('GitLab', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: ZipProvider.bitbucket,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(radius: 10, backgroundColor: WidgetStateColor.transparent, child: Image.asset('assets/images/zip_services/bitbucket.png')),
                                    SizedBox(width: 6),
                                    Text('Bitbucket', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _selectedProvider = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _branchTc,
                      decoration: InputDecoration(
                        hintText: L10n.of(context).zipManagerDownloadBranchHint,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DownloadProgressDisplay(
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Prefs().secondaryColor),
                            ),
                            onPressed: dlState.status == AsyncStatus.loading
                                ? null
                                : () {
                                    final input = _downloadTc.text.trim();
                                    if (input.isEmpty) return;
                                    final branch = _branchTc.text.trim();
                                    downloadCtrlLocal.download(input, provider: _selectedProvider, branch: branch.isEmpty ? null : branch);
                                  },
                            child: Text(L10n.of(context).commonDownload),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          style: ButtonStyle(
                            textStyle: WidgetStateProperty.all(TextStyle(
                              color: Prefs().accentColor,
                            ),
                            ),
                          ),
                          onPressed: dlState.status == AsyncStatus.loading ? () {
                            downloadCtrlLocal.cancel();
                            RZVToast.show(L10n.of(context).commonCanceled, duration: 2500);
                          } : null,
                          child: Text(L10n.of(context).commonCancel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          // ZIP list below
          const Expanded(
            child: ZipList(),
          ),
        ],
      ),
    );
  }
}

class ZipList extends ConsumerWidget {
  const ZipList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntries = ref.watch(zipEntriesProvider);
    return asyncEntries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(L10n.of(context).zipManagerErrorLoadingZips(err))),
      data: (entries) => entries.isEmpty
          ? Center(child: Text(L10n.of(context).zipManagerNoZipsDownloaded))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, idx) {
                final e = entries[idx];
                return ListTile(
                  title: Text(e.filename),
                  subtitle: Text('${(e.size/1024).toStringAsFixed(1)} KB · ${e.modified.toLocal()}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (act) async {
                      final manager = ref.read(zipManagerControllerProvider);
                      if (act == 'extract') {
                        // Show extraction progress dialog and call controller.extract with onProgress
                        StateSetter? dialogSetState;
                        BuildContext? dialogContext;
                        int extracted = 0;
                        int? total;
                        // bool cancelledByUser = false;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dc) {
                            dialogContext = dc;
                            return StatefulBuilder(builder: (context, StateSetter setState) {
                              dialogSetState = setState;
                              final value = (total != null && total! > 0) ? (extracted / total!) : null;
                              return AlertDialog(
                                title: Text(L10n.of(context).zipManagerExtracting(e.filename)),
                                content: SizedBox(
                                  width: 400,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      LinearProgressIndicator(value: value),
                                      const SizedBox(height: 12),
                                      Text(total != null ? '${_readable(extracted)} / ${_readable(total!)}' : _readable(extracted)),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // cancelledByUser = true;
                                      manager.cancel();
                                      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) Navigator.of(dialogContext!).pop();
                                    },
                                    child: Text(L10n.of(context).commonCancel, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                  )
                                ],
                              );
                            });
                          },
                        );

                        // Run extraction and update dialog via onProgress
                        try {
                          await manager.extract(e.filename, onProgress: (a, b) {
                            extracted = a;
                            total = b;
                            dialogSetState?.call(() {});
                          });
                        } catch (_) {}

                        // Close dialog if still open
                        if (dialogContext != null && Navigator.of(dialogContext!).canPop()) Navigator.of(dialogContext!).pop();
                        // Refresh list after extraction completes
                        RZVToast.show(L10n.of(context).zipManagerExtractedZip(e.filename), duration: 2500);
                        ref.read(zipEntriesProvider.notifier).reload();
                      }
                      if (act == 'delete') {
                        await ref.read(zipManagerControllerProvider).deleteZip(e.filename);
                        ref.read(zipEntriesProvider.notifier).reload();
                        RZVToast.show(L10n.of(context).zipManagerDeleteExtractedZip(e.filename), duration: 2500);
                      }
                      if (act == 'deleteExtracted') {
                        await ref.read(zipManagerControllerProvider).deleteExtraction(e.filename);
                        ref.read(zipEntriesProvider.notifier).reload();
                        RZVToast.show(L10n.of(context).zipManagerDeleteExtractedZip(e.filename), duration: 2500);

                      }
                      if (act == 'reExtract') {
                        await ref.read(zipManagerControllerProvider).reExtract(e.filename);
                        ref.read(zipEntriesProvider.notifier).reload();
                        RZVToast.show(L10n.of(context).zipManagerReExtractedZip(e.filename), duration: 2500);
                      }
                    },
                    itemBuilder: (c) => [
                      PopupMenuItem(value: 'extract', child: Text(L10n.of(context).zipManagerMenuExtract)),
                      PopupMenuItem(value: 'reExtract', child: Text(L10n.of(context).zipManagerMenuReextract)),
                      PopupMenuItem(value: 'delete', child: Text(L10n.of(context).commonDelete)),
                      PopupMenuItem(value: 'deleteExtracted', child: Text(L10n.of(context).zipManagerMenuDeleteExtracted)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _readable(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double b = bytes.toDouble();
    while (b >= 1024 && i < suffixes.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(b < 10 ? 2 : 1)} ${suffixes[i]}';
  }
}

class _DownloadProgressDisplay extends ConsumerWidget {
  const _DownloadProgressDisplay();

  String _human(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double b = bytes.toDouble();
    while (b >= 1024 && i < suffixes.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(b < 10 ? 2 : 1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zipDownloadControllerProvider.select((c) => c.state));
    if (state.status == AsyncStatus.loading) {
      final pct = (state.progress * 100).clamp(0.0, 100.0);
      final downloaded = state.downloadedBytes;
      final total = state.totalBytes;
      final cs = Theme.of(context).colorScheme;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total != null && total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 12,
                color: Colors.grey.shade300,
                child: LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth * state.progress.clamp(0.0, 1.0);
                  return Stack(children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ]);
                }),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show downloaded / total prominently
              if (total != null && total > 0)
                Text('${_human(downloaded)} / ${_human(total)}')
              else
                Text('${L10n.of(context).commonDownloading} ${_human(downloaded)}'),
              // Show percent on the right when available
              if (total != null && total > 0)
                Text('${pct.toStringAsFixed(1)}%')
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      );
    }

    if (state.status == AsyncStatus.success) {
      return Row(
        children: [
          Expanded(child: Text(state.message != null ? '${L10n.of(context).commonDone}: ${state.message}' : L10n.of(context).commonSaved)),
          const SizedBox(width: 8),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}