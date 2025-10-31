import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/plugin_provider.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/providers/theme_provider.dart';
import 'package:git_explorer_mob/widgets/settings/plugin_settings_panel.dart';
import 'package:git_explorer_mob/providers/editor_settings_provider.dart';
import 'package:git_explorer_mob/providers/git_settings_provider.dart';
import 'package:git_explorer_mob/providers/ai_settings_provider.dart';
import 'package:git_explorer_mob/providers/file_explorer_settings_provider.dart';
import 'package:git_explorer_mob/enums/options/supported_language.dart';

/// SettingsScreen no longer contains plugin toggles (they live in AppDrawer).
/// This screen exposes plugin-specific settings panels and connects them
/// to plugin configuration stored through `pluginSettingsProvider`.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // convenience flags: whether plugin is enabled (AppDrawer toggles these)
    final editorEnabled = ref.watch(isPluginEnabledProvider('editor'));
    final gitEnabled = ref.watch(isPluginEnabledProvider('git_history'));
    final aiEnabled = ref.watch(isPluginEnabledProvider('ai_assist'));
    final fileExplorerEnabled = ref.watch(isPluginEnabledProvider('file_explorer'));

    final editorCfg = ref.watch(editorSettingsProvider);
    final gitCfg = ref.watch(gitSettingsProvider);
    final aiCfg = ref.watch(aiSettingsProvider);
    final feCfg = ref.watch(fileExplorerSettingsProvider);

    final editorCtrl = ref.read(editorSettingsProvider.notifier);
    final gitCtrl = ref.read(gitSettingsProvider.notifier);
    final aiCtrl = ref.read(aiSettingsProvider.notifier);
    final feCtrl = ref.read(fileExplorerSettingsProvider.notifier);
    final terminalEnabled = ref.watch(isPluginEnabledProvider('terminal'));
    final themeCustomizerEnabled = ref.watch(isPluginEnabledProvider('theme_customizer'));
    // watch Prefs so the UI reacts to changes made elsewhere
    final prefs = ref.watch(prefsProvider);
  final pluginConfigs = ref.watch(pluginSettingsProvider).pluginConfigs;
  final terminalCfg = pluginConfigs['terminal'] ?? {};

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(12), children: [
          // const Text('Application Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Appearance / Theme
          const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final currentTheme = prefs.themeMode;
            return Column(children: [
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: currentTheme,
                onChanged: (v) async {
                  await Prefs().saveThemeMode('system');
                  // also update theme provider so app reacts immediately
                  final settingsNotifier = ref.read(themeSettingsProvider.notifier);
                  final settings = ref.read(themeSettingsProvider);
                  await settingsNotifier.updateSettings(settings.copyWith(themeMode: 'system'));
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentTheme,
                onChanged: (v) async {
                  await Prefs().saveThemeMode('light');
                  final settingsNotifier = ref.read(themeSettingsProvider.notifier);
                  final settings = ref.read(themeSettingsProvider);
                  await settingsNotifier.updateSettings(settings.copyWith(themeMode: 'light'));
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (v) async {
                  await Prefs().saveThemeMode('dark');
                  final settingsNotifier = ref.read(themeSettingsProvider.notifier);
                  final settings = ref.read(themeSettingsProvider);
                  await settingsNotifier.updateSettings(settings.copyWith(themeMode: 'dark'));
                },
              ),
              const SizedBox(height: 12),
            ]);
          }),

          // Language selection
          const SizedBox(height: 8),
          const Text('Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: prefs.locale == null ? 'System' : (prefs.locale?.countryCode != null ? '${prefs.locale!.languageCode}-${prefs.locale!.countryCode}' : prefs.locale!.languageCode),
            items: supportedLanguages.expand((m) => m.entries).map((entry) {
              final label = entry.key;
              final code = entry.value;
              return DropdownMenuItem(value: code == 'System' ? 'System' : code, child: Text(label));
            }).toList(),
            onChanged: (v) async {
              if (v == null) return;
              await Prefs().saveLocaleToPrefs(v);
            },
          ),
          const SizedBox(height: 12),

          // Theme Customizer (plugin)
          PluginSettingsPanel(
            title: 'Theme Customizer',
            visible: themeCustomizerEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Primary color'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Wrap(spacing: 8, children: [
                  ElevatedButton(onPressed: () async { await Prefs().savePrimaryColor(0xFF2196F3); ref.read(themeSettingsProvider.notifier).updateSettings(ref.read(themeSettingsProvider).copyWith(primaryColor: 0xFF2196F3)); }, child: const Text('Blue')),
                  ElevatedButton(onPressed: () async { await Prefs().savePrimaryColor(0xFFE91E63); ref.read(themeSettingsProvider.notifier).updateSettings(ref.read(themeSettingsProvider).copyWith(primaryColor: 0xFFE91E63)); }, child: const Text('Pink')),
                  ElevatedButton(onPressed: () async { await Prefs().savePrimaryColor(0xFF4CAF50); ref.read(themeSettingsProvider.notifier).updateSettings(ref.read(themeSettingsProvider).copyWith(primaryColor: 0xFF4CAF50)); }, child: const Text('Green')),
                ])),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Border radius')),
                Slider(value: prefs.borderRadius, min: 0, max: 32, divisions: 16, label: prefs.borderRadius.toStringAsFixed(0), onChanged: (v) async { await Prefs().saveBorderRadius(v); ref.read(themeSettingsProvider.notifier).updateSettings(ref.read(themeSettingsProvider).copyWith(borderRadius: v)); }),
              ]),
              Row(children: [
                const Expanded(child: Text('Reduce animations')),
                Switch(value: prefs.reduceAnimations, onChanged: (v) async { await Prefs().saveReduceAnimations(v); ref.read(themeSettingsProvider.notifier).updateSettings(ref.read(themeSettingsProvider).copyWith(reduceAnimations: v)); }),
              ]),
            ]),
          ),

          // Editor settings panel (visible only when editor plugin enabled)
          PluginSettingsPanel(
            title: 'Editor Settings',
            visible: editorEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tab size'),
              Slider(
                value: (editorCfg['tabSize'] ?? 2).toDouble(),
                min: 2,
                max: 8,
                divisions: 6,
                label: '${editorCfg['tabSize'] ?? 2}',
                onChanged: (v) => editorCtrl.setTabSize(v.toInt()),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Show line numbers'),
                const Spacer(),
                Checkbox(
                  value: (editorCfg['showLineNumbers'] ?? true) as bool,
                  onChanged: (v) => editorCtrl.setShowLineNumbers(v ?? true),
                ),
              ]),
            ]),
          ),

          // Git settings
          PluginSettingsPanel(
            title: 'Git Settings',
            visible: gitEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Auto-fetch')),
                Switch(value: (gitCfg['autoFetch'] ?? true) as bool, onChanged: (v) => gitCtrl.setAutoFetch(v)),
              ]),
              const SizedBox(height: 8),
              const Text('Default branch'),
              const SizedBox(height: 4),
              TextField(
                controller: TextEditingController(text: (gitCfg['defaultBranch'] ?? 'main') as String),
                decoration: const InputDecoration(hintText: 'main'),
                onSubmitted: (v) => gitCtrl.setDefaultBranch(v.trim()),
              ),
            ]),
          ),

          // AI settings
          PluginSettingsPanel(
            title: 'AI Settings',
            visible: aiEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Default model'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: (aiCfg['model'] ?? 'gpt') as String,
                items: const [DropdownMenuItem(value: 'gpt', child: Text('GPT'))],
                onChanged: (v) { if (v != null) aiCtrl.setModel(v); },
              ),
              const SizedBox(height: 8),
              const Text('Max tokens'),
              Slider(value: (aiCfg['maxTokens'] ?? 512).toDouble(), min: 64, max: 2048, divisions: 32, onChanged: (v) => aiCtrl.setMaxTokens(v.toInt())),
            ]),
          ),

          // Terminal settings
          PluginSettingsPanel(
            title: 'Terminal Settings',
            visible: terminalEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Shell executable'),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: (terminalCfg['shellPath'] ?? '/bin/bash') as String),
                decoration: const InputDecoration(hintText: '/bin/bash'),
                onSubmitted: (v) => ref.read(pluginSettingsProvider.notifier).updatePluginConfig('terminal', 'shellPath', v.trim()),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text('Font size')),
                Slider(value: (terminalCfg['fontSize'] ?? 14).toDouble(), min: 10, max: 24, divisions: 14, onChanged: (v) => ref.read(pluginSettingsProvider.notifier).updatePluginConfig('terminal', 'fontSize', v.toInt())),
              ]),
              Row(children: [
                const Expanded(child: Text('Audible bell')),
                Switch(value: (terminalCfg['bell'] ?? true) as bool, onChanged: (v) => ref.read(pluginSettingsProvider.notifier).updatePluginConfig('terminal', 'bell', v)),
              ]),
            ]),
          ),

          // File Explorer settings
          PluginSettingsPanel(
            title: 'File Explorer Settings',
            visible: fileExplorerEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Show hidden files')),
                Switch(value: (feCfg['showHidden'] ?? false) as bool, onChanged: (v) => feCtrl.setShowHidden(v)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text('Preview markdown files')),
                Switch(value: (feCfg['previewMarkdown'] ?? true) as bool, onChanged: (v) => feCtrl.setPreviewMarkdown(v)),
              ]),
            ]),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: () => ref.read(pluginSettingsProvider.notifier).resetToDefaults(), icon: const Icon(Icons.restore), label: const Text('Reset plugin settings to defaults')),
        ]),
      ),
    );
  }
}
