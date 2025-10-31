import 'package:flutter/material.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A small wrapper that exposes Monaco-like options driven from Prefs.
///
/// Currently this uses a multiline TextField fallback for broad compatibility.
/// When you want to switch to the real `flutter_monaco` widget, replace the
/// [_buildFallbackEditor] with the package widget and map the options.
class MonacoWrapper extends ConsumerStatefulWidget {
  const MonacoWrapper({super.key});

  @override
  ConsumerState<MonacoWrapper> createState() => _MonacoWrapperState();
}

class _MonacoWrapperState extends ConsumerState<MonacoWrapper> {
  late TextEditingController _controller;

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

  Widget _buildFallbackEditor(Prefs prefs) {
    final editorSettings = prefs.getEditorSettings();
    final fontFamily = editorSettings['fontFamily'] as String? ?? prefs.editorFontFamily;
    final fontSize = (editorSettings['fontSize'] as double?) ?? prefs.editorFontSize;

    return TextField(
      controller: _controller,
      maxLines: null,
      style: TextStyle(fontFamily: fontFamily, fontSize: fontSize),
      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
      onChanged: (v) async {
        await Prefs().saveCurrentOpenFileContent(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);

    // top bar with a few quick toggles (maps to Prefs flags)
    return Column(children: [
      Container(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          const SizedBox(width: 8),
          const Icon(Icons.code, size: 18),
          const SizedBox(width: 8),
          Text('Editor', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          // line numbers
          Row(children: [
            const Text('Line numbers'),
            const SizedBox(width: 6),
            DropdownButton<String>(
              value: prefs.editorLineNumbers,
              items: const [
                DropdownMenuItem(value: 'on', child: Text('On')),
                DropdownMenuItem(value: 'off', child: Text('Off')),
                DropdownMenuItem(value: 'relative', child: Text('Relative')),
              ],
              onChanged: (v) async { if (v != null) await prefs.saveEditorLineNumbers(v); setState(() {}); },
            ),
          ]),
          const SizedBox(width: 12),
          // minimap
          Row(children: [
            const Text('Minimap'),
            Switch(value: prefs.editorMinimapEnabled, onChanged: (v) async { await prefs.saveEditorMinimapEnabled(v); setState(() {}); }),
          ]),
          const SizedBox(width: 8),
        ]),
      ),
      Expanded(child: _buildFallbackEditor(prefs)),
    ]);
  }
}
