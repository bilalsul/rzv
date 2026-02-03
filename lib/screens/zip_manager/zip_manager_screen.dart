import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      if (!await f.exists()) return;
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
  bool _registeredDownloadListener = false;
  ZipProvider _selectedProvider = ZipProvider.github;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _downloadTc.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(zipManagerControllerProvider);

    // Register a listener for download completion during build (allowed here).
    if (!_registeredDownloadListener) {
      _registeredDownloadListener = true;
      ref.listen<ZipDownloadState>(
        zipDownloadControllerProvider.select((c) => c.state),
        (previous, next) async {
          if (next.status == AsyncStatus.success) {
            // If we have the saved path from the download, try to append a new entry
            // directly to the list to avoid a full reload UI.
            final saved = next.savedPath;
            if (saved != null) {
              await ref.read(zipEntriesProvider.notifier).addEntryFromPath(saved);
            } else {
              // Fallback: reload the list so the newly downloaded file appears.
              await ref.read(zipEntriesProvider.notifier).reload();
            }
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ZIP Manager'), actions: [
        IconButton(onPressed: () => ref.read(zipEntriesProvider.notifier).reload(), icon: const Icon(Icons.refresh)),
        IconButton(onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
            title: const Text('Delete all ZIPs?'),
            content: const Text('This will delete all downloaded ZIP files.'),
            actions: [TextButton(onPressed: ()=>Navigator.of(c).pop(false), child: const Text('Cancel')), TextButton(onPressed: ()=>Navigator.of(c).pop(true), child: const Text('Delete'))],
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
    // Combine download UI above the ZIP list
    final downloadCtrl = ref.read(zipDownloadControllerProvider);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Download area (keeps progress updates local to this Consumer)
          Consumer(builder: (c, ref, _) {
            final dlState = ref.watch(zipDownloadControllerProvider.select((c) => c.state));
            final downloadCtrlLocal = ref.read(zipDownloadControllerProvider);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Download ZIP (owner/repo)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _downloadTc,
                            decoration: const InputDecoration(hintText: 'owner/repo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Provider dropdown (small)
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
                    const SizedBox(height: 12),
                    _DownloadProgressDisplay(state: dlState),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: dlState.status == AsyncStatus.loading
                                ? null
                                : () {
                                    final input = _downloadTc.text.trim();
                                    if (input.isEmpty) return;
                                    downloadCtrlLocal.download(input, provider: _selectedProvider);
                                  },
                            child: const Text('Download'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: dlState.status == AsyncStatus.loading ? () => downloadCtrlLocal.cancel() : null,
                          child: const Text('Cancel'),
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
      error: (err, stack) => Center(child: Text('Error loading ZIPs: $err')),
      data: (entries) => entries.isEmpty
          ? const Center(child: Text('No ZIPs downloaded'))
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
                        bool cancelledByUser = false;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dc) {
                            dialogContext = dc;
                            return StatefulBuilder(builder: (context, StateSetter setState) {
                              dialogSetState = setState;
                              final value = (total != null && total! > 0) ? (extracted / total!) : null;
                              return AlertDialog(
                                title: Text('Extracting ${e.filename}'),
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
                                      cancelledByUser = true;
                                      manager.cancel();
                                      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) Navigator.of(dialogContext!).pop();
                                    },
                                    child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                        ref.read(zipEntriesProvider.notifier).reload();
                      }
                      if (act == 'delete') {
                        await ref.read(zipManagerControllerProvider).deleteZip(e.filename);
                        ref.read(zipEntriesProvider.notifier).reload();
                      }
                      if (act == 'deleteExtracted') {
                        await ref.read(zipManagerControllerProvider).deleteExtraction(e.filename);
                        ref.read(zipEntriesProvider.notifier).reload();
                      }
                      if (act == 'reExtract') {
                        await ref.read(zipManagerControllerProvider).reExtract(e.filename);
                        ref.read(zipEntriesProvider.notifier).reload();
                      }
                    },
                    itemBuilder: (c) => [
                      const PopupMenuItem(value: 'extract', child: Text('Extract')),
                      const PopupMenuItem(value: 'reExtract', child: Text('Re-extract')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete ZIP')),
                      const PopupMenuItem(value: 'deleteExtracted', child: Text('Delete Extracted')),
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

class _DownloadProgressDisplay extends StatelessWidget {
  final ZipDownloadState state;

  const _DownloadProgressDisplay({required this.state});

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
  Widget build(BuildContext context) {
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
                Text('Downloading ${_human(downloaded)}'),
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
          Expanded(child: Text(state.message != null ? 'Downloaded: ${state.message}' : 'Saved')),
          const SizedBox(width: 8),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}