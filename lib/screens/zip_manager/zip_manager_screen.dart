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
                    if (act == 'extract') await ref.read(zipManagerControllerProvider).extract(e.filename);
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
