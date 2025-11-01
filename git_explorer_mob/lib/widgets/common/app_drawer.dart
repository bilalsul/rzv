import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Navigation moved to AppShell
// Navigation and plugin state now come from Prefs

// Providers
import '../../providers/shared_preferences_provider.dart';

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
                'Git Explorer',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Current Project Info (sourced from Prefs)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Project',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                prefs.lastOpenedProject.isNotEmpty
                    ? prefs.lastOpenedProject.split('/').last
                    : 'No project open',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (prefs.lastOpenedProject.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Last opened: ${_formatDate(prefs.sessionStartTime)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
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
                  'PLUGINS & FEATURES',
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
          title: 'Editor Plugins',
          plugins: _editorPlugins,
          isExpanded: _expandedEditorPlugins,
          onToggle: () => setState(() => _expandedEditorPlugins = !_expandedEditorPlugins),
          theme: theme,
        ),

        // Git Plugins
        _buildPluginCategory(
          title: 'Git Integration',
          plugins: _gitPlugins,
          isExpanded: _expandedGitPlugins,
          onToggle: () => setState(() => _expandedGitPlugins = !_expandedGitPlugins),
          theme: theme,
        ),

        // Utility Plugins
        _buildPluginCategory(
          title: 'Utility Plugins',
          plugins: _utilityPlugins,
          isExpanded: _expandedUtilityPlugins,
          onToggle: () => setState(() => _expandedUtilityPlugins = !_expandedUtilityPlugins),
          theme: theme,
        ),

        // Experimental Plugins
        _buildPluginCategory(
          title: 'Experimental',
          plugins: _experimentalPlugins,
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
                    'BETA',
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
          plugin.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isEnabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        subtitle: plugin.description != null
            ? Text(
                plugin.description!,
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
                  label: const Text('Feedback'),
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
                  label: const Text('About'),
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
                    'Git Explorer',
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

  // =============================================
  // Plugin Definitions
  // =============================================

  static final List<PluginDefinition> _editorPlugins = [
    PluginDefinition(
      id: 'readonly_mode',
      name: 'Read-Only Mode',
      description: 'Prevent accidental edits to files',
      icon: Icons.lock_outline,
      category: PluginCategory.editor,
    ),
    PluginDefinition(
      id: 'syntax_highlighting',
      name: 'Syntax Highlighting',
      description: 'Colorful code syntax for better readability',
      icon: Icons.color_lens_outlined,
      category: PluginCategory.editor,
    ),
    PluginDefinition(
      id: 'code_folding',
      name: 'Code Folding',
      description: 'Collapse and expand code blocks',
      icon: Icons.unfold_less_outlined,
      category: PluginCategory.editor,
    ),
    PluginDefinition(
      id: 'bracket_matching',
      name: 'Bracket Matching',
      description: 'Highlight matching brackets and parentheses',
      icon: Icons.code_outlined,
      category: PluginCategory.editor,
    ),
  ];

  static final List<PluginDefinition> _gitPlugins = [
    PluginDefinition(
      id: 'git_history',
      name: 'Git History',
      description: 'View commit history and differences',
      icon: Icons.history_outlined,
      category: PluginCategory.git,
    ),
    PluginDefinition(
      id: 'git_lens',
      name: 'GitLens',
      description: 'Enhanced git blame annotations',
      icon: Icons.remove_red_eye_outlined,
      category: PluginCategory.git,
    ),
    PluginDefinition(
      id: 'branch_manager',
      name: 'Branch Manager',
      description: 'Easy branch creation and switching',
      icon: Icons.account_tree_outlined,
      category: PluginCategory.git,
    ),
  ];

  static final List<PluginDefinition> _utilityPlugins = [
    PluginDefinition(
      id: 'file_explorer',
      name: 'File Explorer',
      description: 'Browse and manage project files',
      icon: Icons.folder_outlined,
      category: PluginCategory.utility,
    ),
    PluginDefinition(
      id: 'search_replace',
      name: 'Search & Replace',
      description: 'Advanced find and replace across files',
      icon: Icons.search_outlined,
      category: PluginCategory.utility,
    ),
    PluginDefinition(
      id: 'terminal',
      name: 'Integrated Terminal',
      description: 'Run commands without leaving the editor',
      icon: Icons.terminal_outlined,
      category: PluginCategory.utility,
    ),
    PluginDefinition(
      id: 'theme_customizer',
      name: 'Theme Customizer',
      description: 'Customize editor and app appearance',
      icon: Icons.palette_outlined,
      category: PluginCategory.utility,
    ),
  ];

  static final List<PluginDefinition> _experimentalPlugins = [
    PluginDefinition(
      id: 'ai_assist',
      name: 'AI Code Assistant',
      description: 'Get AI-powered code suggestions',
      icon: Icons.auto_awesome_outlined,
      category: PluginCategory.experimental,
    ),
    PluginDefinition(
      id: 'real_time_collab',
      name: 'Real-time Collaboration',
      description: 'Edit code with others in real-time',
      icon: Icons.people_outlined,
      category: PluginCategory.experimental,
    ),
    PluginDefinition(
      id: 'performance_monitor',
      name: 'Performance Monitor',
      description: 'Monitor app performance metrics',
      icon: Icons.monitor_heart_outlined,
      category: PluginCategory.experimental,
    ),
  ];

  // =============================================
  // Helper Methods
  // =============================================

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

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
              'Plugin ID: ${plugin.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Category: ${plugin.category.name.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'We\'d love to hear your feedback about the Flutter Code Editor!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement feedback submission
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback feature coming soon!')),
              );
            },
            child: const Text('Send Feedback'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final appState = ref.read(appStateProvider);
    
    showAboutDialog(
      context: context,
      applicationName: 'Flutter Code Editor',
      applicationVersion: 'v${appState.appVersion} (${appState.buildNumber})',
      applicationIcon: const Icon(Icons.code, size: 48),
      children: [
        const SizedBox(height: 16),
        const Text(
          'A powerful code editor built with Flutter and Monaco, '
          'designed for mobile development workflows.',
        ),
        const SizedBox(height: 16),
        Text(
          'First installed: ${_formatDate(appState.firstInstallDate)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}