import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:rzv/enums/options/plugin.dart';
import 'package:rzv/l10n/generated/L10n.dart';
import 'package:rzv/providers/shared_preferences_provider.dart';
import 'package:rzv/widgets/monaco/monaco_wrapper.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    this.onClose,
    required this.status
  });

  final VoidCallback? onClose;
  final bool status;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final filePath = prefs.currentOpenFile;
    final fileName = filePath.split('/').isNotEmpty
        ? filePath.split('/').last
        : filePath;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          leading: widget.onClose != null
              ? IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: widget.onClose,
                  tooltip: L10n.of(context).commonClose,
                )
              : null,
          title: Text(
            fileName.isNotEmpty ? fileName : '',
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            // overflow: TextOverflow.ellipsis,
          ),
          titleSpacing: 0,
          // centerTitle: true,
          actions: [
            if (prefs.lockEditor)
              IconButton(
                enableFeedback: false,
                icon: const Icon(Icons.lock),
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                padding: EdgeInsets.zero,
                style: ButtonStyle(iconSize: WidgetStateProperty.all(20)),
                onPressed: () {
                  if (prefs.lockEditor) prefs.saveLockEditor(false);
                },
              )
            else
              IconButton(
                enableFeedback: false,
                icon: const Icon(Icons.lock_open),
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                padding: EdgeInsets.zero,
                style: ButtonStyle(iconSize: WidgetStateProperty.all(20)),
                onPressed: () {
                  if (!prefs.lockEditor) prefs.saveLockEditor(true);
                },
              ),
            if (prefs.isPluginEnabled(Plugin.editorZoomInOut.id))
              IconButton(
                enableFeedback: false,
                icon: const Icon(Icons.zoom_in),
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                padding: EdgeInsets.zero,
                style: ButtonStyle(iconSize: WidgetStateProperty.all(20)),
                onPressed: () {
                  if (prefs.editorFontSize < 37)
                    prefs.saveEditorFontSize(prefs.editorFontSize + 2);
                },
              ),
            if (prefs.isPluginEnabled(Plugin.editorZoomInOut.id))
              IconButton(
                enableFeedback: false,
                icon: const Icon(Icons.zoom_out),
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                padding: EdgeInsets.zero,
                style: ButtonStyle(iconSize: WidgetStateProperty.all(20)),
                onPressed: () {
                  if (prefs.editorFontSize > 11)
                    prefs.saveEditorFontSize(prefs.editorFontSize - 2);
                },
              ),
            IconButton(
              enableFeedback: false,
              icon: const Icon(Icons.wrap_text),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              padding: EdgeInsets.zero,
              style: ButtonStyle(iconSize: WidgetStateProperty.all(20)),
              onPressed: () {
                if (prefs.isPluginEnabled(Plugin.editorWordWrap.id)) {
                  prefs.setPluginEnabled(Plugin.editorWordWrap.id, false);
                } else {
                  prefs.setPluginEnabled(Plugin.editorWordWrap.id, true);
                }
              },
            ),
            IconButton(
              enableFeedback: false,
              icon: const Icon(Icons.numbers),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              padding: EdgeInsets.zero,
              style: ButtonStyle(iconSize: WidgetStateProperty.all(20)),
              onPressed: () {
                if (prefs.isPluginEnabled(Plugin.editorLineNumbers.id)) {
                  prefs.setPluginEnabled(Plugin.editorLineNumbers.id, false);
                } else {
                  prefs.setPluginEnabled(Plugin.editorLineNumbers.id, true);
                }
              },
            ),
            IconButton(
              enableFeedback: false,
              icon: const Icon(Icons.view_carousel),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              padding: const EdgeInsets.only(right: 15, left: 5),
              style: ButtonStyle(iconSize: WidgetStateProperty.all(20)),
              onPressed: () {
                if (prefs.isPluginEnabled(Plugin.editorMinimap.id)) {
                  prefs.setPluginEnabled(Plugin.editorMinimap.id, false);
                } else {
                  prefs.setPluginEnabled(Plugin.editorMinimap.id, true);
                }
              },
            ),
          ],
        ),
      ),
      body: MonacoWrapper(status: widget.status,),
    );
  }
}