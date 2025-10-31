import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _controller;
  // language is stored in Prefs; no local copy required here yet

  @override
  void initState() {
    super.initState();
    final p = Prefs();
  _controller = TextEditingController(text: p.currentOpenFileContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
  final filePath = prefs.currentOpenFile;
    final fileName = filePath.split('/').isNotEmpty ? filePath.split('/').last : filePath;

    // Use a simple multiline TextField editor for now. This is intentionally
    // compatible across platforms. We can swap to the `flutter_monaco` widget
    // when its API is confirmed in this project (it is included in pubspec).
    final editor = TextField(
      controller: _controller,
      maxLines: null,
      style: TextStyle(fontFamily: prefs.editorFontFamily, fontSize: prefs.editorFontSize),
      decoration: const InputDecoration(border: InputBorder.none),
      onChanged: (v) async {
        await Prefs().saveCurrentOpenFileContent(v);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName.isNotEmpty ? fileName : 'Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await Prefs().saveCurrentOpenFileContent(_controller.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File saved (in-memory)')));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: editor),
        ]),
      ),
    );
  }
}