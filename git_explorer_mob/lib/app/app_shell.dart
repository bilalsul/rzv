import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/enums/options/screen.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/screens/ai_screen.dart';
import 'package:git_explorer_mob/screens/editor_screen.dart';
import 'package:git_explorer_mob/screens/settings_screen.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

// Providers
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
import 'package:hidable/hidable.dart';

class NavItem {
  final Screen screen;
  final String label;
  final Icon icon;
  final Icon activeIcon;
  final String? pluginKey; // If null, always visible

  NavItem({
    required this.screen,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.pluginKey,
  });
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Navigation is driven by Prefs via prefsProvider

  final ScrollController scrollController = ScrollController();
  // Cache heavy screens to avoid rebuilding (preserve state)
  late final Widget _cachedHomeScreen;
  late final List<Widget> _pages;
  late final Map<Screen, int> _pageIndex;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Create and cache HomeScreen once to preserve its state between navigations
    _cachedHomeScreen = HomeScreen(controller: scrollController);
    // Build a stable pages list so widgets remain in the tree (preserve state)
    _pages = [
      _cachedHomeScreen,
      EditorScreen(controller: scrollController),
      SettingsScreen(controller: scrollController),
      const AIScreen(),
    ];
    _pageIndex = {
      Screen.home: 0,
      Screen.editor: 1,
      Screen.settings: 2,
      Screen.ai: 3,
    };
  }

  Future<void> _initializeApp() async {
    // Pre-load essential providers
    await ref.read(sharedPreferencesProvider.future);
    // ref.read(pluginControllerProvider.notifier).loadPlugins();
    // ref.read(themeControllerProvider.notifier).loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final currentScreen = prefs.lastKnownScreen;
    final themeMode = prefs.themeMode;
    final plugins = prefs.enabledPlugins;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use the watched prefs instance so MaterialApp rebuilds when locale changes.
      locale: prefs.locale,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      title: 'Git Explorer',
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
        // body: _buildBody(currentScreen, plugins),
        body: _buildFloatingNavigationBar(plugins, currentScreen),

        // body: Expanded(
        //   child: Column(children: [
        //     _buildBody(currentScreen, plugins),
        //     _buildFloatingNavigationBar(plugins,currentScreen),
        //   ],),
        // ),
        // bottomNavigationBar: _buildBottomNavigationBar(plugins),
        // bottomNavigationBar: _buildFloatingNavigationBar(plugins,currentScreen),
      ),
    );
  }

  Widget _buildBody(
    Screen currentScreen,
    List<String> plugins,
    ScrollController controller,
  ) {
    // Use an IndexedStack of cached pages for primary screens so they stay mounted
    if (_pageIndex.containsKey(currentScreen)) {
      final idx = _pageIndex[currentScreen]!;
      return IndexedStack(index: idx, children: _pages);
    }

    // Fallback handling for other screens (plugin-dependent)
    switch (currentScreen) {
      case Screen.fileExplorer:
        return plugins.contains('file_explorer')
            ? _cachedHomeScreen
            : FeatureDisabledScreen(
                feature: L10n.of(context).navBarFileExplorer,
              );
      case Screen.gitHistory:
        return plugins.contains('git_history')
            ? (Prefs().featureSupported("git_history")
                  ? const SizedBox.shrink()
                  : FeatureNotSupported(
                      feature: L10n.of(context).navBarGitHistory,
                    ))
            : FeatureDisabledScreen(feature: L10n.of(context).navBarGitHistory);
      case Screen.terminal:
        return plugins.contains('terminal')
            ? (Prefs().featureSupported("terminal")
                  ? const SizedBox.shrink()
                  : FeatureNotSupported(
                      feature: L10n.of(context).navBarTerminal,
                    ))
            : FeatureDisabledScreen(feature: L10n.of(context).navBarTerminal);
      default:
        return _cachedHomeScreen;
    }
  }

  //    Widget _buildBottomNavigationBar() {
  //     // initial value
  //     int currentIndex = 0;

  //     return BottomNavigationBar(
  //       currentIndex: currentIndex,
  //       onTap: (index) {
  //         setState(() {
  //           currentIndex = index;
  //           print(currentIndex);
  //           // print(Prefs().getFlag('plugin_readonly_mode'));
  //           // print(Prefs().setFlag('plugin_readonly_mode_enabled',true));

  //           // print(Prefs().readonlyModeEnabled);
  //           // print(Prefs().getValueList('plugins_enabled'));
  //           // print(Prefs().getValueExistInList('plugins_enabled','readonly_mode'));
  //           // print(Prefs().getValueExistInList('plugins_enabled','readonly_mode'));
  //           // Prefs().clearPrefs();

  //         });
  //       },
  //       type: BottomNavigationBarType.fixed,
  //       items: getVisibleNavigationItems(),
  //     );
  //   }

  // }

  // class FeatureDisabledScreen extends StatelessWidget {
  //   final String feature;

  //   const FeatureDisabledScreen({super.key, required this.feature});

  //   @override
  //   Widget build(BuildContext context) {
  //     return Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           const Icon(Icons.extension_off, size: 64, color: Colors.grey),
  //           const SizedBox(height: 16),
  //           Text(
  //             '$feature Disabled',
  //             style: Theme.of(context).textTheme.headlineSmall,
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             'Enable this feature from the drawer or settings',
  //             style: Theme.of(context).textTheme.bodyMedium,
  //             textAlign: TextAlign.center,
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  // List<BottomNavigationBarItem> getVisibleNavigationItems() {
  //   // Define the full list of navigation items
  //   const allItems = [
  //     BottomNavigationBarItem(
  //       icon: Icon(Icons.folder_shared),
  //       activeIcon: Icon(Icons.folder_shared),
  //       label: 'Projects',
  //     ),
  //     BottomNavigationBarItem(
  //       icon: Icon(Icons.edit_outlined),
  //       activeIcon: Icon(Icons.edit),
  //       label: 'Editor',
  //     ),
  //     BottomNavigationBarItem(
  //       icon: Icon(Icons.chat_rounded),
  //       activeIcon: Icon(Icons.chat_rounded),
  //       label: 'AI',
  //     ),
  //     BottomNavigationBarItem(
  //       icon: Icon(Icons.history_outlined),
  //       activeIcon: Icon(Icons.history),
  //       label: 'Git History',
  //     ),
  //     BottomNavigationBarItem(
  //       icon: Icon(Icons.terminal_outlined),
  //       activeIcon: Icon(Icons.terminal),
  //       label: 'Terminal',
  //     ),
  //     BottomNavigationBarItem(
  //       icon: Icon(Icons.settings_rounded),
  //       activeIcon: Icon(Icons.settings),
  //       label: 'Settings',
  //     ),
  //   ];
  //   final flagMap = {
  //     'AI': 'ai_assist',
  //     'Git History': 'git_history',
  //     'Terminal': 'terminal',
  //   };

  //   // Filter items based on their flag status
  //   return allItems.where((item) {
  //     final flagKey = flagMap[item.label];
  //     if (flagKey == null) {
  //       // No flag associated (e.g., Projects, Editor, Settings), always visible
  //       return true;
  //     }
  //     // Check if the plugin flag is enabled (defaults from previous plugin getters)
  //     return Prefs().getValueExistInList('plugins_enabled',flagKey);
  //   }).toList();
  // }
  Widget _buildFloatingNavigationBar(
    List<String> plugins,
    Screen currentScreen,
  ) {
    final visibleNavItems = getVisibleNavItems(plugins);

    // Compute current index based on currentScreen
    int currentIndex = visibleNavItems.indexWhere(
      (item) => item.screen == Prefs().lastKnownScreen,
    );
    if (currentIndex == -1) {
      currentIndex = 0; // Fallback to first item
    }

    List<BottomNavigationBarItem> bottomBarItems = visibleNavItems.map((item) {
      return BottomNavigationBarItem(
        icon: item.icon,
        activeIcon: item.activeIcon,
        label: item.label,
      );
    }).toList();

    // final currentScreen = Prefs().lastKnownScreen;

    return //Scaffold(
    // extendBody: true,
    // body:
    BottomBar(
      body: (context, _) =>
          // controller: scrollController,
          _buildBody(currentScreen, plugins, scrollController),
      // body: (context, _) => SizedBox.shrink(),

      // body: (_, controller) =>
      //     pages(currentIndex, constraints, controller),
      hideOnScroll: true,
      scrollOpposite: false,
      curve: Curves.easeIn,
      barColor: Colors.transparent,
      iconDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(500),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              // color: Theme.of(context)
              //     .colorScheme
              //     .surfaceContainer
              //     .withAlpha(123),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                // color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
            child: Hidable(
              controller: scrollController,
              preferredWidgetSize: Size.fromHeight(60),
              child: BottomNavigationBar(
                selectedFontSize: 14,
                // selectedItemColor: Prefs().secondaryColor,
                // selectedLabelStyle: TextStyle(color: Prefs().accentColor),
                // selectedIconTheme: IconThemeData(color: Prefs().secondaryColor),
                // showSelectedLabels: true,
                enableFeedback: true,
                type: BottomNavigationBarType.fixed,
                landscapeLayout: BottomNavigationBarLandscapeLayout.linear,
                currentIndex: currentIndex,
                // onTap: (int index) => onBottomTap(index, false),
                onTap: (index) {
                  final selectedItem = visibleNavItems[index];
                  final selectedScreen = selectedItem.screen;
                  // Persist selection to Prefs (prefsProvider will notify listeners and rebuild)
                  Prefs().saveLastKnownRoute(screenToString(selectedScreen));

                  // For debugging: Get/print the value of the current selected item
                  // print('Selected index: $index');
                  // print('Selected screen: $selectedScreen');
                  // print('Selected label: ${selectedItem.label}');
                },
                items: bottomBarItems,
                backgroundColor: Colors.transparent,
                elevation: 0,
                // height: 64,
              ),
            ),
          ),
        ),
      ),
      // ),
    );
  }

  // Widget _buildBottomNavigationBar(List<String> plugins) {
  //     final visibleNavItems = getVisibleNavItems(plugins);

  //     // Compute current index based on currentScreen
  //     int currentIndex = visibleNavItems.indexWhere((item) => item.screen == Prefs().lastKnownScreen);
  //     if (currentIndex == -1) {
  //       currentIndex = 0;  // Fallback to first item
  //     }

  //     return BottomNavigationBar(
  //       currentIndex: currentIndex,
  //       onTap: (index) {
  //   final selectedItem = visibleNavItems[index];
  //   final selectedScreen = selectedItem.screen;
  //   // Persist selection to Prefs (prefsProvider will notify listeners and rebuild)
  //   Prefs().saveLastKnownRoute(screenToString(selectedScreen));
  //   // Also trigger a local rebuild for immediate feedback
  //   // setState(() {});

  //         // For debugging: Get/print the value of the current selected item
  //         print('Selected index: $index');
  //         print('Selected screen: $selectedScreen');
  //         print('Selected label: ${selectedItem.label}');
  //       },
  //       type: BottomNavigationBarType.fixed,
  //       items: visibleNavItems.map((item) {
  //         return BottomNavigationBarItem(
  //           icon: item.icon,
  //           activeIcon: item.activeIcon,
  //           label: item.label,
  //         );
  //       }).toList(),
  //     );
  //   }

  List<NavItem> getVisibleNavItems(List<String> enabledPlugins) {
    final prefs = ref.watch(prefsProvider);
    final allNavItems = [
      NavItem(
        screen: Screen.home,
        label: L10n.of(context).navBarHome,
        icon: const Icon(Icons.folder_shared_outlined),
        activeIcon: Icon(Icons.folder_shared, color: prefs.accentColor),
        pluginKey: null, // Always visible (but body may disable content)
      ),
      NavItem(
        screen: Screen.editor,
        label: L10n.of(context).navBarEditor,
        icon: const Icon(Icons.edit_outlined),
        activeIcon: Icon(Icons.edit, color: prefs.accentColor),
        pluginKey: null,
      ),
      NavItem(
        screen: Screen.ai,
        label: L10n.of(context).navBarAI,
        icon: const Icon(Icons.chat_outlined),
        activeIcon: Icon(Icons.chat_rounded, color: prefs.accentColor),
        pluginKey: 'ai_assist',
      ),
      NavItem(
        screen: Screen.gitHistory,
        label: L10n.of(context).navBarGitHistory,
        icon: const Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history, color: prefs.accentColor),
        pluginKey: 'git_history',
      ),
      NavItem(
        screen: Screen.terminal,
        label: L10n.of(context).navBarTerminal,
        icon: const Icon(Icons.terminal_outlined),
        activeIcon: Icon(Icons.terminal, color: prefs.accentColor),
        pluginKey: 'terminal',
      ),
      NavItem(
        screen: Screen.settings,
        label: L10n.of(context).navBarSettings,
        icon: const Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings, color: prefs.accentColor),
        pluginKey: null,
      ),
    ];

    return allNavItems.where((item) {
      if (item.pluginKey == null) return true;
      return enabledPlugins.contains(item.pluginKey);
    }).toList();
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
            '$feature ${L10n.of(context).commonDisabled}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            L10n.of(context).enableFeatureFromPlugins,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FeatureNotSupported extends StatelessWidget {
  final String feature;

  const FeatureNotSupported({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.extension_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '$feature ${L10n.of(context).commonNotSupported}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            L10n.of(context).featureNotSupported,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
