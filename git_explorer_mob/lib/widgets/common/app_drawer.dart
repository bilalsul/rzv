import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Navigation moved to AppShell
// Navigation and plugin state now come from Prefs

// Providers
import '../../providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _expandedGitPlugins = true;
  bool _expandedUtilityPlugins = true;
  bool _expandedExperimentalPlugins = false;

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
          Expanded(
            child: _buildPluginTogglesSection(prefs, theme),
          ),
          // Footer is rendered as the last sliver inside the scrollable plugin section
        ],
    ),
    );
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
              Icon(
                Icons.code,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                L10n.of(context).appName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
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
                const SizedBox(height: 6),
                // Prefer explicit currentProjectName, otherwise fall back to lastOpenedProject basename
                Text(
                  prefs.currentProjectName.isNotEmpty
                      ? prefs.currentProjectName
                      : (prefs.lastOpenedProject.isNotEmpty ? prefs.lastOpenedProject.split('/').last : L10n.of(context).drawerNoProjectOpen),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                // Show the filename currently open in the editor (if any)
                Builder(builder: (_) {
                  final openFile = prefs.currentOpenFile;
                  final openFileName = openFile.isNotEmpty ? openFile.split('/').last : '';
                  return openFileName.isNotEmpty
                      ? Text(
                          openFileName,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.65)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink();
                }),
                // Last opened time for the project (relative, no seconds)
                Builder(builder: (_) {
                  final lastOpened = prefs.lastOpenedProjectTime;
                  final lastText = lastOpened.millisecondsSinceEpoch > 0 ? _formatDate(lastOpened, context) : L10n.of(context).drawerNever;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(L10n.of(context).drawerLastOpened(lastText), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  );
                }),
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
          onToggle: () => setState(() => _expandedEditorPlugins = !_expandedEditorPlugins),
          theme: theme,
        ),

        // Git Plugins
        _buildPluginCategory(
          title: L10n.of(context).drawerGitIntegration,
          plugins: plugin_defs.gitPlugins,
          isExpanded: _expandedGitPlugins,
          onToggle: () => setState(() => _expandedGitPlugins = !_expandedGitPlugins),
          theme: theme,
        ),

        // Utility Plugins
        _buildPluginCategory(
          title: L10n.of(context).drawerUtilityPlugins,
          plugins: plugin_defs.utilityPlugins,
          isExpanded: _expandedUtilityPlugins,
          onToggle: () => setState(() => _expandedUtilityPlugins = !_expandedUtilityPlugins),
          theme: theme,
        ),

        // Experimental Plugins
        _buildPluginCategory(
          title: L10n.of(context).drawerExperimental,
          plugins: plugin_defs.experimentalPlugins,
          isExpanded: _expandedExperimentalPlugins,
          onToggle: () => setState(() => _expandedExperimentalPlugins = !_expandedExperimentalPlugins),
          theme: theme,
          showExperimentalBadge: true,
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // Footer placed as a sliver so it only becomes visible when the user scrolls to the end
        SliverToBoxAdapter(child: _buildDrawerFooter(theme)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isEnabled
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: ListTile(
        leading: Icon(
          plugin.icon,
          size: 18,
          color: isEnabled
              ? theme.colorScheme.primary
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
          value: isEnabled,
          onChanged: (enabled) async {
            // If enabling the file explorer, request storage permission first
            if (plugin.id == 'file_explorer' && enabled) {
              final status = await Permission.storage.request();
              if (!status.isGranted) {
                // Ask user to open app settings so they can grant permission
                // user have to grant permissions, No permissions requested
                // so the file explorer is enabled after sending the user to settings
                final opened = await openAppSettings();
                if (!opened) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(L10n.of(context).connectionFailed)),
                  );
                  return;
                }
              }
            }

            await Prefs().setPluginEnabled(plugin.id, enabled);
            // Trigger a rebuild so changes are visible immediately
            setState(() {});
          },
          activeColor: theme.colorScheme.primary,
          inactiveTrackColor: theme.colorScheme.surfaceVariant,
        ),
        onTap: () {
          // Optional: Show plugin details or settings
          _showPluginDetails(plugin);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: const VisualDensity(vertical: -3),
      ),
    );
  }

  // =============================================
  // Drawer Footer
  // =============================================

  Widget _buildDrawerFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showFeedbackDialog,
                  icon: const Icon(Icons.feedback_outlined, size: 16),
                  label: Text(L10n.of(context).drawerFeedback),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAboutDialog,
                  icon: const Icon(Icons.info_outlined, size: 16),
                  label: Text(L10n.of(context).drawerAbout),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // App Version and Info
          Consumer(
            builder: (context, ref, child) {
              final appState = ref.watch(appStateProvider);
              return Column(
                children: [
                  Text(
                    'v${appState.appVersion} (${appState.buildNumber})',
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
    if (difference.inHours < 1) return L10n.of(context).commonMinutes(difference.inMinutes);
    if (difference.inDays < 1) return L10n.of(context).commonHours(difference.inHours);
    if (difference.inDays == 1) return L10n.of(context).commonYesterday;
    if (difference.inDays < 7) return L10n.of(context).commonDays(difference.inDays);

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
            Text(plugin.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plugin.description != null) ...[
              Text(plugin.description!),
              const SizedBox(height: 16),
            ],
            Text(
              L10n.of(context).drawerPluginId(plugin.id),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              L10n.of(context).drawerPluginCategory(plugin.category.name.toUpperCase()),
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

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).drawerSendFeedback),
        content: Text(L10n.of(context).drawerFeedbackBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement feedback submission
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(L10n.of(context).drawerFeedbackComingSoon)),
              );
            },
            child: Text(L10n.of(context).drawerSendFeedback),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final appState = ref.read(appStateProvider);
    
    showAboutDialog(
      context: context,
      applicationName: L10n.of(context).appName,
      applicationVersion: 'v${appState.appVersion} (${appState.buildNumber})',
      applicationIcon: const Icon(Icons.code, size: 48),
      children: [
        const SizedBox(height: 16),
        Text(L10n.of(context).drawerAboutDescription),
        const SizedBox(height: 16),
        Text(
          L10n.of(context).drawerFirstInstalled(_formatDate(appState.firstInstallDate, context)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

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
      case 'bracket_matching':
        return l.bracketMatchingName;
      case 'git_history':
        return l.gitHistoryName;
      case 'git_lens':
        return l.gitLensName;
      case 'branch_manager':
        return l.branchManagerName;
      case 'file_explorer':
        return l.fileExplorerName;
      case 'search_replace':
        return l.searchReplaceName;
      case 'terminal':
        return l.terminalName;
      case 'theme_customizer':
        return l.themeCustomizerName;
      case 'ai_assist':
        return l.aiAssistName;
      case 'real_time_collab':
        return l.realtimeCollabName;
      case 'performance_monitor':
        return l.performanceMonitorName;
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
      case 'bracket_matching':
        return l.bracketMatchingDescription;
      case 'git_history':
        return l.gitHistoryDescription;
      case 'git_lens':
        return l.gitLensDescription;
      case 'branch_manager':
        return l.branchManagerDescription;
      case 'file_explorer':
        return l.fileExplorerDescription;
      case 'search_replace':
        return l.searchReplaceDescription;
      case 'terminal':
        return l.terminalDescription;
      case 'theme_customizer':
        return l.themeCustomizerDescription;
      case 'ai_assist':
        return l.aiAssistDescription;
      case 'real_time_collab':
        return l.realtimeCollabDescription;
      case 'performance_monitor':
        return l.performanceMonitorDescription;
      default:
        return '';
    }
  }
}