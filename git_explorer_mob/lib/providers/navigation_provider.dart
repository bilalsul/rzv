
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/enums/options/screen.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';

class NavigationSettings {
  final String defaultHomeScreen;
  final String navigationStyle;
  final bool multiPaneEnabled;
  final List<String> visibleScreens;
  final String workspaceLayout;
  final bool restoreLayoutOnStartup;
  final bool rememberPanelSizes;

  const NavigationSettings({
    this.defaultHomeScreen = 'home',
    this.navigationStyle = 'drawer',
    this.multiPaneEnabled = false,
    this.visibleScreens = const ['editor', 'file_explorer', 'git_history'],
    this.workspaceLayout = 'mobile',
    this.restoreLayoutOnStartup = true,
    this.rememberPanelSizes = true,
  });

  void navigateTo(BuildContext context, Screen screen) {
    Navigator.of(context).pushNamed(screenToString(screen));
  }

  // ... (similar implementation pattern as above classes)
  // CopyWith, fromPreferences, saveToPreferences methods
}

class NavigationSettingsNotifier extends StateNotifier<NavigationSettings> {
  final Ref ref;

  NavigationSettingsNotifier(this.ref) : super(const NavigationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    // state = NavigationSettings.fromPreferences(prefs);
  }

  Future<void> updateSettings(NavigationSettings newSettings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    // await newSettings.saveToPreferences(prefs);
    state = newSettings;
  }
}

final navigationSettingsProvider = StateNotifierProvider<NavigationSettingsNotifier, NavigationSettings>(
  (ref) => NavigationSettingsNotifier(ref),
);

// Convenience provider for current screen
final currentScreenProvider = Provider<Screen>((ref) {
  final settings = ref.watch(navigationSettingsProvider);
  switch (settings.defaultHomeScreen) {
    case 'home':
      return Screen.home;
    case 'editor':
      return Screen.editor;
    case 'file_explorer':
      return Screen.fileExplorer;
    case 'git_history':
      return Screen.gitHistory;
    case 'settings':
      return Screen.settings;
  }
      return Screen.home;
  });