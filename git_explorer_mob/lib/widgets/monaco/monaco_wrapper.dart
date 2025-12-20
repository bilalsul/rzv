import 'dart:io';

import 'package:flutter/material.dart';
import 'package:git_explorer_mob/enums/options/plugin.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:git_explorer_mob/utils/extension/monaco_language_helper.dart';

/// A small wrapper that exposes Monaco-like options driven from Prefs.
///
/// Currently this uses a multiline TextField fallback for broad compatibility.
/// When you want to switch to the real `flutter_monaco` widget, replace the
/// [_buildFallbackEditor] with the package widget and map the options.
class MonacoWrapper extends ConsumerStatefulWidget {
  const MonacoWrapper({
    super.key,
    // required this.controller
  });

  // final ScrollController controller;
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
    return TextField(
      controller: _controller,
      maxLines: null,
      style: TextStyle(
        fontFamily: prefs.editorFontFamily,
        fontSize: prefs.editorFontSize,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
      onChanged: (v) async {
        await Prefs().saveCurrentOpenFileContent(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final double screenHeight = MediaQuery.of(context).size.height;
    final containerHeight = screenHeight - 220;

    // top bar with a few quick toggles (maps to Prefs flags)
    return  
      // children: [
        // SingleChildScrollView(
          // controller: widget.controller,
          // physics: ClampingScrollPhysics(),
          // child: 
          // Expanded(
          //   child: Container(
          //     // color: Theme.of(
          //     //   context,
          //     // ).colorScheme.surfaceVariant.withOpacity(0.04),
          //     color: Colors.black,
          //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              // child: Row(children: [
              //   const SizedBox(width: 8),
              //   const Icon(Icons.code, size: 18),
              //   const SizedBox(width: 8),
              //   Text('Editor', style: Theme.of(context).textTheme.titleMedium),
              //   const Spacer(),
              //   // line numbers
              //   Row(children: [
              //     const Text('Line numbers'),
              //     const SizedBox(width: 6),
              //     DropdownButton<String>(
              //       value: prefs.editorLineNumbers,
              //       items: const [
              //         DropdownMenuItem(value: 'on', child: Text('On')),
              //         DropdownMenuItem(value: 'off', child: Text('Off')),
              //         DropdownMenuItem(value: 'relative', child: Text('Relative')),
              //       ],
              //       onChanged: (v) async { if (v != null) await prefs.saveEditorLineNumbers(v); setState(() {}); },
              //     ),
              //   ]),
              //   const SizedBox(width: 12),
              //   // minimap
              //   Row(children: [
              //     const Text('Minimap'),
              //     Switch(value: prefs.editorMinimapEnabled, onChanged: (v) async { await prefs.saveEditorMinimapEnabled(v); setState(() {}); }),
              //   ]),
              //   const SizedBox(width: 8),
              // ]),
          //   ),
          // ),
        // ),
      Platform.isAndroid || Platform.isIOS
              ? MonacoEditor(
                  constraints: BoxConstraints.tight(Size.fromHeight(containerHeight)),
                    onFocus: () {
                      // Hide keyboard on focus to avoid showing it on mobile
                      FocusScope.of(context).unfocus();
                    },
                    initialValue: prefs.currentOpenFile.isEmpty
                        ? prefs.filePlaceholder(context)
                        : prefs.currentOpenFileContent,
                    onContentChanged: (value) =>
                        prefs.saveCurrentOpenFileContent(value),
                    options: EditorOptions(
                      language:
                          prefs.isPluginEnabled(Plugin.syntaxHighlighting.id)
                          ? prefs.currentOpenFile.toMonacoLanguage()
                          : MonacoLanguage.plaintext,
                      lineNumbers: prefs.isPluginEnabled(
                        Plugin.editorLineNumbers.id,
                      ),
                      minimap: prefs.isPluginEnabled(Plugin.editorMinimap.id),
                      readOnly: true,
                      fontFamily: prefs.editorFontFamily,
                      fontSize: prefs.editorFontSize,
                      wordWrap: prefs.isPluginEnabled(Plugin.editorWordWrap.id),
                      renderControlCharacters: prefs.isPluginEnabled(
                        Plugin.editorRenderControlCharacters.id,
                      ),
                    ),
                  )
              : _buildFallbackEditor(prefs);
      // ],
  }
}

/*
 (new) MonacoEditor MonacoEditor({
  Key? key,
  MonacoController? controller,
  String? initialValue,
  EditorOptions options = const EditorOptions(),
  Range? initialSelection,
  bool autofocus = false,
  String? customCss,
  bool allowCdnFonts = false,
  Duration? readyTimeout,
  void Function(MonacoController)? onReady,
  void Function(String)? onContentChanged,
  void Function(bool)? onRawContentChanged,
  bool fullTextOnFlushOnly = false,
  Duration contentDebounce = const Duration(milliseconds: 120),
  void Function(Range?)? onSelectionChanged,
  void Function()? onFocus,
  void Function()? onBlur,
  void Function(LiveStats)? onLiveStats,
  Widget Function(BuildContext)? loadingBuilder,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  bool showStatusBar = false,
  Widget Function(BuildContext, LiveStats)? statusBarBuilder,
  Color? backgroundColor,
  EdgeInsetsGeometry? padding,
  BoxConstraints? constraints,
  });

  ==========================================================

  EditorOptions EditorOptions({
  MonacoLanguage language,
  MonacoTheme theme,
  double fontSize,
  String fontFamily,
  double lineHeight,
  bool wordWrap,
  bool minimap,
  bool lineNumbers,
  List<int> rulers,
  int tabSize,
  bool insertSpaces,
  bool readOnly,
  bool automaticLayout,
  Map<String, int>? padding,
  bool scrollBeyondLastLine,
  bool smoothScrolling,
  CursorBlinking cursorBlinking,
  CursorStyle cursorStyle,
  RenderWhitespace renderWhitespace,
  bool bracketPairColorization,
  AutoClosingBehavior autoClosingBrackets,
  AutoClosingBehavior autoClosingQuotes,
  bool formatOnPaste,
  bool formatOnType,
  bool quickSuggestions,
  bool fontLigatures,
  bool parameterHints,
  bool hover,
  bool contextMenu,
  bool mouseWheelZoom,
  bool roundedSelection,
  bool selectionHighlight,
  bool overviewRulerBorder,
  bool renderControlCharacters,
  bool disableLayerHinting,
  bool disableMonospaceOptimizations,
});

 */
