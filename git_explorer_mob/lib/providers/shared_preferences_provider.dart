import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/enums/options/screen.dart';
// Other providers removed; Prefs is now the central settings source.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// =============================================
// SharedPreferences Provider
// =============================================

/// Main provider that gives access to SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Expose the Prefs singleton as a ChangeNotifierProvider so widgets can
/// watch preference changes with `ref.watch(prefsProvider)`.
final prefsProvider = ChangeNotifierProvider<Prefs>((ref) => Prefs());

class Prefs extends ChangeNotifier {
  late SharedPreferences prefs;
  // Secure storage for sensitive values such as API keys
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static final Prefs _instance = Prefs._internal();

  factory Prefs() {
    return _instance;
  }

  // -------------------------------
  // Secure plugin API key helpers
  // -------------------------------
  /// Store a plugin API key securely and set a flag in SharedPreferences
  Future<void> setPluginApiKey(String pluginId, String apiKey) async {
    final key = 'plugin_${pluginId}_api_key';
    await _secureStorage.write(key: key, value: apiKey);
    await prefs.setBool('plugin_${pluginId}_has_api_key', true);
    notifyListeners();
  }

  /// Read a plugin API key from secure storage (may be null if not set)
  Future<String?> getPluginApiKey(String pluginId) async {
    final key = 'plugin_${pluginId}_api_key';
    return await _secureStorage.read(key: key);
  }

  /// Returns whether an API key is present for the plugin (fast, synchronous)
  bool hasPluginApiKey(String pluginId) {
    return prefs.getBool('plugin_${pluginId}_has_api_key') ?? false;
  }

  /// Remove the plugin API key and clear the flag
  Future<void> removePluginApiKey(String pluginId) async {
    final key = 'plugin_${pluginId}_api_key';
    await _secureStorage.delete(key: key);
    await prefs.remove('plugin_${pluginId}_has_api_key');
    notifyListeners();
  }

  Prefs._internal() {
    initPrefs();
  }


  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> clearPrefs() async {
      await prefs.clear(); 
  }

  // for testing purposes
  String getValue(String value){
    return prefs.getString(value) ?? "whatt?";
  }

  List<String> getValueList(String listName) {
    return prefs.getStringList(listName)?? [];
  }

  bool getValueExistInList(String listName, String value) {
    return prefs.getStringList(listName)?.contains(value) ?? false;
  }

  bool getFlag(String flagKey){
    return prefs.getBool(flagKey) ?? false;
  }

  setFlag(String key, bool value){
    prefs.setBool(key, value);
  }

  // App State
  // Getter and setter for last opened project
String get lastOpenedProject {
  return prefs.getString('app_last_opened_project') ?? '';
}

Future<void> saveLastOpenedProject(String projectPath) async {
  await prefs.setString('app_last_opened_project', projectPath);
  notifyListeners();
}

Screen get lastKnownScreen {
  switch(lastKnownRoute){
    case '/' || '/home':
      return Screen.home;
    case '/editor':
      return Screen.editor;
    case '/settings':
      return Screen.settings;
    case '/terminal':
      return Screen.terminal;
    case '/ai':
      return Screen.AI;
    case '/git_history':
      return Screen.gitHistory;
     case '/file_explorer':
      return Screen.fileExplorer;
  }
  return Screen.home;
}

// Getter and setter for last known route
String get lastKnownRoute {
  return prefs.getString('app_last_known_route') ?? '/';
}

Future<void> saveLastKnownRoute(String route) async {
  await prefs.setString('app_last_known_route', '/$route');
  notifyListeners();
}

// Getter and setter for session start time
DateTime get sessionStartTime {
  String? timestamp = prefs.getString('app_session_start_time');
  return timestamp != null ? DateTime.parse(timestamp) : DateTime.now();
}

Future<void> saveSessionStartTime(DateTime startTime) async {
  await prefs.setString('app_session_start_time', startTime.toIso8601String());
  notifyListeners();
}

// Getter and setter for onboarding completion status
bool get isOnboardingCompleted {
  return prefs.getBool('app_onboarding_completed') ?? false;
}

Future<void> saveOnboardingCompleted(bool completed) async {
  await prefs.setBool('app_onboarding_completed', completed);
  notifyListeners();
}

// Getter and setter for terms acceptance status
bool get isTermsAccepted {
  return prefs.getBool('app_terms_accepted') ?? false;
}

Future<void> saveTermsAccepted(bool accepted) async {
  await prefs.setBool('app_terms_accepted', accepted);
  notifyListeners();
}

// Getter and setter for analytics opt-in status
bool get isAnalyticsOptedIn {
  return prefs.getBool('app_analytics_opted_in') ?? false;
}

Future<void> saveAnalyticsOptedIn(bool optedIn) async {
  await prefs.setBool('app_analytics_opted_in', optedIn);
  notifyListeners();
}

// Getter and setter for crash reporting enabled status
bool get isCrashReportingEnabled {
  return prefs.getBool('app_crash_reporting') ?? true;
}

Future<void> saveCrashReportingEnabled(bool enabled) async {
  await prefs.setBool('app_crash_reporting', enabled);
  notifyListeners();
}

// Getter and setter for app version
String get appVersion {
  return prefs.getString('app_version') ?? '1.0.0';
}

// Future<void> saveAppVersion(String version) async {
//   await prefs.setString('app_version', version);
//   notifyListeners();
// }

// Getter and setter for build number
String get buildNumber {
  return prefs.getString('app_build_number') ?? '1';
}

Future<void> saveBuildNumber(String build) async {
  await prefs.setString('app_build_number', build);
  notifyListeners();
}

// Getter and setter for first install date
DateTime get firstInstallDate {
  String? timestamp = prefs.getString('app_first_install_date');
  return timestamp != null ? DateTime.parse(timestamp) : DateTime.now();
}

Future<void> saveFirstInstallDate(DateTime installDate) async {
  await prefs.setString('app_first_install_date', installDate.toIso8601String());
  notifyListeners();
}

  Locale? get locale {
    String? localeCode = prefs.getString('locale');
    if (localeCode == null || localeCode == 'System') return null;
    if (localeCode.contains('-')) {
      List<String> codes = localeCode.split('-');
      return Locale(codes[0], codes[1]);
    }
    return Locale(localeCode);
  }

  Future<void> saveLocaleToPrefs(String localeCode) async {
    await prefs.setString('locale', localeCode);
    notifyListeners();
  }

  // Log file
  void saveClearLogWhenStart(bool status) {
    prefs.setBool('clearLogWhenStart', status);
    notifyListeners();
  }

  bool get clearLogWhenStart {
    return prefs.getBool('clearLogWhenStart') ?? true;
  }

  // Theme Related Prefs
ThemeMode get themeMode {
  String themeMode = prefs.getString('theme_mode') ?? 'system';
  switch (themeMode) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
      return ThemeMode.light;
    default:
      return ThemeMode.system;
  }
}

Future<void> saveThemeMode(String themeMode) async {
  await prefs.setString('theme_mode', themeMode);
  notifyListeners();
}

// Getter and setter for custom theme name
String get customThemeName {
  return prefs.getString('theme_custom_name') ?? 'default_custom';
}

Future<void> saveCustomThemeName(String name) async {
  await prefs.setString('theme_custom_name', name);
  notifyListeners();
}

// Getter and setter for primary color
Color get primaryColor {
  int colorValue = prefs.getInt('theme_primary_color') ?? 0xFF2196F3;
  return Color(colorValue);
}

Future<void> savePrimaryColor(int colorValue) async {
  await prefs.setInt('theme_primary_color', colorValue);
  notifyListeners();
}

// Getter and setter for secondary color
Color get secondaryColor {
  int colorValue = prefs.getInt('theme_secondary_color') ?? 0xFFFF9800;
  return Color(colorValue);
}

Future<void> saveSecondaryColor(int colorValue) async {
  await prefs.setInt('theme_secondary_color', colorValue);
  notifyListeners();
}

// Getter and setter for background color
Color get backgroundColor {
  int colorValue = prefs.getInt('theme_background_color') ?? 0xFF121212;
  return Color(colorValue);
}

Future<void> saveBackgroundColor(int colorValue) async {
  await prefs.setInt('theme_background_color', colorValue);
  notifyListeners();
}

// Getter and setter for surface color
Color get surfaceColor {
  int colorValue = prefs.getInt('theme_surface_color') ?? 0xFF1E1E1E;
  return Color(colorValue);
}

Future<void> saveSurfaceColor(int colorValue) async {
  await prefs.setInt('theme_surface_color', colorValue);
  notifyListeners();
}

// Getter and setter for error color
Color get errorColor {
  int colorValue = prefs.getInt('theme_error_color') ?? 0xFFCF6679;
  return Color(colorValue);
}

Future<void> saveErrorColor(int colorValue) async {
  await prefs.setInt('theme_error_color', colorValue);
  notifyListeners();
}

// Getter and setter for UI density
String get uiDensity {
  return prefs.getString('theme_ui_density') ?? 'comfortable';
}

Future<void> saveUiDensity(String density) async {
  await prefs.setString('theme_ui_density', density);
  notifyListeners();
}

// Getter and setter for button style
String get buttonStyle {
  return prefs.getString('theme_button_style') ?? 'elevated';
}

Future<void> saveButtonStyle(String style) async {
  await prefs.setString('theme_button_style', style);
  notifyListeners();
}

// Getter and setter for border radius
double get borderRadius {
  return prefs.getDouble('theme_border_radius') ?? 8.0;
}

Future<void> saveBorderRadius(double radius) async {
  await prefs.setDouble('theme_border_radius', radius);
  notifyListeners();
}

// Getter and setter for elevation level
double get elevationLevel {
  return prefs.getDouble('theme_elevation_level') ?? 2.0;
}

Future<void> saveElevationLevel(double elevation) async {
  await prefs.setDouble('theme_elevation_level', elevation);
  notifyListeners();
}

// Getter and setter for app font family
String get appFontFamily {
  return prefs.getString('theme_app_font_family') ?? 'Roboto';
}

Future<void> saveAppFontFamily(String fontFamily) async {
  await prefs.setString('theme_app_font_family', fontFamily);
  notifyListeners();
}

// Getter and setter for app font size
double get appFontSize {
  return prefs.getDouble('theme_app_font_size') ?? 14.0;
}

Future<void> saveAppFontSize(double fontSize) async {
  await prefs.setDouble('theme_app_font_size', fontSize);
  notifyListeners();
}

// Getter and setter for heading font scale
double get headingFontScale {
  return prefs.getDouble('theme_heading_font_scale') ?? 1.5;
}

Future<void> saveHeadingFontScale(double scale) async {
  await prefs.setDouble('theme_heading_font_scale', scale);
  notifyListeners();
}

// Getter and setter for code font scale
double get codeFontScale {
  return prefs.getDouble('theme_code_font_scale') ?? 1.0;
}

Future<void> saveCodeFontScale(double scale) async {
  await prefs.setDouble('theme_code_font_scale', scale);
  notifyListeners();
}

// -------------------------------
// Current open file / editor session helpers
// -------------------------------

/// Save the currently opened project and file path and its latest content.
Future<void> saveCurrentOpenFile(String projectId, String filePath, String content) async {
  await prefs.setString('editor_current_project', projectId);
  await prefs.setString('editor_current_file', filePath);
  await prefs.setString('editor_current_content', content);
  notifyListeners();
}

String get currentOpenProject {
  return prefs.getString('editor_current_project') ?? '';
}

String get currentOpenFile {
  return prefs.getString('editor_current_file') ?? '';
}

String get currentOpenFileContent {
  return prefs.getString('editor_current_content') ?? '';
}

Future<void> saveCurrentOpenFileContent(String content) async {
  await prefs.setString('editor_current_content', content);
  notifyListeners();
}

Future<void> saveCurrentOpenFileLanguage(String language) async {
  await prefs.setString('editor_current_language', language);
  notifyListeners();
}

String get currentOpenFileLanguage {
  return prefs.getString('editor_current_language') ?? '';
}

/// Detect a monaco / language id from a filename extension
String detectLanguageFromFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.dart')) return 'dart';
  if (lower.endsWith('.js')) return 'javascript';
  if (lower.endsWith('.ts')) return 'typescript';
  if (lower.endsWith('.jsx')) return 'javascript';
  if (lower.endsWith('.tsx')) return 'typescript';
  if (lower.endsWith('.py')) return 'python';
  if (lower.endsWith('.java')) return 'java';
  if (lower.endsWith('.kt') || lower.endsWith('.kts')) return 'kotlin';
  if (lower.endsWith('.swift')) return 'swift';
  if (lower.endsWith('.c') || lower.endsWith('.h')) return 'c';
  if (lower.endsWith('.cpp') || lower.endsWith('.cc') || lower.endsWith('.cxx')) return 'cpp';
  if (lower.endsWith('.cs')) return 'csharp';
  if (lower.endsWith('.rb')) return 'ruby';
  if (lower.endsWith('.go')) return 'go';
  if (lower.endsWith('.rs')) return 'rust';
  if (lower.endsWith('.php')) return 'php';
  if (lower.endsWith('.json')) return 'json';
  if (lower.endsWith('.yaml') || lower.endsWith('.yml')) return 'yaml';
  if (lower.endsWith('.html') || lower.endsWith('.htm')) return 'html';
  if (lower.endsWith('.css') || lower.endsWith('.scss') || lower.endsWith('.sass')) return 'css';
  if (lower.endsWith('.sh') || lower.endsWith('.bash')) return 'shell';
  if (lower.endsWith('.md') || lower.endsWith('.markdown')) return 'markdown';
  // fallback
  return 'plaintext';
}

// Getter and setter for animation speed
double get animationSpeed {
  return prefs.getDouble('theme_animation_speed') ?? 1.0;
}

Future<void> saveAnimationSpeed(double speed) async {
  await prefs.setDouble('theme_animation_speed', speed);
  notifyListeners();
}

// Getter and setter for reduce animations setting
bool get reduceAnimations {
  return prefs.getBool('theme_reduce_animations') ?? false;
}

Future<void> saveReduceAnimations(bool reduce) async {
  await prefs.setBool('theme_reduce_animations', reduce);
  notifyListeners();
}

// Getter and setter for ripple effect setting
bool get rippleEffect {
  return prefs.getBool('theme_ripple_effect') ?? true;
}

Future<void> saveRippleEffect(bool enable) async {
  await prefs.setBool('theme_ripple_effect', enable);
  notifyListeners();
}

// Editor Prefs
// Getter and setter for Monaco editor theme
String get editorMonacoTheme {
  return prefs.getString('editor_monaco_theme') ?? 'vs-dark';
}

Future<void> saveEditorMonacoTheme(String theme) async {
  await prefs.setString('editor_monaco_theme', theme);
  notifyListeners();
}

// Getter and setter for editor font size
double get editorFontSize {
  return prefs.getDouble('editor_font_size') ?? 14.0;
}

Future<void> saveEditorFontSize(double size) async {
  await prefs.setDouble('editor_font_size', size);
  notifyListeners();
}

// Getter and setter for editor font family
String get editorFontFamily {
  return prefs.getString('editor_font_family') ?? 'Fira Code, Monaco, Menlo, Consolas';
}

Future<void> saveEditorFontFamily(String fontFamily) async {
  await prefs.setString('editor_font_family', fontFamily);
  notifyListeners();
}

// Getter and setter for editor tab size
int get editorTabSize {
  return prefs.getInt('editor_tab_size') ?? 2;
}

Future<void> saveEditorTabSize(int size) async {
  await prefs.setInt('editor_tab_size', size);
  notifyListeners();
}

// Getter and setter for insert spaces setting
bool get editorInsertSpaces {
  return prefs.getBool('editor_insert_spaces') ?? true;
}

Future<void> saveEditorInsertSpaces(bool insertSpaces) async {
  await prefs.setBool('editor_insert_spaces', insertSpaces);
  notifyListeners();
}

// Getter and setter for word wrap setting
String get editorWordWrap {
  return prefs.getString('editor_word_wrap') ?? 'on';
}

Future<void> saveEditorWordWrap(String wordWrap) async {
  await prefs.setString('editor_word_wrap', wordWrap);
  notifyListeners();
}

// Getter and setter for line numbers setting
String get editorLineNumbers {
  return prefs.getString('editor_line_numbers') ?? 'on';
}

Future<void> saveEditorLineNumbers(String lineNumbers) async {
  await prefs.setString('editor_line_numbers', lineNumbers);
  notifyListeners();
}

// Getter and setter for minimap enabled setting
bool get editorMinimapEnabled {
  return prefs.getBool('editor_minimap_enabled') ?? true;
}

Future<void> saveEditorMinimapEnabled(bool enabled) async {
  await prefs.setBool('editor_minimap_enabled', enabled);
  notifyListeners();
}

// Getter and setter for auto-indent setting
bool get editorAutoIndent {
  return prefs.getBool('editor_auto_indent') ?? true;
}

Future<void> saveEditorAutoIndent(bool autoIndent) async {
  await prefs.setBool('editor_auto_indent', autoIndent);
  notifyListeners();
}

// Getter and setter for match brackets setting
bool get editorMatchBrackets {
  return prefs.getBool('editor_match_brackets') ?? true;
}

Future<void> saveEditorMatchBrackets(bool matchBrackets) async {
  await prefs.setBool('editor_match_brackets', matchBrackets);
  notifyListeners();
}

// Getter and setter for code lens setting
bool get editorCodeLens {
  return prefs.getBool('editor_code_lens') ?? false;
}

Future<void> saveEditorCodeLens(bool codeLens) async {
  await prefs.setBool('editor_code_lens', codeLens);
  notifyListeners();
}

// Getter and setter for auto-save setting
bool get editorAutoSave {
  return prefs.getBool('editor_auto_save') ?? true;
}

Future<void> saveEditorAutoSave(bool autoSave) async {
  await prefs.setBool('editor_auto_save', autoSave);
  notifyListeners();
}

// Getter and setter for auto-save delay
int get editorAutoSaveDelay {
  return prefs.getInt('editor_auto_save_delay') ?? 1000;
}

Future<void> saveEditorAutoSaveDelay(int delay) async {
  await prefs.setInt('editor_auto_save_delay', delay);
  notifyListeners();
}

// Getter and setter for format on save setting
bool get editorFormatOnSave {
  return prefs.getBool('editor_format_on_save') ?? false;
}

Future<void> saveEditorFormatOnSave(bool formatOnSave) async {
  await prefs.setBool('editor_format_on_save', formatOnSave);
  notifyListeners();
}

// Getter and setter for trim trailing whitespace setting
bool get editorTrimTrailingWhitespace {
  return prefs.getBool('editor_trim_trailing_whitespace') ?? false;
}

Future<void> saveEditorTrimTrailingWhitespace(bool trim) async {
  await prefs.setBool('editor_trim_trailing_whitespace', trim);
  notifyListeners();
}

// Getter and setter for insert final newline setting
bool get editorInsertFinalNewline {
  return prefs.getBool('editor_insert_final_newline') ?? true;
}

Future<void> saveEditorInsertFinalNewline(bool insertNewline) async {
  await prefs.setBool('editor_insert_final_newline', insertNewline);
  notifyListeners();
}

// Getter and setter for cursor style
String get editorCursorStyle {
  return prefs.getString('editor_cursor_style') ?? 'line';
}

Future<void> saveEditorCursorStyle(String cursorStyle) async {
  await prefs.setString('editor_cursor_style', cursorStyle);
  notifyListeners();
}

// Getter and setter for cursor blinking
String get editorCursorBlinking {
  return prefs.getString('editor_cursor_blinking') ?? 'blink';
}

Future<void> saveEditorCursorBlinking(String cursorBlinking) async {
  await prefs.setString('editor_cursor_blinking', cursorBlinking);
  notifyListeners();
}

// Getter and setter for render whitespace setting
String get editorRenderWhitespace {
  return prefs.getString('editor_render_whitespace') ?? 'none';
}

Future<void> saveEditorRenderWhitespace(String renderWhitespace) async {
  await prefs.setString('editor_render_whitespace', renderWhitespace);
  notifyListeners();
}

// Getter and setter for render control characters setting
bool get editorRenderControlCharacters {
  return prefs.getBool('editor_render_control_characters') ?? false;
}

Future<void> saveEditorRenderControlCharacters(bool renderControl) async {
  await prefs.setBool('editor_render_control_characters', renderControl);
  notifyListeners();
}

// Plugins pref
// Getter and setter for Read-Only Mode plugin (editor)
bool get readonlyModeEnabled {
  return prefs.getBool('plugin_readonly_mode') ?? false;
}

Future<void> saveReadonlyModeEnabled(bool enabled) async {
  await prefs.setBool('plugin_readonly_mode', enabled);
  notifyListeners();
}

// Getter and setter for Syntax Highlighting plugin (editor)
bool get syntaxHighlightingEnabled {
  return prefs.getBool('plugin_syntax_highlighting') ?? false;
}

Future<void> saveSyntaxHighlightingEnabled(bool enabled) async {
  await prefs.setBool('plugin_syntax_highlighting', enabled);
  notifyListeners();
}

// Getter and setter for Code Folding plugin (editor)
bool get codeFoldingEnabled {
  return prefs.getBool('plugin_code_folding') ?? false;
}

Future<void> saveCodeFoldingEnabled(bool enabled) async {
  await prefs.setBool('plugin_code_folding', enabled);
  notifyListeners();
}

// Getter and setter for Bracket Matching plugin (editor)
bool get bracketMatchingEnabled {
  return prefs.getBool('plugin_bracket_matching') ?? false;
}

Future<void> saveBracketMatchingEnabled(bool enabled) async {
  await prefs.setBool('plugin_bracket_matching', enabled);
  notifyListeners();
}

// Getter and setter for Git History plugin (git)
bool get gitHistoryEnabled {
  return prefs.getBool('plugin_git_history') ?? false;
}

Future<void> saveGitHistoryEnabled(bool enabled) async {
  await prefs.setBool('plugin_git_history', enabled);
  notifyListeners();
}

// Getter and setter for GitLens plugin (git)
bool get gitLensEnabled {
  return prefs.getBool('plugin_git_lens') ?? false;
}

Future<void> saveGitLensEnabled(bool enabled) async {
  await prefs.setBool('plugin_git_lens', enabled);
  notifyListeners();
}

// Getter and setter for Branch Manager plugin (git)
bool get branchManagerEnabled {
  return prefs.getBool('plugin_branch_manager') ?? false;
}

Future<void> saveBranchManagerEnabled(bool enabled) async {
  await prefs.setBool('plugin_branch_manager', enabled);
  notifyListeners();
}

// Getter and setter for File Explorer plugin (utility)
bool get fileExplorerEnabled {
  return prefs.getBool('plugin_file_explorer') ?? false;
}

Future<void> saveFileExplorerEnabled(bool enabled) async {
  await prefs.setBool('plugin_file_explorer', enabled);
  notifyListeners();
}

// Getter and setter for Search & Replace plugin (utility)
bool get searchReplaceEnabled {
  return prefs.getBool('plugin_search_replace') ?? false;
}

Future<void> saveSearchReplaceEnabled(bool enabled) async {
  await prefs.setBool('plugin_search_replace', enabled);
  notifyListeners();
}

// Getter and setter for Integrated Terminal plugin (utility)
bool get terminalEnabled {
  return prefs.getBool('plugin_terminal') ?? false;
}

Future<void> saveTerminalEnabled(bool enabled) async {
  await prefs.setBool('plugin_terminal', enabled);
  notifyListeners();
}

// Getter and setter for Theme Customizer plugin (utility)
bool get themeCustomizerEnabled {
  return prefs.getBool('plugin_theme_customizer') ?? false;
}

Future<void> saveThemeCustomizerEnabled(bool enabled) async {
  await prefs.setBool('plugin_theme_customizer', enabled);
  notifyListeners();
}

// Getter and setter for AI Code Assistant plugin (experimental)
bool get aiAssistEnabled {
  return prefs.getBool('plugin_ai_assist') ?? false;
}

Future<void> saveAiAssistEnabled(bool enabled) async {
  await prefs.setBool('plugin_ai_assist', enabled);
  notifyListeners();
}

// Getter and setter for Real-time Collaboration plugin (experimental)
bool get realTimeCollabEnabled {
  return prefs.getBool('plugin_real_time_collab') ?? false;
}

Future<void> saveRealTimeCollabEnabled(bool enabled) async {
  await prefs.setBool('plugin_real_time_collab', enabled);
  notifyListeners();
}

// Getter and setter for Performance Monitor plugin (experimental)
bool get performanceMonitorEnabled {
  return prefs.getBool('plugin_performance_monitor') ?? false;
}

Future<void> savePerformanceMonitorEnabled(bool enabled) async {
  await prefs.setBool('plugin_performance_monitor', enabled);
  notifyListeners();
}

  // Generic plugin helpers -------------------------------------------------
  /// Returns the list of enabled plugins stored under 'plugins_enabled'.
  List<String> get enabledPlugins {
    return prefs.getStringList('plugins_enabled') ?? [];
  }

  /// Check whether a plugin (by id) is enabled.
  bool isPluginEnabled(String pluginId) {
    return prefs.getStringList('plugins_enabled')?.contains(pluginId) ?? false;
  }

  /// Enable or disable a plugin by id. Updates the 'plugins_enabled' list.
  Future<void> setPluginEnabled(String pluginId, bool enabled) async {
    final List<String> current = prefs.getStringList('plugins_enabled') ?? [];
    final updated = List<String>.from(current);
    if (enabled) {
      if (!updated.contains(pluginId)) updated.add(pluginId);
    } else {
      updated.remove(pluginId);
    }
    await prefs.setStringList('plugins_enabled', updated);
    notifyListeners();
  }

  /// Read a plugin-specific config value stored as 'plugin_<pluginId>_<configKey>'.
  /// Returns null if not present.
  dynamic getPluginConfig(String pluginId, String configKey) {
    final key = 'plugin_${pluginId}_$configKey';
    // SharedPreferences supports a few primitive types; try them in order.
    if (prefs.containsKey(key)) {
      final value = prefs.get(key);
      return value;
    }
    return null;
  }

  /// Write a plugin-specific config value using the key 'plugin_<pluginId>_<configKey>'.
  /// Accepts String, int, double, bool, List<String>.
  Future<void> setPluginConfig(String pluginId, String configKey, dynamic value) async {
    final key = 'plugin_${pluginId}_$configKey';
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else if (value == null) {
      await prefs.remove(key);
    } else {
      // Fallback: store JSON-encoded string representation
      await prefs.setString(key, value.toString());
    }
    notifyListeners();
  }
}


class AppState {
  final String lastOpenedProject;
  final String lastKnownRoute;
  final DateTime sessionStartTime;
  final bool onboardingCompleted;
  final bool termsAccepted;
  final bool analyticsOptedIn;
  final bool crashReportingEnabled;
  final String appVersion;
  final String buildNumber;
  final DateTime firstInstallDate;

  const AppState({
    this.lastOpenedProject = '',
    this.lastKnownRoute = '/',
    required this.sessionStartTime,
    this.onboardingCompleted = false,
    this.termsAccepted = false,
    this.analyticsOptedIn = false,
    this.crashReportingEnabled = true,
    this.appVersion = '1.0.0',
    this.buildNumber = '1',
    required this.firstInstallDate,
  });
  
  AppState setLastOpenedProject({required String lastOpenedProject}) {
    return AppState(
      lastOpenedProject: lastOpenedProject,
      lastKnownRoute: lastKnownRoute,
      sessionStartTime: sessionStartTime,
      onboardingCompleted: onboardingCompleted,
      termsAccepted: termsAccepted,
      analyticsOptedIn: analyticsOptedIn,
      crashReportingEnabled: crashReportingEnabled,
      appVersion: appVersion,
      buildNumber: buildNumber,
      firstInstallDate: firstInstallDate,
    );
  }
  
  AppState markOnboardingCompleted({required bool onboardingCompleted}) {
    return AppState(
      lastOpenedProject: lastOpenedProject,
      lastKnownRoute: lastKnownRoute,
      sessionStartTime: sessionStartTime,
      onboardingCompleted: onboardingCompleted,
      termsAccepted: termsAccepted,
      analyticsOptedIn: analyticsOptedIn,
      crashReportingEnabled: crashReportingEnabled,
      appVersion: appVersion,
      buildNumber: buildNumber,
      firstInstallDate: firstInstallDate,
    );
  }

  // ... (similar implementation pattern)
}

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref ref;

  AppStateNotifier(this.ref) : super(AppState(
    sessionStartTime: DateTime.now(),
    firstInstallDate: DateTime.now(),
  )) {
    _loadState();
  }

  Future<void> _loadState() async {
     await ref.read(sharedPreferencesProvider.future);

    // final prefs = await ref.read(sharedPreferencesProvider.future);
    // state = AppState.fromPreferences(prefs);
  }

  Future<void> updateLastOpenedProject(String projectPath) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('app_last_opened_project', projectPath);
    state = state.setLastOpenedProject(lastOpenedProject: projectPath);
  }

  Future<void> markOnboardingCompleted() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('app_onboarding_completed', true);
    state = state.markOnboardingCompleted(onboardingCompleted: true);
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(ref),
);

// =============================================
// Utility Providers
// =============================================

/// Provider that initializes all settings when app starts
final settingsInitializerProvider = FutureProvider<void>((ref) async {
  // Wait for SharedPreferences to be ready
  await ref.read(sharedPreferencesProvider.future);
  
  // Ensure Prefs singleton is initialized and available to the app
  ref.read(prefsProvider);
  // Initialize app state provider as before
  ref.read(appStateProvider);
});

/// Provider that gives a quick way to check if all settings are loaded
final areSettingsLoadedProvider = Provider<bool>((ref) {
  // Consider settings loaded once SharedPreferences is available
  final shared = ref.watch(sharedPreferencesProvider);
  return shared.maybeWhen(data: (_) => true, orElse: () => false);
});