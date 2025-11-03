import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'dart:io';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/widgets/monaco/monaco_wrapper.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure Prefs reflects the current opened file and project when the editor mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPrefsWithCurrentFile();
    });
  }

  Future<void> _syncPrefsWithCurrentFile() async {
    try {
      final prefs = Prefs();
      final filePath = prefs.currentOpenFile;
      if (filePath.isEmpty) return;
      final content = prefs.currentOpenFileContent;
      // Derive project path as the parent directory of the file when possible
      String projectPath = prefs.currentOpenProject;
      if (projectPath.isEmpty) {
        final idx = filePath.lastIndexOf('/');
        projectPath = idx > 0 ? filePath.substring(0, idx) : '';
      }
      await prefs.saveCurrentOpenFile(projectPath, filePath, content);
      if (projectPath.isNotEmpty) await prefs.saveLastOpenedProject(projectPath);
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final filePath = prefs.currentOpenFile;
    final fileName = filePath.split('/').isNotEmpty ? filePath.split('/').last : filePath;

    return Scaffold(
      appBar: AppBar(
        // replace '' with unnamed file, add l10n
        title: Text(fileName.isNotEmpty ? fileName : ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // Try to persist the current open file content to disk if available
              final prefs = Prefs();
              final filePath = prefs.currentOpenFile;
              if (filePath.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file open')));
                return;
              }
              try {
                final content = prefs.currentOpenFileContent;
                final f = File(filePath);
                await f.create(recursive: true);
                await f.writeAsString(content);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).commonSaved)));
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).commonFailed)));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Mark current file/project as opened',
            onPressed: () async {
              final prefs = Prefs();
              final filePath = prefs.currentOpenFile;
              if (filePath.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file open')));
                return;
              }
              final content = prefs.currentOpenFileContent;
              String projectPath = prefs.currentOpenProject;
              if (projectPath.isEmpty) {
                final idx = filePath.lastIndexOf('/');
                projectPath = idx > 0 ? filePath.substring(0, idx) : '';
              }
              await prefs.saveCurrentOpenFile(projectPath, filePath, content);
              if (projectPath.isNotEmpty) await prefs.saveLastOpenedProject(projectPath);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as current open file/project')));
            },
          ),
        ],
      ),
      body: const SafeArea(child: MonacoWrapper()),
    );
  }
}