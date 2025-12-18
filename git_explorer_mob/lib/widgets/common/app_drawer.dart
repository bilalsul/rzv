import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:url_launcher/url_launcher.dart';
// Navigation moved to AppShell
// Navigation and plugin state now come from Prefs

// Providers
import '../../providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/data/plugin_definitions.dart' as plugin_defs;

// Models
import 'package:git_explorer_mob/models/plugin.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _expandedEditorPlugins = true;
  // bool _expandedGitPlugins = true;
  bool _expandedUtilityPlugins = true;
  // bool _expandedExperimentalPlugins = false;

  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(prefsProvider);
    // final currentScreen = ref.watch(currentScreenProvider);

    return Drawer(
      width: 320,
      child: Column(
        children: [
          // Header Section
          _buildDrawerHeader(theme, prefs),

          // Navigation Section
          // _buildNavigationSection(currentScreen, theme),

          // Plugin Toggles Section
          Expanded(child: _buildPluginTogglesSection(prefs, theme)),
          // Footer is rendered as the last sliver inside the scrollable plugin section
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // make sure initialized Mobile Ads in main then load native ad for this screen
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-3940256099942544/2247696110', // Test Native Ad Unit
      factoryId: 'listTileMedium',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isNativeAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native Ad failed: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  // =============================================
  // Drawer Header
  // =============================================

  Widget _buildDrawerHeader(ThemeData theme, Prefs prefs) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Logo and Name
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.asset(
                  Theme.of(context).brightness == Brightness.light
                      ? 'assets/icons/git-explorer-icon.png'
                      : 'assets/icons/git-explorer-icon-light.png',
                  height: 35,
                  width: 35,
                ),
              ),
              const SizedBox(width: 12),
              // Ensure the app title cannot overflow the header horizontally
              Expanded(
                child: Text(
                  L10n.of(context).appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    // color: prefs.accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Current Project Info (sourced from Prefs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.of(context).drawerCurrentProject,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 3),
                // Use Flexible/Row to prevent overflow and allow ellipsis for long names
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        prefs.currentProjectName.isNotEmpty
                            ? prefs.currentProjectName
                            : (prefs.lastOpenedProject.isNotEmpty
                                  ? prefs.lastOpenedProject.split('/').last
                                  : L10n.of(context).drawerNoProjectOpen),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                // Show the filename currently open in the editor (if any)
                Builder(
                  builder: (_) {
                    final openFile = prefs.currentOpenFile;
                    final openFileName = openFile.isNotEmpty
                        ? openFile.split('/').last
                        : '';
                    return openFileName.isNotEmpty
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  openFileName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink();
                  },
                ),
                // Last opened time for the project (relative, no seconds)
                Builder(
                  builder: (_) {
                    final lastOpened = prefs.lastOpenedProjectTime;
                    final lastText = lastOpened.millisecondsSinceEpoch > 0
                        ? _formatDate(lastOpened, context)
                        : L10n.of(context).drawerNever;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        L10n.of(context).drawerLastOpened(lastText),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Navigation UI has been migrated to use Prefs; AppShell builds the primary navigation.

  // Navigation items removed from the drawer; main navigation is handled by AppShell.

  // =============================================
  // Plugin Toggles Section
  // =============================================

  Widget _buildPluginTogglesSection(Prefs prefs, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Row(
              children: [
                Icon(
                  Icons.extension,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  L10n.of(context).drawerPluginsAndFeatures.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Editor Plugins
        _buildPluginCategory(
          title: L10n.of(context).drawerEditorPlugins,
          plugins: plugin_defs.editorPlugins,
          isExpanded: _expandedEditorPlugins,
          onToggle: () =>
              setState(() => _expandedEditorPlugins = !_expandedEditorPlugins),
          theme: theme,
        ),

        // Git Plugins
        // _buildPluginCategory(
        //   title: L10n.of(context).drawerGitIntegration,
        //   plugins: plugin_defs.gitPlugins,
        //   isExpanded: _expandedGitPlugins,
        //   onToggle: () => setState(() => _expandedGitPlugins = !_expandedGitPlugins),
        //   theme: theme,
        // ),

        // _isNativeAdLoaded && _nativeAd != null
        //       ? SizedBox(
        //           height: 120,
        //           child: AdWidget(ad: _nativeAd!),
        //         )
        //       : const SizedBox.shrink(),

        // Utility Plugins
        _buildPluginCategory(
          title: L10n.of(context).drawerUtilityPlugins,
          plugins: plugin_defs.utilityPlugins,
          isExpanded: _expandedUtilityPlugins,
          onToggle: () => setState(
            () => _expandedUtilityPlugins = !_expandedUtilityPlugins,
          ),
          theme: theme,
        ),

        // Experimental Plugins
        // _buildPluginCategory(
        //   title: L10n.of(context).drawerExperimental,
        //   plugins: plugin_defs.experimentalPlugins,
        //   isExpanded: _expandedExperimentalPlugins,
        //   onToggle: () => setState(() => _expandedExperimentalPlugins = !_expandedExperimentalPlugins),
        //   theme: theme,
        //   showExperimentalBadge: true,
        // ),

        // SliverToBoxAdapter(child:
        // _isNativeAdLoaded && _nativeAd != null
        //       ? SizedBox(
        //           height: 250,
        //           child: AdWidget(ad: _nativeAd!),
        //         )
        //       : const SizedBox.shrink(),
        // // SizedBox(height: 16)
        // ),
        // _isNativeAdLoaded && _nativeAd != null
        //       ? SizedBox(
        //           height: 120,
        //           child: AdWidget(ad: _nativeAd!),
        //         )
        //       : const SizedBox.shrink(),

        // Footer placed as a sliver so it only becomes visible when the user scrolls to the end
        SliverToBoxAdapter(child: _buildDrawerFooter(theme)),

        SliverToBoxAdapter(
          child: _isNativeAdLoaded && _nativeAd != null
              ? SizedBox(height: 250, child: AdWidget(ad: _nativeAd!))
              : const SizedBox.shrink(),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 60)),
        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, child) {
              final appState = ref.watch(appStateProvider);
              return Column(
                children: [
                  Text(
                    'v${appState.appVersion}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L10n.of(context).appName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildPluginCategory({
    required String title,
    required List<PluginDefinition> plugins,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ThemeData theme,
    bool showExperimentalBadge = false,
  }) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Category Header
        ListTile(
          leading: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          title: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              if (showExperimentalBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    L10n.of(context).drawerBeta,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: onToggle,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          visualDensity: const VisualDensity(vertical: -4),
        ),

        // Plugin Items
        if (isExpanded)
          ...plugins.map((plugin) => _buildPluginToggleItem(plugin, theme)),
      ]),
    );
  }

  Widget _buildPluginToggleItem(PluginDefinition plugin, ThemeData theme) {
    final isEnabled = Prefs().isPluginEnabled(plugin.id);
    final prefs = ref.watch(prefsProvider);

    return AbsorbPointer(
      absorbing: prefs.disabledByDefault(plugin.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isEnabled
              // ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              ? prefs.secondaryColor.withOpacity(0.1)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: ListTile(
          leading: Icon(
            plugin.icon,
            size: 18,
            color: isEnabled
                // ? theme.colorScheme.primary
                ? prefs.accentColor.withOpacity(0.4)
                : theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          title: Text(
            _localizedPluginName(plugin.id, context),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isEnabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          subtitle: (_localizedPluginDescription(plugin.id, context)).isNotEmpty
              ? Text(
                  _localizedPluginDescription(plugin.id, context),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isEnabled
                        ? theme.colorScheme.onSurface.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Switch.adaptive(
            value: prefs.disabledByDefault(plugin.id) ? true : isEnabled,
            onChanged: (enabled) async {
              // If enabling the file explorer, request storage permission first
              // if (plugin.id == 'file_explorer' && enabled) {
              //   final status = await Permission.storage.request();
              //     // Ask user to open app settings so they can grant permission
              //     // user have to grant permissions, No permissions requested
              //     // so the file explorer is enabled after sending the user to settings
              //     if (!status.isGranted) {
              //         final opened = await openAppSettings();
              //         if (!opened) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             SnackBar(content: Text(L10n.of(context).connectionFailed)),
              //           );
              //           return;
              //     }
              //   }
              //     if (!status.isGranted && enabled) {
              //       Prefs().enabledPlugins.remove("file_explorer");
              //       return;
              //     }
              // }

              await Prefs().setPluginEnabled(plugin.id, enabled);
              // Trigger a rebuild so changes are visible immediately
              setState(() {});
            },
            activeColor: prefs.secondaryColor,
            inactiveTrackColor: theme.colorScheme.surfaceVariant,
          ),
          onTap: () {
            // Optional: Show plugin details or settings
            _showPluginDetails(plugin);
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          visualDensity: const VisualDensity(vertical: -3),
        ),
      ),
    );
  }

  // =============================================
  // Drawer Footer
  // =============================================

  Widget _buildDrawerFooter(ThemeData theme) {
    final prefs = ref.watch(prefsProvider);
    final appState = ref.watch(appStateProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          // _isNativeAdLoaded && _nativeAd != null
          //     ? SizedBox(
          //         height: 120,
          //         width: double.infinity,
          //         child: AdWidget(ad: _nativeAd!),
          //       )
          //     : const SizedBox.shrink(),
          const SizedBox(height: 60),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFeedbackDialog(prefs),
                  icon: Icon(
                    Icons.feedback_outlined,
                    size: 16,
                    color: prefs.accentColor,
                  ),
                  label: Text(
                    L10n.of(context).drawerFeedback,
                    style: TextStyle(color: prefs.accentColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAboutDialogDonate(appState, prefs),
                  icon: Icon(
                    Icons.info_outlined,
                    size: 16,
                    color: prefs.accentColor,
                  ),
                  label: Text(
                    L10n.of(context).drawerAbout,
                    style: TextStyle(color: prefs.accentColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),

          // App Version and Info
          // Consumer(
          //   builder: (context, ref, child) {
          //     final appState = ref.watch(appStateProvider);
          //     return Column(
          //       children: [
          //         Text(
          //           'v${appState.appVersion}',
          //           style: theme.textTheme.labelSmall?.copyWith(
          //             color: theme.colorScheme.onSurface.withOpacity(0.5),
          //           ),
          //         ),
          //         const SizedBox(height: 4),
          //         Text(
          //           L10n.of(context).appName,
          //           style: theme.textTheme.labelSmall?.copyWith(
          //             color: theme.colorScheme.onSurface.withOpacity(0.4),
          //           ),
          //         ),
          //       ],
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  // Plugin lists are now imported from `lib/data/plugin_definitions.dart`.
  // Leaving these definitions removed to avoid duplication. Names and descriptions
  // are rendered via `L10n` at runtime so they can be localized.

  // =============================================
  // Helper Methods
  // =============================================

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return L10n.of(context).commonJustNow;
    if (difference.inHours < 1)
      return L10n.of(context).commonMinutes(difference.inMinutes);
    if (difference.inDays < 1)
      return L10n.of(context).commonHours(difference.inHours);
    if (difference.inDays == 1) return L10n.of(context).commonYesterday;
    if (difference.inDays < 7)
      return L10n.of(context).commonDays(difference.inDays);

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPluginDetails(PluginDefinition plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(plugin.icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(_localizedPluginName(plugin.name, context)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plugin.description != null) ...[
              // Text(plugin.description!),
              Text(_localizedPluginDescription(plugin.description!, context)),
              const SizedBox(height: 16),
            ],
            Text(
              _localizedPluginName(plugin.name, context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              // L10n.of(context).drawerPluginCategory(plugin.category.name.toUpperCase()),
              _localizedPluginCategory(plugin.category, context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).commonClose),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(Prefs prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).drawerSendFeedback),
        content: Text(L10n.of(context).drawerFeedbackBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              L10n.of(context).commonCancel,
              style: TextStyle(color: prefs.accentColor),
            ),
          ),
          AbsorbPointer(
            absorbing: true,
            child: FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(prefs.accentColor),
              ),
              onPressed: () async {
                // TODO: Implemented feedback submission, view it for Close Testers(change after publish)
                final Uri feedbackUrl = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.bilalworku.gzip',
                ); // Replace with your actual PLAYSTORE link after publish
                if (await canLaunchUrl(feedbackUrl)) {
                  await launchUrl(feedbackUrl);
                } else {
                  // Handle the case where the URL cannot be launched (e.g., no browser installed)
                  // You might display a SnackBar or an AlertDialog to inform the user.
                  print('Could not launch $feedbackUrl');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(L10n.of(context).drawerFeedbackComingSoon),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(
                L10n.of(context).drawerSendFeedback,
              ), // change when added
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialogDonate(AppState appState, Prefs prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // title: Text(L10n.of(context).appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              spacing: 10,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40.0),
                  child: Image.asset(
                    'assets/icons/git-explorer-icon.png',
                    height: 60,
                    width: 60,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L10n.of(context).appName,
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'v${appState.appVersion}',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text(L10n.of(context).appAbout, style: TextStyle(fontSize: 15)),
            const SizedBox(height: 25),
            Text(
              L10n.of(context).appDonateTips,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              L10n.of(context).commonClose,
              style: TextStyle(color: prefs.accentColor),
            ),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(prefs.accentColor),
            ),
            onPressed: () async {
              // TODO: Implement donate submission
              final Uri donateUrl = Uri.parse(
                'https://github.com/uncrr',
              ); // Replace with your actual donation link
              if (await canLaunchUrl(donateUrl)) {
                await launchUrl(donateUrl);
              } else {
                // Handle the case where the URL cannot be launched (e.g., no browser installed)
                // You might display a SnackBar or an AlertDialog to inform the user.
                print('Could not launch $donateUrl');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(L10n.of(context).commonFailed)),
                );
              }
              Navigator.of(context).pop();
            },
            child: Text(L10n.of(context).appDonate),
          ),
        ],
      ),
    );
  }

  // void _showAboutDialogLicenses() {
  //   final appState = ref.read(appStateProvider);

  //   showAboutDialog(
  //     context: context,
  //     applicationName: L10n.of(context).appName,
  //     applicationVersion: 'v${appState.appVersion}',
  //     applicationIcon: Image.asset('assets/icons/git-explorer-icon.png' , height: 48, width: 48,),
  //     children: [
  //       const SizedBox(height: 16),
  //       Text(L10n.of(context).appAbout),
  //       const SizedBox(height: 16),
  //       Text(
  //         L10n.of(context).drawerFirstInstalled(_formatDate(appState.firstInstallDate, context)),
  //         style: Theme.of(context).textTheme.bodySmall,
  //       ),
  //     ],
  //   );
  // }

  // Localized plugin name lookup. Keep a switch on plugin id so the id stays
  // canonical for pref lookups, while the displayed string comes from L10n.
  String _localizedPluginName(String id, BuildContext context) {
    final l = L10n.of(context);
    switch (id) {
      case 'readonly_mode':
        return l.readonlyModeName;
      case 'syntax_highlighting':
        return l.syntaxHighlightingName;
      case 'code_folding':
        return l.codeFoldingName;
      // case 'bracket_matching':
      //   return l.bracketMatchingName;
      case 'advanced_editor_options':
        return l.advancedEditorName;
      case 'git_history':
        return l.gitHistoryName;
      // case 'git_lens':
      //   return l.gitLensName;
      // case 'branch_manager':
      //   return l.branchManagerName;
      case 'file_explorer':
        return l.fileExplorerName;
      // case 'search_replace':
      //   return l.searchReplaceName;
      case 'terminal':
        return l.terminalName;
      case 'theme_customizer':
        return l.themeCustomizerName;
      case 'ai_assist':
        return l.aiAssistName;
      // case 'real_time_collab':
      //   return l.realtimeCollabName;
      // case 'performance_monitor':
      //   return l.performanceMonitorName;
      default:
        return id;
    }
  }

  String _localizedPluginDescription(String id, BuildContext context) {
    final l = L10n.of(context);
    switch (id) {
      case 'readonly_mode':
        return l.readonlyModeDescription;
      case 'syntax_highlighting':
        return l.syntaxHighlightingDescription;
      case 'code_folding':
        return l.codeFoldingDescription;
      // case 'bracket_matching':
      //   return l.bracketMatchingDescription;
      case 'advanced_editor_options':
        return l.advancedEditorDescription;
      case 'git_history':
        return l.gitHistoryDescription;
      // case 'git_lens':
      //   return l.gitLensDescription;
      // case 'branch_manager':
      //   return l.branchManagerDescription;
      case 'file_explorer':
        return l.fileExplorerDescription;
      // case 'search_replace':
      //   return l.searchReplaceDescription;
      case 'terminal':
        return l.terminalDescription;
      case 'theme_customizer':
        return l.themeCustomizerDescription;
      case 'ai_assist':
        return l.aiAssistDescription;
      // case 'real_time_collab':
      //   return l.realtimeCollabDescription;
      // case 'performance_monitor':
      //   return l.performanceMonitorDescription;
      default:
        return '';
    }
  }
}

String _localizedPluginCategory(PluginCategory category, BuildContext context) {
  final l = L10n.of(context);
  switch (category) {
    case PluginCategory.editor:
      return l.drawerEditorPlugins;
    case PluginCategory.utility:
      return l.drawerUtilityPlugins;
    case PluginCategory.git:
      return l.drawerGitIntegration;
    case PluginCategory.experimental:
      return l.drawerExperimental;
  }
}
