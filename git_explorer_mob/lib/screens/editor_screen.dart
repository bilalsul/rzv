import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/widgets/monaco/monaco_wrapper.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final filePath = prefs.currentOpenFile;
    final fileName = filePath.split('/').isNotEmpty ? filePath.split('/').last : filePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName.isNotEmpty ? fileName : 'Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // MonacoWrapper persists on change; keep parity with UI
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved (in-memory)')));
            },
          ),
        ],
      ),
      body: const SafeArea(child: MonacoWrapper()),
    );
  }
}