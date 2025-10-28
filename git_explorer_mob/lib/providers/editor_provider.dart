import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditorSettings {
  final String monacoTheme;
  final double fontSize;
  final String fontFamily;
  final int tabSize;
  final bool insertSpaces;
  final String wordWrap;
  final String lineNumbers;
  final bool minimapEnabled;
  final bool autoIndent;
  final bool matchBrackets;
  final bool codeLens;
  final bool autoSave;
  final int autoSaveDelay;
  final bool formatOnSave;
  final bool trimTrailingWhitespace;
  final bool insertFinalNewline;
  final String cursorStyle;
  final String cursorBlinking;
  final String renderWhitespace;
  final bool renderControlCharacters;

  const EditorSettings({
    this.monacoTheme = 'vs-dark',
    this.fontSize = 14.0,
    this.fontFamily = 'Fira Code, Monaco, Menlo, Consolas',
    this.tabSize = 2,
    this.insertSpaces = true,
    this.wordWrap = 'on',
    this.lineNumbers = 'on',
    this.minimapEnabled = true,
    this.autoIndent = true,
    this.matchBrackets = true,
    this.codeLens = false,
    this.autoSave = true,
    this.autoSaveDelay = 1000,
    this.formatOnSave = false,
    this.trimTrailingWhitespace = false,
    this.insertFinalNewline = true,
    this.cursorStyle = 'line',
    this.cursorBlinking = 'blink',
    this.renderWhitespace = 'none',
    this.renderControlCharacters = false,
  });

  EditorSettings copyWith({
    String? monacoTheme,
    double? fontSize,
    String? fontFamily,
    int? tabSize,
    bool? insertSpaces,
    String? wordWrap,
    String? lineNumbers,
    bool? minimapEnabled,
    bool? autoIndent,
    bool? matchBrackets,
    bool? codeLens,
    bool? autoSave,
    int? autoSaveDelay,
    bool? formatOnSave,
    bool? trimTrailingWhitespace,
    bool? insertFinalNewline,
    String? cursorStyle,
    String? cursorBlinking,
    String? renderWhitespace,
    bool? renderControlCharacters,
  }) {
    return EditorSettings(
      monacoTheme: monacoTheme ?? this.monacoTheme,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      tabSize: tabSize ?? this.tabSize,
      insertSpaces: insertSpaces ?? this.insertSpaces,
      wordWrap: wordWrap ?? this.wordWrap,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      minimapEnabled: minimapEnabled ?? this.minimapEnabled,
      autoIndent: autoIndent ?? this.autoIndent,
      matchBrackets: matchBrackets ?? this.matchBrackets,
      codeLens: codeLens ?? this.codeLens,
      autoSave: autoSave ?? this.autoSave,
      autoSaveDelay: autoSaveDelay ?? this.autoSaveDelay,
      formatOnSave: formatOnSave ?? this.formatOnSave,
      trimTrailingWhitespace: trimTrailingWhitespace ?? this.trimTrailingWhitespace,
      insertFinalNewline: insertFinalNewline ?? this.insertFinalNewline,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      cursorBlinking: cursorBlinking ?? this.cursorBlinking,
      renderWhitespace: renderWhitespace ?? this.renderWhitespace,
      renderControlCharacters: renderControlCharacters ?? this.renderControlCharacters,
    );
  }

  static EditorSettings fromPreferences(SharedPreferences prefs) {
    return EditorSettings(
      monacoTheme: prefs.getString('editor_monaco_theme') ?? 'vs-dark',
      fontSize: prefs.getDouble('editor_font_size') ?? 14.0,
      fontFamily: prefs.getString('editor_font_family') ?? 'Fira Code, Monaco, Menlo, Consolas',
      tabSize: prefs.getInt('editor_tab_size') ?? 2,
      insertSpaces: prefs.getBool('editor_insert_spaces') ?? true,
      wordWrap: prefs.getString('editor_word_wrap') ?? 'on',
      lineNumbers: prefs.getString('editor_line_numbers') ?? 'on',
      minimapEnabled: prefs.getBool('editor_minimap_enabled') ?? true,
      autoIndent: prefs.getBool('editor_auto_indent') ?? true,
      matchBrackets: prefs.getBool('editor_match_brackets') ?? true,
      codeLens: prefs.getBool('editor_code_lens') ?? false,
      autoSave: prefs.getBool('editor_auto_save') ?? true,
      autoSaveDelay: prefs.getInt('editor_auto_save_delay') ?? 1000,
      formatOnSave: prefs.getBool('editor_format_on_save') ?? false,
      trimTrailingWhitespace: prefs.getBool('editor_trim_trailing_whitespace') ?? false,
      insertFinalNewline: prefs.getBool('editor_insert_final_newline') ?? true,
      cursorStyle: prefs.getString('editor_cursor_style') ?? 'line',
      cursorBlinking: prefs.getString('editor_cursor_blinking') ?? 'blink',
      renderWhitespace: prefs.getString('editor_render_whitespace') ?? 'none',
      renderControlCharacters: prefs.getBool('editor_render_control_characters') ?? false,
    );
  }

  Future<void> saveToPreferences(SharedPreferences prefs) async {
    await prefs.setString('editor_monaco_theme', monacoTheme);
    await prefs.setDouble('editor_font_size', fontSize);
    await prefs.setString('editor_font_family', fontFamily);
    await prefs.setInt('editor_tab_size', tabSize);
    await prefs.setBool('editor_insert_spaces', insertSpaces);
    await prefs.setString('editor_word_wrap', wordWrap);
    await prefs.setString('editor_line_numbers', lineNumbers);
    await prefs.setBool('editor_minimap_enabled', minimapEnabled);
    await prefs.setBool('editor_auto_indent', autoIndent);
    await prefs.setBool('editor_match_brackets', matchBrackets);
    await prefs.setBool('editor_code_lens', codeLens);
    await prefs.setBool('editor_auto_save', autoSave);
    await prefs.setInt('editor_auto_save_delay', autoSaveDelay);
    await prefs.setBool('editor_format_on_save', formatOnSave);
    await prefs.setBool('editor_trim_trailing_whitespace', trimTrailingWhitespace);
    await prefs.setBool('editor_insert_final_newline', insertFinalNewline);
    await prefs.setString('editor_cursor_style', cursorStyle);
    await prefs.setString('editor_cursor_blinking', cursorBlinking);
    await prefs.setString('editor_render_whitespace', renderWhitespace);
    await prefs.setBool('editor_render_control_characters', renderControlCharacters);
  }
}

class EditorSettingsNotifier extends StateNotifier<EditorSettings> {
  final Ref ref;

  EditorSettingsNotifier(this.ref) : super(const EditorSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = EditorSettings.fromPreferences(prefs);
  }

  Future<void> updateSettings(EditorSettings newSettings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await newSettings.saveToPreferences(prefs);
    state = newSettings;
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = const EditorSettings();
    await updateSettings(defaultSettings);
  }
}

final editorSettingsProvider = StateNotifierProvider<EditorSettingsNotifier, EditorSettings>(
  (ref) => EditorSettingsNotifier(ref),
);
