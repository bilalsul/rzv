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

  String getValue(String value){
    return prefs.getString(value) ?? "";
  }

  Color get themeColor {
    int colorValue = prefs.getInt('themeColor') ?? Colors.blue.value;
    return Color(colorValue);
  }

  Future<void> saveThemeToPrefs(int colorValue) async {
    await prefs.setInt('themeColor', colorValue);
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

  ThemeMode get themeMode {
    String themeMode = prefs.getString('themeMode') ?? 'system';
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void saveClearLogWhenStart(bool status) {
    prefs.setBool('clearLogWhenStart', status);
    notifyListeners();
  }

  bool get clearLogWhenStart {
    return prefs.getBool('clearLogWhenStart') ?? true;
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