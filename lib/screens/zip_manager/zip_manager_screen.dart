import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'zip_manager_controller.dart';
import '../../services/filesystem/zip_storage_manager.dart';
import '../../services/filesystem/app_directories.dart';

class ZipManagerScreen extends ConsumerStatefulWidget {
  const ZipManagerScreen({super.key});

  @override
  ConsumerState<ZipManagerScreen> createState() => _ZipManagerScreenState();
}

class _ZipManagerScreenState extends ConsumerState<ZipManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(zipManagerControllerProvider).refresh());
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

    return Scaffold(
      appBar: AppBar(title: const Text('ZIP Manager'), actions: [
        IconButton(onPressed: () => ref.read(zipManagerControllerProvider).refresh(), icon: const Icon(Icons.refresh)),
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
    if (ctrl.status == null || ctrl.status == null) {}
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: FutureBuilder<List<ZipEntry>>(
        future: ZipStorageManager.instance.listZips(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No ZIPs downloaded'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final e = list[idx];
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
                    }
                    if (act == 'delete') await ref.read(zipManagerControllerProvider).deleteZip(e.filename);
                    if (act == 'deleteExtracted') await ref.read(zipManagerControllerProvider).deleteExtraction(e.filename);
                    if (act == 'reExtract') await ref.read(zipManagerControllerProvider).reExtract(e.filename);
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
        },
      ),
    );
  }
}
