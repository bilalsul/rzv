import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'zip_manager_controller.dart';
import 'zip_download_controller.dart';
import 'zip_download_state.dart';
import '../../services/state/async_status.dart';
import '../../services/filesystem/zip_storage_manager.dart';

class ZipManagerScreen extends ConsumerStatefulWidget {
  const ZipManagerScreen({super.key});

  @override
  ConsumerState<ZipManagerScreen> createState() => _ZipManagerScreenState();
}

class _ZipManagerScreenState extends ConsumerState<ZipManagerScreen> {
  final _downloadTc = TextEditingController();
  bool _registeredDownloadListener = false;
  bool _loadingEntries = false;
  List<ZipEntry> _entries = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadZips());
  }

  @override
  void dispose() {
    _downloadTc.dispose();
    super.dispose();
  }

  Future<void> _loadZips() async {
    setState(() => _loadingEntries = true);
    try {
      final list = await ZipStorageManager.instance.listZips();
      setState(() {
        _entries = list;
      });
    } catch (_) {
      setState(() => _entries = []);
    } finally {
      setState(() => _loadingEntries = false);
    }
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
        (previous, next) {
          if (next.status == AsyncStatus.success) {
            // Reload the local list so the newly downloaded file appears immediately.
            Future.microtask(() => _loadZips());
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ZIP Manager'), actions: [
      IconButton(onPressed: () => _loadZips(), icon: const Icon(Icons.refresh)),
        IconButton(onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
            title: const Text('Delete all ZIPs?'),
            content: const Text('This will delete all downloaded ZIP files.'),
            actions: [TextButton(onPressed: ()=>Navigator.of(c).pop(false), child: const Text('Cancel')), TextButton(onPressed: ()=>Navigator.of(c).pop(true), child: const Text('Delete'))],
          ));
          if (ok == true) await ref.read(zipManagerControllerProvider).deleteAllZips();
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
                    TextField(
                      controller: _downloadTc,
                      decoration: const InputDecoration(hintText: 'owner/repo'),
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
                                    downloadCtrlLocal.download(input);
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
          Expanded(
            child: _loadingEntries
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(child: Text('No ZIPs downloaded'))
                    : FutureBuilder(
                      future: ZipStorageManager.instance.listZips(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        return ListView.builder(
                            itemCount: _entries.length,
                            itemBuilder: (context, idx) {
                              final e = _entries[idx];
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
                          _loadZips();
                        }
                        if (act == 'delete') {
                          await ref.read(zipManagerControllerProvider).deleteZip(e.filename);
                          _loadZips();
                        }
                        if (act == 'deleteExtracted') {
                          await ref.read(zipManagerControllerProvider).deleteExtraction(e.filename);
                          _loadZips();
                        }
                        if (act == 'reExtract') {
                          await ref.read(zipManagerControllerProvider).reExtract(e.filename);
                          _loadZips();
                        }
                        setState(() {});
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
                                  );
                      }
                    ),
      ),
      ],
          ),
        );
        }
}

// }

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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 12,
              color: Colors.grey.shade300,
              child: total != null && total > 0
                  ? LayoutBuilder(builder: (context, constraints) {
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
                    })
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: LinearProgressIndicator(),
                    ),
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
                const Text('Downloading'),
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

    // Errors are shown via GzipToast from the controller; do not surface raw errors in UI

    return const SizedBox.shrink();
  }
}
