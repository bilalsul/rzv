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
    final prefs = await ref.read(sharedPreferencesProvider.future);
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