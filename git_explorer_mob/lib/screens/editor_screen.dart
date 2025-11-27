import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: AppBar(
          // replace '' with unnamed file, add l10n
          title: Text(fileName.isNotEmpty ? fileName : '',
          style: TextStyle(fontSize: 15),
          ),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.save),
            //   style: ButtonStyle(
            //     iconSize: WidgetStateProperty.all(20),
            //   ),
            //   onPressed: () async {
            //     // Try to persist the current open file content to disk if available
            //     final prefs = Prefs();
            //     final filePath = prefs.currentOpenFile;
            //     if (filePath.isEmpty) {
            //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file open')));
            //       return;
            //     }
            //     try {
            //       final content = prefs.currentOpenFileContent;
            //       final f = File(filePath);
            //       await f.create(recursive: true);
            //       await f.writeAsString(content);
            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).commonSaved)));
            //     } catch (_) {
            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).commonFailed)));
            //     }
            //   },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.upload_file),
            //   style: ButtonStyle(
            //     iconSize: WidgetStateProperty.all(20),
            //   ),
            //   tooltip: 'Mark current file/project as opened',
            //   onPressed: () async {
            //     final prefs = Prefs();
            //     final filePath = prefs.currentOpenFile;
            //     if (filePath.isEmpty) {
            //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file open')));
            //       return;
            //     }
            //     final content = prefs.currentOpenFileContent;
            //     String projectPath = prefs.currentOpenProject;
            //     if (projectPath.isEmpty) {
            //       final idx = filePath.lastIndexOf('/');
            //       projectPath = idx > 0 ? filePath.substring(0, idx) : '';
            //     }
            //     await prefs.saveCurrentOpenFile(projectPath, filePath, content);
            //     if (projectPath.isNotEmpty) await prefs.saveLastOpenedProject(projectPath);
            //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as current open file/project')));
            //   },
            // ),
             IconButton(
              icon: const Icon(Icons.zoom_in),
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              padding: EdgeInsets.zero,
              style: ButtonStyle(
                iconSize: WidgetStateProperty.all(20),
              ),
              onPressed: () {
                if(prefs.editorFontSize < 37) prefs.saveEditorFontSize(prefs.editorFontSize + 2);
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              padding: EdgeInsets.zero,
              style: ButtonStyle(
                iconSize: WidgetStateProperty.all(20),
              ),
              onPressed: () {
                if(prefs.editorFontSize > 11) prefs.saveEditorFontSize(prefs.editorFontSize - 2);
              },
            ),
            prefs.codeFoldingEnabled ?
            IconButton(
              icon: const Icon(Icons.wrap_text),
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              padding: EdgeInsets.zero,
              style: ButtonStyle(
                iconSize: WidgetStateProperty.all(20),
              ),
              onPressed: () {
                if(prefs.editorWordWrap) {
                    prefs.saveEditorWordWrap(false);
                    return;
                }
                if(!prefs.editorWordWrap) {
                    prefs.saveEditorWordWrap(true);
                    return;
                }
              },
            ) : SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.numbers),
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              padding: EdgeInsets.zero,
              style: ButtonStyle(
                iconSize: WidgetStateProperty.all(20),
              ),
              onPressed: () {
                if(prefs.editorLineNumbers) {
                    prefs.saveEditorLineNumbers(false);
                    return;
                }
                if(!prefs.editorLineNumbers) {
                    prefs.saveEditorLineNumbers(true);
                    return;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.view_carousel),
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              padding: EdgeInsets.zero,
              style: ButtonStyle(
                iconSize: WidgetStateProperty.all(20),
              ),
              onPressed: () {
                if(prefs.editorMinimapEnabled) {
                    prefs.saveEditorMinimapEnabled(false);
                    return;
                }
                if(!prefs.editorMinimapEnabled) {
                    prefs.saveEditorMinimapEnabled(true);
                    return;
                }
              },
            ),
          ],
        ),
      ),
      body: const SafeArea(child: MonacoWrapper()),
    );
  }
}