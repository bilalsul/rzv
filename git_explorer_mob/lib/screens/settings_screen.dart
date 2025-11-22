import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
// Theme provider removed; theme is driven from Prefs
import 'package:git_explorer_mob/widgets/settings/plugin_settings_panel.dart';
import 'package:git_explorer_mob/enums/options/supported_language.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';

/// SettingsScreen no longer contains plugin toggles (they live in AppDrawer).
/// This screen exposes plugin-specific settings panels and connects them
/// to plugin configuration stored through `pluginSettingsProvider`.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Temporary theme customizer state (apply button will persist)
  late Color _tempPrimaryColor;
  late Color _tempSecondaryColor;
  late double _tempBorderRadius;
  late double _tempElevation;
  late double _tempAppFontSize;
  late String _tempButtonStyle;

  // AI temporary state before apply
  String _selectedAiProvider = 'gpt';
  String _selectedAiModel = 'gpt-4o';
  int _selectedAiMaxTokens = 512;
  @override
  Widget build(BuildContext context) {
    // single source: watch Prefs
    final prefs = ref.watch(prefsProvider);
  // Temporary theme values are initialized in initState from Prefs.
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
    // AI config is read into local state in initState(); persisted values
    // are accessed via Prefs when Apply is pressed.
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
          Text(L10n.of(context).settingsAppearance, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final currentTheme = prefs.themeMode;
            return Column(children: [
                  RadioListTile<ThemeMode>(
                title: Text(L10n.of(context).settingsSystemMode),
                value: ThemeMode.system,
                groupValue: currentTheme,
                onChanged: (v) async {
                      await Prefs().saveThemeMode('system');
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(L10n.of(context).settingsLightMode),
                value: ThemeMode.light,
                groupValue: currentTheme,
                onChanged: (v) async { await Prefs().saveThemeMode('light'); },
              ),
              RadioListTile<ThemeMode>(
                title: Text(L10n.of(context).settingsDarkMode),
                value: ThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (v) async { await Prefs().saveThemeMode('dark'); },
              ),
              const SizedBox(height: 12),
            ]);
          }),

          // Language selection
          const SizedBox(height: 8),
          Text(L10n.of(context).settingsAppearanceLanguage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // current stored locale code or 'System'
            value: prefs.locale == null ? 'System' : (prefs.locale?.countryCode != null ? '${prefs.locale!.languageCode}-${prefs.locale!.countryCode}' : prefs.locale!.languageCode),
            items: supportedLanguages.map((m) {
              final entry = m.entries.first;
              final label = entry.key;
              final code = entry.value;
              final displayLabel = label[0].toUpperCase() + label.substring(1);
              return DropdownMenuItem<String>(value: code == 'System' ? 'System' : code, child: Text(displayLabel));
            }).toList(),
            onChanged: (selectedCode) async {
              if (selectedCode == null) return;
              // Persist the language code (e.g., 'en', 'zh-CN' or 'System') to prefs
              await Prefs().saveLocaleToPrefs(selectedCode);
            },
          ),
          const SizedBox(height: 12),

          // Theme Customizer (plugin)
          PluginSettingsPanel(
            title: L10n.of(context).settingsAppearanceTheme,
            visible: themeCustomizerEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L10n.of(context).settingsAppearancePrimaryColor),
              const SizedBox(height: 8),
              // clickable color circle palette
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Colors.primaries.take(18).map((c) {
                  final col = c.shade600;
                  final selected = _tempPrimaryColor == col;
                  return GestureDetector(
                    onTap: () => setState(() { _tempPrimaryColor = col; }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black87, width: 2) : null,
                      ),
                      child: CircleAvatar(backgroundColor: col, radius: 18),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(L10n.of(context).settingsAppearanceAccentColor),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Colors.primaries.reversed.take(18).map((c) {
                  final col = c.shade400;
                  final selected = _tempSecondaryColor == col;
                  return GestureDetector(
                    onTap: () => setState(() { _tempSecondaryColor = col; }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black87, width: 2) : null,
                      ),
                      child: CircleAvatar(backgroundColor: col, radius: 14),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton(
                  onPressed: () async {
                    await Prefs().savePrimaryColor(_tempPrimaryColor);
                    await Prefs().saveSecondaryColor(_tempSecondaryColor);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).settingsThemeApplied)));
                  },
                  child: Text(L10n.of(context).settingsApplyThemeColors),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() {
                    // revert temps from prefs
                    final p = Prefs();
                    _tempPrimaryColor = p.primaryColor;
                    _tempSecondaryColor = p.secondaryColor;
                  }),
                  child: Text(L10n.of(context).settingsRevertThemeColors),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsBorderRadius)),
                Expanded(
                  child: Slider(
                    value: _tempBorderRadius,
                    min: 0,
                    max: 32,
                    divisions: 16,
                    label: _tempBorderRadius.toStringAsFixed(0),
                    onChanged: (v) => setState(() { _tempBorderRadius = v; }),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsElevation)),
                Expanded(
                  child: Slider(value: _tempElevation, min: 0, max: 12, divisions: 12, label: _tempElevation.toStringAsFixed(0), onChanged: (v) => setState(() { _tempElevation = v; })),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsAppFontSize)),
                Expanded(child: Slider(value: _tempAppFontSize, min: 10, max: 22, divisions: 12, label: _tempAppFontSize.toStringAsFixed(0), onChanged: (v) => setState(() { _tempAppFontSize = v; }))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsButtonStyle)),
                DropdownButton<String>(
                  value: _tempButtonStyle,
                  items: ['elevated', 'outlined', 'text'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() { if (v != null) _tempButtonStyle = v; }),
                ),
              ]),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsReduceAnimations)),
                Switch(value: prefs.reduceAnimations, onChanged: (v) async { await Prefs().saveReduceAnimations(v); }),
              ]),
            ]),
          ),

          // Editor settings panel (visible only when editor plugin enabled)
          PluginSettingsPanel(
            title: L10n.of(context).settingsEditorSettings,
            visible: editorEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L10n.of(context).settingsEditorTabSize),
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
                Text(L10n.of(context).settingsEditorShowLineNumbers),
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
            title: L10n.of(context).settingsGitSettings,
            visible: gitEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsGitAutoFetch)),
                Switch(value: (gitCfg['autoFetch'] ?? true) as bool, onChanged: (v) async => await prefs.setPluginConfig('git', 'autoFetch', v)),
              ]),
              const SizedBox(height: 8),
              Text(L10n.of(context).settingsGitDefaultBranch),
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
            title: L10n.of(context).settingsAiSettings,
            visible: aiEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L10n.of(context).settingsAiModelProvider),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _providerTile('gpt', label: 'OpenAI', assetName: 'openai.png'),
                _providerTile('claude', label: 'Anthropic', assetName: 'claude.png'),
                _providerTile('grok', label: 'Grok', assetName: 'deepseek.png'),
                _providerTile('gemini', label: 'Gemini', assetName: 'gemini.png'),
                _providerTile('commonai', label: 'Common', assetName: 'commonAi.png'),
                _providerTile('openrouter', label: 'OpenRouter', assetName: 'openrouter.png'),
                _providerTile('xiaohongshu', label: 'Xiaohongshu', assetName: 'xiaohongshu.png'),
              ]),
              const SizedBox(height: 12),
              Text(L10n.of(context).settingsAiMaxTokens),
              Slider(
                value: _selectedAiMaxTokens.toDouble(),
                min: 64,
                max: 2048,
                divisions: 32,
                label: '$_selectedAiMaxTokens',
                onChanged: (v) => setState(() { _selectedAiMaxTokens = v.toInt(); }),
              ),

              const SizedBox(height: 12),
              // Per-provider configuration: Configure API URL and secure API key per provider using the "Configure" button on each provider tile.

              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(
                  onPressed: () async {
                    // Persist provider/model/maxTokens
                    await prefs.setPluginConfig('ai', 'provider', _selectedAiProvider);
                    await prefs.setPluginConfig('ai', 'model', _selectedAiModel);
                    await prefs.setPluginConfig('ai', 'maxTokens', _selectedAiMaxTokens);
                    setState(() {});
                    final ok = await _checkApiKey(_selectedAiProvider);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? L10n.of(context).connectionSuccessful : L10n.of(context).connectionFailed)));
                  },
                  child: Text(L10n.of(context).settingsApplyAiSettings),
                ),
              ]),
            ]),
          ),

          // Terminal settings
          PluginSettingsPanel(
            title: L10n.of(context).settingsTerminalSettings,
            visible: terminalEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L10n.of(context).settingsTerminalShellExecutable),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: (terminalCfg['shellPath'] ?? '/bin/bash') as String),
                decoration: const InputDecoration(hintText: '/bin/bash'),
                onSubmitted: (v) async => await prefs.setPluginConfig('terminal', 'shellPath', v.trim()),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsTerminalFontSize)),
                Slider(value: (terminalCfg['fontSize'] ?? 14).toDouble(), min: 10, max: 24, divisions: 14, onChanged: (v) async => await prefs.setPluginConfig('terminal', 'fontSize', v.toInt())),
              ]),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsTerminalAudibleBell)),
                Switch(value: (terminalCfg['bell'] ?? true) as bool, onChanged: (v) async => await prefs.setPluginConfig('terminal', 'bell', v)),
              ]),
            ]),
          ),

          // File Explorer settings
          PluginSettingsPanel(
            title: L10n.of(context).settingsFileExplorerSettings,
            visible: fileExplorerEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsFileExplorerShowHidden)),
                Switch(value: (feCfg['showHidden'] ?? false) as bool, onChanged: (v) async => await prefs.setPluginConfig('file_explorer', 'showHidden', v)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsFileExplorerPreviewMarkdown)),
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
            label: Text(L10n.of(context).settingsResetPluginDefaults),
          ),
        ]),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    // Read current persisted values from Prefs singleton into temporary state
    final p = Prefs();
    _tempPrimaryColor = p.primaryColor;
    _tempSecondaryColor = p.secondaryColor;
    _tempBorderRadius = p.borderRadius;
    _tempElevation = p.elevationLevel;
    _tempAppFontSize = p.appFontSize;
    _tempButtonStyle = p.buttonStyle;

    // AI defaults
    _selectedAiProvider = p.getPluginConfig('ai', 'provider') ?? 'gpt';
    _selectedAiModel = p.getPluginConfig('ai', 'model') ?? 'gpt-4o';
    _selectedAiMaxTokens = p.getPluginConfig('ai', 'maxTokens') ?? 512;
  }

  Widget _providerTile(String id, {required String label, required String assetName}) {
    final selected = _selectedAiProvider == id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedAiProvider = id;
              // set a reasonable default model per provider
              if (id == 'gpt') _selectedAiModel = 'gpt-4o';
              else if (id == 'claude') _selectedAiModel = 'claude-2';
              else if (id == 'grok') _selectedAiModel = 'grok-1';
              else if (id == 'gemini') _selectedAiModel = 'gemini-1';
              else _selectedAiModel = 'gpt-4o';
            });
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: selected ? Colors.blue.shade100 : Colors.grey.shade200,
            child: ClipOval(
              child: Image.asset('assets/images/ai/$assetName', width: 36, height: 36, errorBuilder: (c, e, st) => const Icon(Icons.cloud, size: 28)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        const SizedBox(height: 6),
        SizedBox(
          width: 84,
          child: OutlinedButton(
            onPressed: () => _showProviderConfigDialog(context, id, label),
            child: const Text('Configure', style: TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
  }

  void _showProviderConfigDialog(BuildContext context, String providerId, String label) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          // fetch api url (shared prefs) and api key (secure storage) concurrently
          future: Future.wait([Prefs().getPluginConfig('ai', '${providerId}_api_url'), Prefs().getPluginApiKey('ai_${providerId}')]),
          builder: (context, snapshot) {
            final existingUrl = snapshot.hasData ? snapshot.data![0] as String? : null;
            final existingKey = snapshot.hasData ? snapshot.data![1] as String? : null;
            final urlController = TextEditingController(text: existingUrl ?? '');
            final keyController = TextEditingController(text: existingKey ?? '');
            return AlertDialog(
              title: Text('Configure $label'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(labelText: 'API URL (optional)'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(labelText: 'API Key'),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(L10n.of(context).commonCancel)),
                FilledButton(
                  onPressed: () async {
                    final url = urlController.text.trim();
                    final key = keyController.text.trim();
                    // save url in plugin config (non-sensitive) and key in secure storage per-provider
                    if (url.isNotEmpty) await Prefs().setPluginConfig('ai', '${providerId}_api_url', url);
                    else await Prefs().setPluginConfig('ai', '${providerId}_api_url', null);
                    if (key.isNotEmpty) await Prefs().setPluginApiKey('ai_${providerId}', key);
                    else await Prefs().removePluginApiKey('ai_${providerId}');
                    Navigator.of(context).pop();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label settings saved')));
                  },
                  child: Text(L10n.of(context).commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _checkApiKey(String providerId) async {
    // Basic provider-specific connectivity check. This is intentionally lightweight
    // and does not exhaustively validate all provider API semantics.
    final key = await Prefs().getPluginApiKey('ai_${providerId}');
    if (key == null || key.isEmpty) return false;
    final configuredUrl = Prefs().getPluginConfig('ai', '${providerId}_api_url') as String?;
    try {
      if (providerId == 'gpt') {
        // OpenAI: try listing models (allow custom URL if configured)
        final url = configuredUrl?.isNotEmpty == true ? configuredUrl! : 'https://api.openai.com/v1/models';
        final resp = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $key'},
        ).timeout(const Duration(seconds: 6));
        return resp.statusCode == 200;
      } else if (providerId == 'claude') {
        // Anthropic: try listing models endpoint (allow custom URL)
        final url = configuredUrl?.isNotEmpty == true ? configuredUrl! : 'https://api.anthropic.com/v1/models';
        final resp = await http.get(
          Uri.parse(url),
          headers: {'x-api-key': key},
        ).timeout(const Duration(seconds: 6));
        return resp.statusCode == 200;
      } else {
        // For other providers (grok/gemini) we do a simple non-network check: key presence
        return key.isNotEmpty;
      }
    } catch (e) {
      return false;
    }
  }
  
}
