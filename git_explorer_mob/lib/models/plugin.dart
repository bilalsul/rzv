import 'package:flutter/material.dart';

enum PluginCategory {
  editor('Editor', Icons.edit, 'Editor enhancements and features'),
  git('Git', Icons.history, 'Version control and history'),
  utility('Utility', Icons.build, 'Tools and utilities'),
  experimental('Experimental', Icons.science, 'Beta features and experiments');

  final String displayName;
  final IconData icon;
  final String description;

  const PluginCategory(this.displayName, this.icon, this.description);
}

class PluginDefinition {
  final String id;
  final String name;
  final String? description;
  final IconData icon;
  final PluginCategory category;
  final String version;
  final String author;
  final List<String> dependencies;
  final List<String> conflictsWith;
  final Map<String, dynamic> defaultConfig;
  final bool requiresRestart;
  final bool enabledByDefault;
  final DateTime? lastUpdated;

  const PluginDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.category,
    this.version = '1.0.0',
    this.author = 'Flutter Code Editor',
    this.dependencies = const [],
    this.conflictsWith = const [],
    this.defaultConfig = const {},
    this.requiresRestart = false,
    this.enabledByDefault = true,
    this.lastUpdated,
  });

  PluginDefinition copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    PluginCategory? category,
    String? version,
    String? author,
    List<String>? dependencies,
    List<String>? conflictsWith,
    Map<String, dynamic>? defaultConfig,
    bool? requiresRestart,
    bool? enabledByDefault,
    DateTime? lastUpdated,
  }) {
    return PluginDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      version: version ?? this.version,
      author: author ?? this.author,
      dependencies: dependencies ?? this.dependencies,
      conflictsWith: conflictsWith ?? this.conflictsWith,
      defaultConfig: defaultConfig ?? this.defaultConfig,
      requiresRestart: requiresRestart ?? this.requiresRestart,
      enabledByDefault: enabledByDefault ?? this.enabledByDefault,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': _iconToCode(icon),
      'category': category.name,
      'version': version,
      'author': author,
      'dependencies': dependencies,
      'conflictsWith': conflictsWith,
      'defaultConfig': defaultConfig,
      'requiresRestart': requiresRestart,
      'enabledByDefault': enabledByDefault,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  factory PluginDefinition.fromMap(Map<String, dynamic> map) {
    return PluginDefinition(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: _iconFromCode(map['icon'] as String?),
      category: PluginCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => PluginCategory.utility,
      ),
      version: map['version'] as String? ?? '0.0.1',
      author: map['author'] as String? ?? 'Git Explorer',
      dependencies: List<String>.from(map['dependencies'] as List? ?? []),
      conflictsWith: List<String>.from(map['conflictsWith'] as List? ?? []),
      defaultConfig: Map<String, dynamic>.from(map['defaultConfig'] as Map? ?? {}),
      requiresRestart: map['requiresRestart'] as bool? ?? false,
      enabledByDefault: map['enabledByDefault'] as bool? ?? true,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] as int)
          : null,
    );
  }

  static String _iconToCode(IconData icon) {
    // Convert IconData to a string representation
    return '${icon.codePoint}:${icon.fontFamily}:${icon.fontPackage}';
  }

  static IconData _iconFromCode(String? code) {
    if (code == null) return Icons.extension;
    
    try {
      final parts = code.split(':');
      return IconData(
        int.parse(parts[0]),
        fontFamily: parts.length > 1 ? parts[1] : null,
        fontPackage: parts.length > 2 ? parts[2] : null,
      );
    } catch (e) {
      return Icons.extension;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PluginDefinition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PluginDefinition(id: $id, name: $name, category: $category)';
  }
}

class PluginState {
  final PluginDefinition definition;
  final bool isEnabled;
  final Map<String, dynamic> config;
  final bool isLoading;
  final String? error;
  final DateTime? lastUsed;

  const PluginState({
    required this.definition,
    required this.isEnabled,
    required this.config,
    this.isLoading = false,
    this.error,
    this.lastUsed,
  });

  PluginState copyWith({
    PluginDefinition? definition,
    bool? isEnabled,
    Map<String, dynamic>? config,
    bool? isLoading,
    String? error,
    DateTime? lastUsed,
  }) {
    return PluginState(
      definition: definition ?? this.definition,
      isEnabled: isEnabled ?? this.isEnabled,
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'definition': definition.toMap(),
      'isEnabled': isEnabled,
      'config': config,
      'isLoading': isLoading,
      'error': error,
      'lastUsed': lastUsed?.millisecondsSinceEpoch,
    };
  }

  factory PluginState.fromMap(Map<String, dynamic> map) {
    return PluginState(
      definition: PluginDefinition.fromMap(Map<String, dynamic>.from(map['definition'])),
      isEnabled: map['isEnabled'] as bool,
      config: Map<String, dynamic>.from(map['config'] as Map? ?? {}),
      isLoading: map['isLoading'] as bool? ?? false,
      error: map['error'] as String?,
      lastUsed: map['lastUsed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUsed'] as int)
          : null,
    );
  }
}

class PluginRegistry {
  final Map<String, PluginDefinition> _plugins = {};

  void registerPlugin(PluginDefinition plugin) {
    _plugins[plugin.id] = plugin;
  }

  void unregisterPlugin(String pluginId) {
    _plugins.remove(pluginId);
  }

  PluginDefinition? getPlugin(String pluginId) {
    return _plugins[pluginId];
  }

  List<PluginDefinition> getPluginsByCategory(PluginCategory category) {
    return _plugins.values
        .where((plugin) => plugin.category == category)
        .toList();
  }

  List<PluginDefinition> getAllPlugins() {
    return _plugins.values.toList();
  }

  List<PluginDefinition> getEnabledPlugins(List<String> enabledIds) {
    return enabledIds
        .map((id) => _plugins[id])
        .whereType<PluginDefinition>()
        .toList();
  }

  bool validateDependencies(String pluginId, List<String> enabledPlugins) {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;

    for (final dependency in plugin.dependencies) {
      if (!enabledPlugins.contains(dependency)) {
        return false;
      }
    }

    for (final conflict in plugin.conflictsWith) {
      if (enabledPlugins.contains(conflict)) {
        return false;
      }
    }

    return true;
  }
}

// Default plugin definitions
// final defaultPlugins = [
//   PluginDefinition(
//     id: 'readonly_mode',
//     name: 'Read-Only Mode',
//     description: 'Prevent accidental edits to files',
//     icon: Icons.lock_outlined,
//     category: PluginCategory.editor,
//     defaultConfig: {
//       'autoEnableLargeFiles': true,
//       'fileSizeThreshold': 1000000,
//       'showWarning': true,
//     },
//   ),
//   PluginDefinition(
//     id: 'syntax_highlighting',
//     name: 'Syntax Highlighting',
//     description: 'Colorful code syntax for better readability',
//     icon: Icons.color_lens_outlined,
//     category: PluginCategory.editor,
//     enabledByDefault: true,
//     defaultConfig: {
//       'theme': 'vs-dark',
//       'fontSize': 14.0,
//     },
//   ),
//   PluginDefinition(
//     id: 'code_folding',
//     name: 'Code Folding',
//     description: 'Collapse and expand code blocks',
//     icon: Icons.unfold_less_outlined,
//     category: PluginCategory.editor,
//     enabledByDefault: true,
//   ),
//   PluginDefinition(
//     id: 'bracket_matching',
//     name: 'Bracket Matching',
//     description: 'Highlight matching brackets and parentheses',
//     icon: Icons.code_outlined,
//     category: PluginCategory.editor,
//     enabledByDefault: true,
//   ),
//   PluginDefinition(
//     id: 'git_history',
//     name: 'Git History',
//     description: 'View commit history and differences',
//     icon: Icons.history_outlined,
//     category: PluginCategory.git,
//     enabledByDefault: true,
//     defaultConfig: {
//       'maxCommitHistory': 1000,
//       'showAuthorNames': true,
//       'showCommitHashes': true,
//     },
//   ),
//   PluginDefinition(
//     id: 'git_lens',
//     name: 'GitLens',
//     description: 'Enhanced git blame annotations',
//     icon: Icons.remove_red_eye_outlined,
//     category: PluginCategory.git,
//     dependencies: ['git_history'],
//     defaultConfig: {
//       'showBlameAnnotations': true,
//       'highlightRecentChanges': true,
//     },
//   ),
//   PluginDefinition(
//     id: 'file_explorer',
//     name: 'File Explorer',
//     description: 'Browse and manage project files',
//     icon: Icons.folder_outlined,
//     category: PluginCategory.utility,
//     enabledByDefault: true,
//     defaultConfig: {
//       'showHiddenFiles': false,
//       'sortBy': 'name',
//       'sortOrder': 'ascending',
//     },
//   ),
//   PluginDefinition(
//     id: 'search_replace',
//     name: 'Search & Replace',
//     description: 'Advanced find and replace across files',
//     icon: Icons.search_outlined,
//     category: PluginCategory.utility,
//     enabledByDefault: true,
//     defaultConfig: {
//       'caseSensitive': false,
//       'useRegex': false,
//       'wholeWord': false,
//     },
//   ),
//   PluginDefinition(
//     id: 'theme_customizer',
//     name: 'Theme Customizer',
//     description: 'Customize editor and app appearance',
//     icon: Icons.palette_outlined,
//     category: PluginCategory.utility,
//     enabledByDefault: true,
//   ),
//   PluginDefinition(
//     id: 'ai_assist',
//     name: 'AI Code Assistant',
//     description: 'Get AI-powered code suggestions',
//     icon: Icons.auto_awesome_outlined,
//     category: PluginCategory.experimental,
//     requiresRestart: true,
//     enabledByDefault: false,
//   ),
//   PluginDefinition(
//     id: 'performance_monitor',
//     name: 'Performance Monitor',
//     description: 'Monitor app performance metrics',
//     icon: Icons.monitor_heart_outlined,
//     category: PluginCategory.experimental,
//     enabledByDefault: false,
//   ),
// ];