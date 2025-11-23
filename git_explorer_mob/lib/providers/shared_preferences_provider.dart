import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/enums/options/screen.dart';
import 'package:path_provider/path_provider.dart';
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
  // store a timestamp (ISO8601) so UIs can show relative last-opened time
  await prefs.setString('app_last_opened_project_time', DateTime.now().toIso8601String());
  notifyListeners();
}

  // -------------------------------
  // Current project explicit helpers
  // -------------------------------
  /// Save current project id, name and path.
  Future<void> saveCurrentProject({required String id, required String name, required String path}) async {
    await prefs.setString('current_project_id', id);
    await prefs.setString('current_project_name', name);
    await prefs.setString('current_project_path', path);
    // Keep backward compatibility with lastOpenedProject
    await prefs.setString('app_last_opened_project', path);
    // also record when this project was last opened
    await prefs.setString('app_last_opened_project_time', DateTime.now().toIso8601String());
    notifyListeners();
  }

  String get currentProjectId {
    return prefs.getString('current_project_id') ?? '';
  }

  String get currentProjectName {
    return prefs.getString('current_project_name') ?? '';
  }

  String get currentProjectPath {
    return prefs.getString('current_project_path') ?? prefs.getString('app_last_opened_project') ?? '';
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

void resetThemeCustomizerColors() {
    // prefs.remove('theme_primary_color');
    prefs.remove('theme_secoondary_color');
    prefs.remove('theme_accent_color');
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
  // Color name mapping helpers ------------------------------------------------
  final Map<String, Color> _colorNameMap = (() {
    const swatchNames = [
      'red', 'pink', 'purple', 'deepPurple', 'indigo', 'blue', 'lightBlue', 'cyan',
      'teal', 'green', 'lightGreen', 'lime', 'yellow', 'amber', 'orange', 'deepOrange',
      'brown', 'blueGrey'
    ];
    final shades = [50,100,200,300,400,500,600,700,800,900];
    final map = <String, Color>{};
    for (var i = 0; i < swatchNames.length && i < Colors.primaries.length; i++) {
      final name = swatchNames[i];
      final swatch = Colors.primaries[i];
      for (final shade in shades) {
        final col = swatch[shade] ?? swatch as Color;
        map['${name}$shade'] = col;
      }
      map[name] = swatch[500]!;
    }
    return map;
  })();

  String _nameFromColor(Color color) {
    for (final entry in _colorNameMap.entries) {
      if (entry.value.value == color.value) return entry.key;
    }
    // fallback to a stable string for custom colors
    return 'custom#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  Color _colorFromName(String? name, {Color? fallback}) {
    if (name == null) return fallback ?? const Color(0xFF2196F3);
    if (name.startsWith('custom#')) {
      final hex = name.substring('custom#'.length);
      try {
        return Color(int.parse(hex, radix: 16));
      } catch (_) {
        return fallback ?? const Color(0xFF2196F3);
      }
    }
    return _colorNameMap[name] ?? fallback ?? const Color(0xFF2196F3);
  }

  // Getter and setter for primary color
  // Color get primaryColor {
  //   // Support legacy int storage: if a string isn't found but an int exists, migrate it.
  //   final stored = prefs.getString('theme_primary_color');
  //   if (stored != null) return _colorFromName(stored, fallback: Colors.purple);
  //   if (prefs.containsKey('theme_primary_color')) {
  //     final intValue = prefs.getInt('theme_primary_color');
  //     if (intValue != null) {
  //       final col = Color(intValue);
  //       // migrate to string name (fire-and-forget)
  //       final name = _nameFromColor(col);
  //       prefs.setString('theme_primary_color', name);
  //       return col;
  //     }
  //   }
  //   return Colors.purple;
  // }

  // Future<void> savePrimaryColor(Color color) async {
  //   final name = _nameFromColor(color);
  //   await prefs.setString('theme_primary_color', name);
  //   notifyListeners();
  // }

// Getter and setter for secondary color
  // Getter and setter for secondary color
  Color get secondaryColor {
    final stored = prefs.getString('theme_secondary_color');
    if (stored != null) return _colorFromName(stored, fallback: Colors.purple);
    if (prefs.containsKey('theme_secondary_color')) {
      final intValue = prefs.getInt('theme_secondary_color');
      if (intValue != null) {
        final col = Color(intValue);
        final name = _nameFromColor(col);
        prefs.setString('theme_secondary_color', name);
        return col;
      }
    }
    return Colors.purple;
  }

  Future<void> saveSecondaryColor(Color color) async {
    final name = _nameFromColor(color);
    await prefs.setString('theme_secondary_color', name);
    notifyListeners();
  }

// Accent color
  Color get accentColor {
    final stored = prefs.getString('theme_accent_color');
    if (stored != null) return _colorFromName(stored, fallback: Colors.purpleAccent);
    if (prefs.containsKey('theme_accent_color')) {
      final intValue = prefs.getInt('theme_accent_color');
      if (intValue != null) {
        final col = Color(intValue);
        final name = _nameFromColor(col);
        prefs.setString('theme_accent_color', name);
        return col;
      }
    }
    return Colors.purpleAccent;
  }

  Future<void> saveAccentColor(Color color) async {
    final name = _nameFromColor(color);
    await prefs.setString('theme_accent_color', name);
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
// Editor convenience helpers
// -------------------------------

/// Return a map of editor-related settings (used to configure Monaco)
Map<String, dynamic> getEditorSettings() {
  return {
    // 'monacoTheme': editorMonacoTheme,
    'fontFamily': editorFontFamily,
    'fontSize': editorFontSize,
    // 'tabSize': editorTabSize,
    'lineNumbers': editorLineNumbers,
    'minimap': editorMinimapEnabled,
    'autoSave': editorAutoSave,
    // 'autoSaveDelay': editorAutoSaveDelay,
    'formatOnSave': editorFormatOnSave,
    // 'wordWrap': editorWordWrap,
    // 'insertSpaces': editorInsertSpaces,
  };
}

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
  return prefs.getString('editor_current_content') ?? '# Create New File';
}

Future<void> saveCurrentOpenFileContent(String content) async {
  await prefs.setString('editor_current_content', content);
  notifyListeners();
}

/// Return the timestamp when the last project was opened (or epoch if unknown)
DateTime get lastOpenedProjectTime {
  final s = prefs.getString('app_last_opened_project_time');
  if (s == null || s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  try {
    return DateTime.parse(s);
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
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
// int get editorTabSize {
//   return prefs.getInt('editor_tab_size') ?? 2;
// }

// Future<void> saveEditorTabSize(int size) async {
//   await prefs.setInt('editor_tab_size', size);
//   notifyListeners();
// }

// Getter and setter for insert spaces setting
bool get editorInsertSpaces {
  return prefs.getBool('editor_insert_spaces') ?? true;
}

Future<void> saveEditorInsertSpaces(bool insertSpaces) async {
  await prefs.setBool('editor_insert_spaces', insertSpaces);
  notifyListeners();
}

// Getter and setter for word wrap setting
bool get editorWordWrap {
  return prefs.getBool('editor_word_wrap') ?? false;
}

Future<void> saveEditorWordWrap(bool wordWrap) async {
  await prefs.setBool('editor_word_wrap', wordWrap);
  notifyListeners();
}

// Getter and setter for line numbers setting
bool get editorLineNumbers {
  return prefs.getBool('editor_line_numbers') ?? false;
}

Future<void> saveEditorLineNumbers(bool lineNumbers) async {
  await prefs.setBool('editor_line_numbers', lineNumbers);
  notifyListeners();
}

// Getter and setter for minimap enabled setting
bool get editorMinimapEnabled {
  return prefs.getBool('editor_minimap_enabled') ?? false;
}

Future<void> saveEditorMinimapEnabled(bool enabled) async {
  await prefs.setBool('editor_minimap_enabled', enabled);
  notifyListeners();
}

// Getter and setter for auto-indent setting
bool get editorAutoIndent {
  return prefs.getBool('editor_auto_indent') ?? true;
}

// Getter and setter for auto-save setting
bool get editorAutoSave {
  return prefs.getBool('editor_auto_save') ?? true;
}

Future<void> saveEditorAutoSave(bool autoSave) async {
  await prefs.setBool('editor_auto_save', autoSave);
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

// Plugins pref
// Getter and setter for Read-Only Mode plugin (editor)
bool get readonlyModeEnabled {
  return isPluginEnabled('readonly_mode');
}


// Getter and setter for Syntax Highlighting plugin (editor)
bool get syntaxHighlightingEnabled {
  return isPluginEnabled('syntax_highlighting');
}


// Getter and setter for Code Folding plugin (editor)
bool get codeFoldingEnabled {
  return isPluginEnabled('code_folding');
}


// Getter and setter for Bracket Matching plugin (editor)
bool get bracketMatchingEnabled {
  return isPluginEnabled('bracket_matching');
}

// Getter and setter for Git History plugin (git)
bool get gitHistoryEnabled {
  return isPluginEnabled('git_history');
}


// Getter and setter for GitLens plugin (git)
bool get gitLensEnabled {
  return isPluginEnabled('git_lens');
}


// Getter and setter for Branch Manager plugin (git)
bool get branchManagerEnabled {
  return isPluginEnabled('branch_manager');
}


// Getter and setter for File Explorer plugin (utility)
bool get fileExplorerEnabled {
  return isPluginEnabled('file_explorer');
}


// Getter and setter for Search & Replace plugin (utility)
bool get searchReplaceEnabled {
  return isPluginEnabled('search_replace');
}


// Getter and setter for Integrated Terminal plugin (utility)
bool get terminalEnabled {
  return isPluginEnabled('terminal');
}


// Getter and setter for Theme Customizer plugin (utility)
bool get themeCustomizerEnabled {
  return isPluginEnabled('theme_customizer');
}


// Getter and setter for AI Code Assistant plugin (experimental)
bool get aiAssistEnabled {
  return isPluginEnabled('ai_assist');
}


// Getter and setter for Real-time Collaboration plugin (experimental)
bool get realTimeCollabEnabled {
  return isPluginEnabled("real_time_collab");
}


// Getter and setter for Performance Monitor plugin (experimental)
bool get performanceMonitorEnabled {
  return isPluginEnabled('performance_monitor');
}

  // Generic plugin helpers -------------------------------------------------
  /// Returns the list of enabled plugins stored under 'plugins_enabled'.
  List<String> get enabledPlugins {
    return prefs.getStringList('plugins_enabled') ?? [];
  }

  bool get tutorialProject {
    return prefs.getBool("tutorialProject")?? true;
  }

  setTutorialProject(bool flag){
    prefs.setBool("tutorialProject", flag);
  }

  // Project Root
  Future<Directory> projectsRoot() async {
    // check if it's an android app, persist into /projects/
    // if(Platform.isAndroid && await Permission.storage.isGranted){
    // final base = await getExternalStorageDirectory();
    // final projects = Directory('$base/projects');
    // if (!await projects.exists()) await projects.create(recursive: true);
    //   return projects;
    // } 
    // this is run on IOS, we can't have access to files outside the app sandbox
    final base = await getApplicationDocumentsDirectory();
    final projects = Directory('${base.path}/projects');
    if (!await projects.exists()) await projects.create(recursive: true);
      return projects;
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
  final DateTime sessionStartTime;
  final String appVersion;
  final DateTime firstInstallDate;

  const AppState({
    required this.sessionStartTime,
    this.appVersion = '0.0.1',
    required this.firstInstallDate,
  });
  
}

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref ref;

  AppStateNotifier(this.ref) : super(AppState(
    sessionStartTime: DateTime.now(),
    firstInstallDate: DateTime.now(),
  ));
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(ref),
);