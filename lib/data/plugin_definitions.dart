import 'package:flutter/material.dart';
import 'package:rzv/enums/options/plugin.dart';
import 'package:rzv/models/plugin.dart';

// This file centralizes the canonical plugin IDs, icons and categories.
// Names/descriptions are localized at render time via `L10n.of(context)`.

List<PluginDefinition> editorPlugins = [
  PluginDefinition(
    id: Plugin.readOnlyMode.id,
    name: Plugin.readOnlyMode.id,
    description: Plugin.readOnlyMode.id,
    icon: Icons.lock_outline,
    category: PluginCategory.editor,
  ),
  PluginDefinition(
    id: Plugin.syntaxHighlighting.id,
    name: Plugin.syntaxHighlighting.id,
    description: Plugin.syntaxHighlighting.id,
    icon: Icons.color_lens_outlined,
    category: PluginCategory.editor,
  ),
  // PluginDefinition(
  //   id: Plugin.codeFolding.id,
  //   name: Plugin.codeFolding.id,
  //   description: Plugin.codeFolding.id,
  //   icon: Icons.wrap_text,
  //   category: PluginCategory.editor,
  // ),
  PluginDefinition(
    id: Plugin.advancedEditorOptions.id,
    name: Plugin.advancedEditorOptions.id,
    description: Plugin.advancedEditorOptions.id,
    icon: Icons.edit,
    category: PluginCategory.editor,
  ),
  // PluginDefinition(
  //   id: 'bracket_matching',
  //   name: 'bracket_matching',
  //   description: 'bracket_matching',
  //   icon: Icons.code_outlined,
  //   category: PluginCategory.editor,
  // ),
];

const List<PluginDefinition> gitPlugins = [
  // PluginDefinition(
  //   id: 'git_history',
  //   name: 'git_history',
  //   description: 'git_history',
  //   icon: Icons.history_outlined,
  //   category: PluginCategory.git,
  // ),
  // PluginDefinition(
  //   id: 'git_lens',
  //   name: 'git_lens',
  //   description: 'git_lens',
  //   icon: Icons.remove_red_eye_outlined,
  //   category: PluginCategory.git,
  // ),
  // PluginDefinition(
  //   id: 'branch_manager',
  //   name: 'branch_manager',
  //   description: 'branch_manager',
  //   icon: Icons.account_tree_outlined,
  //   category: PluginCategory.git,
  // ),
];

List<PluginDefinition> utilityPlugins = [
  PluginDefinition(
    id: Plugin.fileExplorer.id,
    name: Plugin.fileExplorer.id,
    description: Plugin.fileExplorer.id,
    icon: Icons.folder_outlined,
    category: PluginCategory.utility,
  ),
  // PluginDefinition(
  //   id: 'search_replace',
  //   name: 'search_replace',
  //   description: 'search_replace',
  //   icon: Icons.search_outlined,
  //   category: PluginCategory.utility,
  // ),
  // PluginDefinition(
  //   id: 'terminal',
  //   name: 'terminal',
  //   description: 'terminal',
  //   icon: Icons.terminal_outlined,
  //   category: PluginCategory.utility,
  // ),
  PluginDefinition(
    id: Plugin.themeCustomizer.id,
    name: Plugin.themeCustomizer.id,
    description: Plugin.themeCustomizer.id,
    icon: Icons.palette_outlined,
    category: PluginCategory.utility,
  ),
];

List<PluginDefinition> experimentalPlugins = [
  PluginDefinition(
    id: Plugin.ai.id,
    name: Plugin.ai.id,
    description: Plugin.ai.id,
    icon: Icons.auto_awesome_outlined,
    category: PluginCategory.experimental,
  ),
  // PluginDefinition(
  //   id: 'git_history',
  //   name: 'git_history',
  //   description: 'git_history',
  //   icon: Icons.history_outlined,
  //   category: PluginCategory.experimental, //change to git
  // ),
  // PluginDefinition(
  //   id: 'terminal',
  //   name: 'terminal',
  //   description: 'terminal',
  //   icon: Icons.terminal_outlined,
  //   category: PluginCategory.experimental, // change to utility
  // ),
  // PluginDefinition(
  //   id: 'real_time_collab',
  //   name: 'real_time_collab',
  //   description: 'real_time_collab',
  //   icon: Icons.people_outlined,
  //   category: PluginCategory.experimental,
  // ),
  // PluginDefinition(
  //   id: 'performance_monitor',
  //   name: 'performance_monitor',
  //   description: 'performance_monitor',
  //   icon: Icons.monitor_heart_outlined,
  //   category: PluginCategory.experimental,
  // ),
  PluginDefinition(
    id: Plugin.zipManager.id,
    name: Plugin.zipManager.id,
    description: Plugin.zipManager.id,
    icon: Icons.folder_zip,
    category: PluginCategory.experimental,
  ),
];
