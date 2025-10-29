import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/editor_provider.dart';
import 'package:git_explorer_mob/providers/navigation_provider.dart';
import 'package:git_explorer_mob/providers/plugin_provider.dart';
import 'package:git_explorer_mob/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================
// SharedPreferences Provider
// =============================================

/// Main provider that gives access to SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

class Prefs extends ChangeNotifier {
  late SharedPreferences prefs;
  static final Prefs _instance = Prefs._internal();

  factory Prefs() {
    return _instance;
  }

  Prefs._internal() {
    initPrefs();
  }


  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  // for testing purposes
  String getValue(String value){
    return prefs.getString(value) ?? "whatt?";
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
  
  // Initialize all settings providers
  ref.read(editorSettingsProvider);
  ref.read(themeSettingsProvider);
  ref.read(pluginSettingsProvider);
  ref.read(navigationSettingsProvider);
  ref.read(appStateProvider);
});

/// Provider that gives a quick way to check if all settings are loaded
final areSettingsLoadedProvider = Provider<bool>((ref) {
  final editorSettings = ref.watch(editorSettingsProvider);
  final themeSettings = ref.watch(themeSettingsProvider);
  final pluginSettings = ref.watch(pluginSettingsProvider);
  
  return editorSettings != const EditorSettings() &&
         themeSettings != const ThemeSettings() &&
         pluginSettings != const PluginSettings();
});