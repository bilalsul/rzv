import 'package:flutter/material.dart';
import 'package:git_explorer_mob/models/plugin.dart';

// This file centralizes the canonical plugin IDs, icons and categories.
// Names/descriptions are localized at render time via `L10n.of(context)`.

const List<PluginDefinition> editorPlugins = [
  PluginDefinition(
    id: 'readonly_mode',
    name: 'readonly_mode',
    description: 'readonly_mode',
    icon: Icons.lock_outline,
    category: PluginCategory.editor,
  ),
  PluginDefinition(
    id: 'syntax_highlighting',
    name: 'syntax_highlighting',
    description: 'syntax_highlighting',
    icon: Icons.color_lens_outlined,
    category: PluginCategory.editor,
  ),
  PluginDefinition(
    id: 'code_folding',
    name: 'code_folding',
    description: 'code_folding',
    icon: Icons.wrap_text,
    category: PluginCategory.editor,
  ),
  PluginDefinition(
    id: 'advanced_editor_options',
    name: 'advanced_editor_options',
    description: 'advanced_editor_options',
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

const List<PluginDefinition> utilityPlugins = [
  PluginDefinition(
    id: 'file_explorer',
    name: 'file_explorer',
    description: 'file_explorer',
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
    id: 'theme_customizer',
    name: 'theme_customizer',
    description: 'theme_customizer',
    icon: Icons.palette_outlined,
    category: PluginCategory.utility,
  ),
];

const List<PluginDefinition> experimentalPlugins = [
  PluginDefinition(
    id: 'ai_assist',
    name: 'ai_assist',
    description: 'ai_assist',
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
];
