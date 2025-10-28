import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/enums/options/screen.dart';
import 'package:git_explorer_mob/providers/navigation_provider.dart';
import 'package:git_explorer_mob/providers/plugin_provider.dart';
import 'package:git_explorer_mob/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import '../providers/shared_preferences_provider.dart';
// import 'package:git_explorer_mob/providers/plugin_provider.dart';
// import 'package:git_explorer_mob/providers/theme_provider.dart';
// import '../providers/navigation_provider.dart';

// Screens
import 'package:git_explorer_mob/screens/home_screen.dart';
// import '../screens/editor_screen.dart';
// import '../screens/file_explorer_screen.dart';
// import '../screens/git_history_screen.dart';
// import '../screens/settings_screen.dart';

// Widgets
import 'package:git_explorer_mob/widgets/common/app_drawer.dart';
import 'package:git_explorer_mob/widgets/common/dynamic_app_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Pre-load essential providers
    await ref.read(sharedPreferencesProvider.future);
    // ref.read(pluginControllerProvider.notifier).loadPlugins();
    // ref.read(themeControllerProvider.notifier).loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = ref.watch(currentScreenProvider);
    final themeMode = ref.watch(themeModeProvider);
    final plugins = ref.watch(enabledPluginsProvider);

    return MaterialApp(
      title: 'Unnamed Code Editor',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: DynamicAppBar(
          scaffoldKey: _scaffoldKey,
          currentScreen: currentScreen,
        ),
        drawer: const AppDrawer(),
        body: _buildBody(currentScreen, plugins),
      ),
    );
  }

  Widget _buildBody(Screen currentScreen, List<String> plugins) {
    switch (currentScreen) {
      case Screen.home:
        return const HomeScreen();
      case Screen.editor:
        return const HomeScreen();
      case Screen.fileExplorer:
        return plugins.contains('file_explorer')
            ? const HomeScreen()
            : const FeatureDisabledScreen(feature: 'File Explorer');
      case Screen.gitHistory:
        return plugins.contains('git_history')
            ? const HomeScreen()
            : const FeatureDisabledScreen(feature: 'Git History');
      case Screen.settings:
        return const HomeScreen();
    }
  }
}

class FeatureDisabledScreen extends StatelessWidget {
  final String feature;

  const FeatureDisabledScreen({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.extension_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '$feature Disabled',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enable this feature from the drawer or settings',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}