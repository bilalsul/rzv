import 'package:flutter/material.dart';
import 'package:rzv/enums/options/plugin.dart';
import 'package:rzv/models/plugin.dart';

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
  PluginDefinition(
    id: Plugin.advancedEditorOptions.id,
    name: Plugin.advancedEditorOptions.id,
    description: Plugin.advancedEditorOptions.id,
    icon: Icons.edit,
    category: PluginCategory.editor,
  ),
];

const List<PluginDefinition> gitPlugins = [
];

List<PluginDefinition> utilityPlugins = [
  PluginDefinition(
    id: Plugin.fileExplorer.id,
    name: Plugin.fileExplorer.id,
    description: Plugin.fileExplorer.id,
    icon: Icons.folder_outlined,
    category: PluginCategory.utility,
  ),
  PluginDefinition(
    id: Plugin.themeCustomizer.id,
    name: Plugin.themeCustomizer.id,
    description: Plugin.themeCustomizer.id,
    icon: Icons.palette_outlined,
    category: PluginCategory.utility,
  ),
];

List<PluginDefinition> experimentalPlugins = [
  // PluginDefinition(
  //   id: Plugin.ai.id,
  //   name: Plugin.ai.id,
  //   description: Plugin.ai.id,
  //   icon: Icons.auto_awesome_outlined,
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
