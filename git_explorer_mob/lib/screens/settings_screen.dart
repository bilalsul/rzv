import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
// Theme provider removed; theme is driven from Prefs
import 'package:git_explorer_mob/widgets/settings/plugin_settings_panel.dart';
import 'package:git_explorer_mob/enums/options/supported_language.dart';

/// SettingsScreen no longer contains plugin toggles (they live in AppDrawer).
/// This screen exposes plugin-specific settings panels and connects them
/// to plugin configuration stored through `pluginSettingsProvider`.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // single source: watch Prefs
    final prefs = ref.watch(prefsProvider);
    // plugin enabled flags read from prefs (prefs.notifyListeners will rebuild)
    final editorEnabled = prefs.isPluginEnabled('editor');
    final gitEnabled = prefs.isPluginEnabled('git_history');
    final aiEnabled = prefs.isPluginEnabled('ai_assist');
    final fileExplorerEnabled = prefs.isPluginEnabled('file_explorer');
    final terminalEnabled = prefs.isPluginEnabled('terminal');
    final themeCustomizerEnabled = prefs.isPluginEnabled('theme_customizer');
    
    // plugin configs read via Prefs.getPluginConfig(pluginName, key)
    final editorCfg = {
      'tabSize': prefs.getPluginConfig('editor', 'tabSize') ?? 2,
      'showLineNumbers': prefs.getPluginConfig('editor', 'showLineNumbers') ?? true,
    };
    final gitCfg = {
      'autoFetch': prefs.getPluginConfig('git', 'autoFetch') ?? true,
      'defaultBranch': prefs.getPluginConfig('git', 'defaultBranch') ?? 'main',
    };
    final aiCfg = {
      'model': prefs.getPluginConfig('ai', 'model') ?? 'gpt',
      'maxTokens': prefs.getPluginConfig('ai', 'maxTokens') ?? 512,
    };
    final feCfg = {
      'showHidden': prefs.getPluginConfig('file_explorer', 'showHidden') ?? false,
      'previewMarkdown': prefs.getPluginConfig('file_explorer', 'previewMarkdown') ?? true,
    };
    final terminalCfg = {
      'shellPath': prefs.getPluginConfig('terminal', 'shellPath') ?? '/bin/bash',
      'fontSize': prefs.getPluginConfig('terminal', 'fontSize') ?? 14,
      'bell': prefs.getPluginConfig('terminal', 'bell') ?? true,
    };
  

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
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentTheme,
                onChanged: (v) async { await Prefs().saveThemeMode('light'); },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (v) async { await Prefs().saveThemeMode('dark'); },
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
                  ElevatedButton(onPressed: () async { await Prefs().savePrimaryColor(0xFF2196F3); }, child: const Text('Blue')),
                  ElevatedButton(onPressed: () async { await Prefs().savePrimaryColor(0xFFE91E63); }, child: const Text('Pink')),
                  ElevatedButton(onPressed: () async { await Prefs().savePrimaryColor(0xFF4CAF50); }, child: const Text('Green')),
                ])),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Border radius')),
                Slider(value: prefs.borderRadius, min: 0, max: 32, divisions: 16, label: prefs.borderRadius.toStringAsFixed(0), onChanged: (v) async { await Prefs().saveBorderRadius(v); }),
              ]),
              Row(children: [
                const Expanded(child: Text('Reduce animations')),
                Switch(value: prefs.reduceAnimations, onChanged: (v) async { await Prefs().saveReduceAnimations(v); }),
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
                onChanged: (v) async => await prefs.setPluginConfig('editor', 'tabSize', v.toInt()),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Show line numbers'),
                const Spacer(),
                Checkbox(
                  value: (editorCfg['showLineNumbers'] ?? true) as bool,
                  onChanged: (v) async => await prefs.setPluginConfig('editor', 'showLineNumbers', v ?? true),
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
                Switch(value: (gitCfg['autoFetch'] ?? true) as bool, onChanged: (v) async => await prefs.setPluginConfig('git', 'autoFetch', v)),
              ]),
              const SizedBox(height: 8),
              const Text('Default branch'),
              const SizedBox(height: 4),
              TextField(
                controller: TextEditingController(text: (gitCfg['defaultBranch'] ?? 'main') as String),
                decoration: const InputDecoration(hintText: 'main'),
                onSubmitted: (v) async => await prefs.setPluginConfig('git', 'defaultBranch', v.trim()),
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
                onChanged: (v) async { if (v != null) await prefs.setPluginConfig('ai', 'model', v); },
              ),
              const SizedBox(height: 8),
              const Text('Max tokens'),
              Slider(value: (aiCfg['maxTokens'] ?? 512).toDouble(), min: 64, max: 2048, divisions: 32, onChanged: (v) async => await prefs.setPluginConfig('ai', 'maxTokens', v.toInt())),
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
                onSubmitted: (v) async => await prefs.setPluginConfig('terminal', 'shellPath', v.trim()),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text('Font size')),
                Slider(value: (terminalCfg['fontSize'] ?? 14).toDouble(), min: 10, max: 24, divisions: 14, onChanged: (v) async => await prefs.setPluginConfig('terminal', 'fontSize', v.toInt())),
              ]),
              Row(children: [
                const Expanded(child: Text('Audible bell')),
                Switch(value: (terminalCfg['bell'] ?? true) as bool, onChanged: (v) async => await prefs.setPluginConfig('terminal', 'bell', v)),
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
                Switch(value: (feCfg['showHidden'] ?? false) as bool, onChanged: (v) async => await prefs.setPluginConfig('file_explorer', 'showHidden', v)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text('Preview markdown files')),
                Switch(value: (feCfg['previewMarkdown'] ?? true) as bool, onChanged: (v) async => await prefs.setPluginConfig('file_explorer', 'previewMarkdown', v)),
              ]),
            ]),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              // Reset selected plugin flags and a few common configs to defaults via Prefs.
              await prefs.setPluginEnabled('editor', false);
              await prefs.setPluginEnabled('git_history', false);
              await prefs.setPluginEnabled('file_explorer', false);
              await prefs.setPluginEnabled('terminal', false);
              await prefs.setPluginEnabled('theme_customizer', false);
              await prefs.setPluginEnabled('ai_assist', false);
              // remove a few plugin config keys
              await prefs.setPluginConfig('editor', 'tabSize', null);
              await prefs.setPluginConfig('editor', 'showLineNumbers', null);
              await prefs.setPluginConfig('git', 'autoFetch', null);
              await prefs.setPluginConfig('git', 'defaultBranch', null);
              await prefs.setPluginConfig('file_explorer', 'showHidden', null);
              await prefs.setPluginConfig('file_explorer', 'previewMarkdown', null);
              await prefs.setPluginConfig('ai', 'model', null);
              await prefs.setPluginConfig('ai', 'maxTokens', null);
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset plugin settings to defaults'),
          ),
        ]),
      ),
    );
  }
}
