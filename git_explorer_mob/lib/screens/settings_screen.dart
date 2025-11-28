import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/enums/options/font_family.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  // AdMob native ad
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;
  // Temporary theme customizer state (apply button will persist)
  // late Color _tempPrimaryColor;
  late Color _tempSecondaryColor;
  late Color _tempAccentColor;
  // other temporary theme values (removed UI for now)
  // AI temporary state before apply
  int _selectedAiMaxTokens = 512;
  // Temporary storage for provider configurations before Apply
  final Map<String, String> _tempApiUrls = {}; // key: '<provider>_<model>' -> url
  final Map<String, String> _tempApiKeys = {}; // key: 'ai_<provider>_<model>' -> apiKey (empty = remove)
  final Map<String, String> _tempLastModel = {}; // provider -> model
  String? _tempActiveProvider;
  String? _tempActiveModel;
  @override
  Widget build(BuildContext context) {
    // single source: watch Prefs
    final prefs = ref.watch(prefsProvider);
  // Temporary theme values are initialized in initState from Prefs.
    // plugin enabled flags read from prefs (prefs.notifyListeners will rebuild)
    final fileExplorerEnabled = prefs.isPluginEnabled('file_explorer');
    final themeCustomizerEnabled = prefs.isPluginEnabled('theme_customizer');
    final aiEnabled = prefs.isPluginEnabled('ai_assist');
    // final gitEnabled = prefs.isPluginEnabled('git_history');
    // final terminalEnabled = prefs.isPluginEnabled('terminal');
    
    // plugin configs read via Prefs.getPluginConfig(pluginName, key)
    // final editorCfg = {
    //   'tabSize': prefs.getPluginConfig('editor', 'tabSize') ?? 2,
    //   'showLineNumbers': prefs.getPluginConfig('editor', 'showLineNumbers') ?? true,
    // };
    // final gitCfg = {
    //   'autoFetch': prefs.getPluginConfig('git', 'autoFetch') ?? true,
    //   'defaultBranch': prefs.getPluginConfig('git', 'defaultBranch') ?? 'main',
    // };
    // AI config is read into local state in initState(); persisted values
    // are accessed via Prefs when Apply is pressed.
    // final feCfg = {
    //   'show_hidden': prefs.getPluginConfig('file_explorer', 'show_hidden') ?? false,
    //   'previewMarkdown': prefs.getPluginConfig('file_explorer', 'previewMarkdown') ?? true,
    // };
    // final terminalCfg = {
    //   'shellPath': prefs.getPluginConfig('terminal', 'shellPath') ?? '/bin/bash',
    //   'fontSize': prefs.getPluginConfig('terminal', 'fontSize') ?? 14,
    //   'bell': prefs.getPluginConfig('terminal', 'bell') ?? true,
    // };
  

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
                activeColor: prefs.accentColor,
                groupValue: currentTheme,
                onChanged: (v) async {
                      await Prefs().saveThemeMode('system');
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(L10n.of(context).settingsLightMode),
                value: ThemeMode.light,
                activeColor: prefs.accentColor,
                groupValue: currentTheme,
                onChanged: (v) async { await Prefs().saveThemeMode('light'); },
              ),
              RadioListTile<ThemeMode>(
                title: Text(L10n.of(context).settingsDarkMode),
                value: ThemeMode.dark,
                activeColor: prefs.accentColor,
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
          prefs.featureSupported("theme_customizer") ?
          PluginSettingsPanel(
            title: L10n.of(context).settingsAppearanceTheme,
            visible: themeCustomizerEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Text(L10n.of(context).settingsAppearancePrimaryColor),
              // const SizedBox(height: 8),
              // // clickable color circle palette
              // Wrap(
              //   spacing: 8,
              //   runSpacing: 8,
              //   children: Colors.primaries.take(18).map((c) {
              //     // final col = c.shade700;
              //     final col = c;
              //     final selected = _tempPrimaryColor == col;
              //     return GestureDetector(
              //       onTap: () => setState(() { _tempPrimaryColor = col; }),
              //       child: Container(
              //         padding: const EdgeInsets.all(4),
              //         decoration: BoxDecoration(
              //           shape: BoxShape.circle,
              //           border: selected ? Border.all(color: Colors.black87, width: 2) : null,
              //         ),
              //         child: CircleAvatar(backgroundColor: col, radius: 18),
              //       ),
              //     );
              //   }).toList(),
              // ),
              const SizedBox(height: 10),
              Text(L10n.of(context).settingsAppearanceSecondaryColor),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: Colors.primaries.take(18).map((c) {
                  // final col = c.shade400;
                  final col = c;
                  final selected = _tempSecondaryColor == col;
                  return GestureDetector(
                    onTap: () => setState(() { _tempSecondaryColor = col; }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: prefs.secondaryColor, width: 2) : null,
                      ),
                      child: CircleAvatar(backgroundColor: col, radius: 14),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(L10n.of(context).settingsAppearanceAccentColor),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Colors.accents.take(16).map((c) {
                  // final col = c.shade400;
                  final col = c;
                  final selected = _tempAccentColor == col;
                  return GestureDetector(
                    onTap: () => setState(() { _tempAccentColor = col; }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color:prefs.accentColor, width: 2) : null,
                      ),
                      child: CircleAvatar(backgroundColor: col, radius: 14),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              Row(children: [
                ElevatedButton(
                  onPressed: () async {
                    // await Prefs().savePrimaryColor(_tempPrimaryColor);
                    await Prefs().saveSecondaryColor(_tempSecondaryColor);
                    await Prefs().saveAccentColor(_tempAccentColor);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).settingsThemeApplied)));
                  },
                  child: Text(L10n.of(context).commonApply, style: TextStyle(color: prefs.accentColor)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() {
                    // revert temps from prefs
                    final p = Prefs();
                    // _tempPrimaryColor = p.primaryColor;
                    _tempSecondaryColor = p.secondaryColor;
                    _tempAccentColor = p.accentColor;
                  }),
                  child: Text(L10n.of(context).settingsRevertThemeColors, style: TextStyle(color: prefs.accentColor)),
                ),
                ElevatedButton(
                  onPressed: () => setState(() {
                    // reset theme customizer colors from prefs
                    Prefs().resetThemeCustomizerColors();
                  }),
                  child: Text(L10n.of(context).commonReset, style: TextStyle(color: prefs.accentColor)),
                ),
              ]),
              const SizedBox(height: 12),
              // Row(children: [
              //   Expanded(child: Text(L10n.of(context).settingsBorderRadius)),
              //   Expanded(
              //     child: Slider(
              //       value: _tempBorderRadius,
              //       min: 0,
              //       max: 32,
              //       divisions: 16,
              //       label: _tempBorderRadius.toStringAsFixed(0),
              //       onChanged: (v) => setState(() { _tempBorderRadius = v; }),
              //     ),
              //   ),
              // ]),
              // const SizedBox(height: 8),
              // Row(children: [
              //   Expanded(child: Text(L10n.of(context).settingsElevation)),
              //   Expanded(
              //     child: Slider(value: _tempElevation, min: 0, max: 12, divisions: 12, label: _tempElevation.toStringAsFixed(0), onChanged: (v) => setState(() { _tempElevation = v; })),
              //   ),
              // ]),
              // const SizedBox(height: 8),
              // Row(children: [
              //   Expanded(child: Text(L10n.of(context).settingsAppFontSize)),
              //   Expanded(child: Slider(value: _tempAppFontSize, min: 10, max: 22, divisions: 12, label: _tempAppFontSize.toStringAsFixed(0), onChanged: (v) => setState(() { _tempAppFontSize = v; }))),
              // ]),
              // const SizedBox(height: 8),
              // Row(children: [
              //   Expanded(child: Text(L10n.of(context).settingsButtonStyle)),
              //   DropdownButton<String>(
              //     value: _tempButtonStyle,
              //     items: ['elevated', 'outlined', 'text'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              //     onChanged: (v) => setState(() { if (v != null) _tempButtonStyle = v; }),
              //   ),
              // ]),
              // Row(children: [
              //   Expanded(child: Text(L10n.of(context).settingsReduceAnimations)),
              //   Switch(value: prefs.reduceAnimations, onChanged: (v) async { await Prefs().saveReduceAnimations(v); }),
              // ]),
            ]),
          ) : SizedBox.shrink(),

          // Editor settings panel (visible only when editor plugin enabled)
          prefs.isPluginEnabled("advanced_editor_options") ?
          PluginSettingsPanel(
            title: L10n.of(context).settingsEditorSettings,
            visible: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Text(L10n.of(context).settingsEditorTabSize),
              // Slider(
              //   activeColor: prefs.accentColor,
              //   value: (editorCfg['tabSize'] ?? 2).toDouble(),
              //   min: 2,
              //   max: 8,
              //   divisions: 6,
              //   label: '${editorCfg['tabSize'] ?? 2}',
              //   onChanged: (v) async => await prefs.setPluginConfig('editor', 'tabSize', v.toInt()),
              // ),
              const SizedBox(height: 8),
              Text(L10n.of(context).settingsEditorFontFamily, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                // current stored locale code or 'System'
                value: prefs.editorFontFamily,
                items: fontFamily.map((m) {
                  final entry = m.entries.first;
                  // final code = entry.key;
                  final label = entry.value;
                  final displayLabel = label[0].toUpperCase() + label.substring(1);
                  return DropdownMenuItem<String>(value: label, child: Text(displayLabel));
                }).toList(),
                onChanged: (selectedFont) async {
                  if (selectedFont == null) return;
                  // Persist the font family to prefs
                  await Prefs().saveEditorFontFamily(selectedFont);
                },
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              Text(L10n.of(context).settingsEditorFontSize),
              Slider(
                activeColor: prefs.accentColor,
                value: prefs.editorFontSize,
                min: 8,
                max: 40,
                divisions: 16,
                label: prefs.editorFontSize.toString(),
                onChanged: (v) async => await prefs.saveEditorFontSize(v),
              ),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsEditorZoomInOut)),
                Switch.adaptive(value: prefs.editorZoomInOut, 
                onChanged: (v) async => await prefs.saveEditorZoomInOut(v),
                activeColor: prefs.secondaryColor,
                )]),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsEditorShowLineNumbers)),
                Switch.adaptive(value: prefs.editorLineNumbers, 
                onChanged: (v) async => await prefs.saveEditorLineNumbers(v),
                activeColor: prefs.secondaryColor,
                )]),
            ]),
          ) : SizedBox.shrink() ,

          // Git settings
          // prefs.featureSupported("git_history") ?
          // PluginSettingsPanel(
          //   title: L10n.of(context).settingsGitSettings,
          //   visible: gitEnabled,
          //   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //     Row(children: [
          //       Expanded(child: Text(L10n.of(context).settingsGitAutoFetch)),
          //       Switch(value: (gitCfg['autoFetch'] ?? true) as bool, onChanged: (v) async => await prefs.setPluginConfig('git', 'autoFetch', v), activeColor: prefs.secondaryColor),
          //     ]),
          //     const SizedBox(height: 8),
          //     Text(L10n.of(context).settingsGitDefaultBranch),
          //     const SizedBox(height: 4),
          //     TextField(
          //       controller: TextEditingController(text: (gitCfg['defaultBranch'] ?? 'main') as String),
          //       decoration: const InputDecoration(hintText: 'main'),
          //       onSubmitted: (v) async => await prefs.setPluginConfig('git', 'defaultBranch', v.trim()),
          //     ),
          //   ]),
          // ) : SizedBox.shrink(),

          // AI settings
          prefs.featureSupported("ai") ?
          PluginSettingsPanel(
            title: L10n.of(context).settingsAiSettings,
            visible: aiEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L10n.of(context).settingsAiModelProvider),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                _providerTile(context, 'gpt', label: 'OpenAI', assetName: 'openai.png'),
                _providerTile(context, 'claude', label: 'Anthropic', assetName: 'claude.png'),
                _providerTile(context, 'grok', label: 'Grok', assetName: 'deepseek.png'),
                _providerTile(context, 'gemini', label: 'Gemini', assetName: 'gemini.png'),
                // _providerTile(context, 'commonai', label: 'Common', assetName: 'commonAi.png'),
                _providerTile(context, 'openrouter', label: 'OpenRouter', assetName: 'openrouter.png'),
                _providerTile(context, 'xiaohongshu', label: 'Xiaohongshu', assetName: 'xiaohongshu.png'),
              ]),
              const SizedBox(height: 12),
              Text(L10n.of(context).settingsAiMaxTokens),
              Slider(
                activeColor: prefs.accentColor,
                value: _selectedAiMaxTokens.toDouble(),
                min: 64,
                max: 9999,
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
                    // Persist any temporary API URLs
                    for (final entry in _tempApiUrls.entries) {
                      final full = entry.key; // '<provider>_<model>'
                      final idx = full.indexOf('_');
                      if (idx <= 0) continue;
                      final provider = full.substring(0, idx);
                      final model = full.substring(idx + 1);
                      final urlConfigKey = '${provider}_${model}_api_url';
                      await prefs.setPluginConfig('ai', urlConfigKey, entry.value);
                      await prefs.setPluginConfig('ai', '${provider}_last_model', model);
                    }
                    // Persist any temporary API keys (secure)
                    for (final entry in _tempApiKeys.entries) {
                      final pluginId = entry.key; // 'ai_<provider>_<model>'
                      final key = entry.value;
                      if (key.isNotEmpty) {
                        await prefs.setPluginApiKey(pluginId, key);
                      } else {
                        await prefs.removePluginApiKey(pluginId);
                      }
                    }
                    // Persist active provider/model if the user configured one
                    if (_tempActiveProvider != null) {
                      await prefs.setPluginConfig('ai', 'provider', _tempActiveProvider);
                      if (_tempActiveModel != null) await prefs.setPluginConfig('ai', 'model', _tempActiveModel);
                    }
                    // Persist max tokens
                    await prefs.setPluginConfig('ai', 'maxTokens', _selectedAiMaxTokens);
                    setState(() {});
                    final activeProvider = (prefs.getPluginConfig('ai', 'provider') as String?) ?? _tempActiveProvider ?? '';
                    final ok = activeProvider != '' ? await _checkApiKey(activeProvider) : false;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? L10n.of(context).connectionSuccessful : L10n.of(context).connectionFailed)));
                  },
                  child: Text(L10n.of(context).commonApply, style: TextStyle(color: prefs.accentColor)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(L10n.of(context).settingsResetAiSettings),
                        content: Text(L10n.of(context).settingsResetAiConfirm),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(L10n.of(context).commonCancel, style: TextStyle(color: prefs.secondaryColor))),
                          FilledButton(onPressed: () => Navigator.of(context).pop(true),
                          style: ButtonStyle(backgroundColor: WidgetStateProperty.all(prefs.secondaryColor)),
                          child: Text(L10n.of(context).commonDelete),
                           ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    // Delete AI-related SharedPreferences keys and secure API keys
                    final sp = prefs.prefs;
                    // collect secure key flags first (plugin_<pluginId>_has_api_key)
                    final hasFlags = sp.getKeys().where((k) => k.startsWith('plugin_') && k.contains('plugin_ai_') && k.endsWith('_has_api_key')).toList();
                    for (final flag in hasFlags) {
                      final pluginId = flag.substring('plugin_'.length, flag.length - '_has_api_key'.length);
                      // this will remove secure storage key and the 'has' flag, and notify
                      await prefs.removePluginApiKey(pluginId);
                    }
                    // remove any remaining plugin_ai_ keys via setPluginConfig so Prefs notifies
                    final aiKeys = sp.getKeys().where((k) => k.startsWith('plugin_ai_')).toList();
                    for (final k in aiKeys) {
                      final configKey = k.substring('plugin_ai_'.length);
                      await prefs.setPluginConfig('ai', configKey, null);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).settingsAiSettingsReset)));
                  },
                  child: Text(L10n.of(context).commonReset, style: TextStyle(color: prefs.accentColor)),
                ),
              ]),
            ]),
          ) : SizedBox.shrink(),

          // Terminal settings
          // prefs.featureSupported("terminal") ?
          // PluginSettingsPanel(
          //   title: L10n.of(context).settingsTerminalSettings,
          //   visible: terminalEnabled,
          //   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //     Text(L10n.of(context).settingsTerminalShellExecutable),
          //     const SizedBox(height: 8),
          //     TextField(
          //       controller: TextEditingController(text: (terminalCfg['shellPath'] ?? '/bin/bash') as String),
          //       decoration: const InputDecoration(hintText: '/bin/bash'),
          //       onSubmitted: (v) async => await prefs.setPluginConfig('terminal', 'shellPath', v.trim()),
          //     ),
          //     const SizedBox(height: 8),
          //     Row(children: [
          //       Expanded(child: Text(L10n.of(context).settingsTerminalFontSize)),
          //       Slider(value: (terminalCfg['fontSize'] ?? 14).toDouble(), min: 10, max: 24, divisions: 14, onChanged: (v) async => await prefs.setPluginConfig('terminal', 'fontSize', v.toInt()),
          //       activeColor: prefs.accentColor,
          //       ),
          //     ]),
          //     Row(children: [
          //       Expanded(child: Text(L10n.of(context).settingsTerminalAudibleBell)),
          //       Switch(value: (terminalCfg['bell'] ?? true) as bool, onChanged: (v) async => await prefs.setPluginConfig('terminal', 'bell', v), activeColor: prefs.secondaryColor),
          //     ]),
          //   ]),
          // ) : SizedBox.shrink(),

          // File Explorer settings
          prefs.featureSupported("file_explorer") ?
          PluginSettingsPanel(
            title: L10n.of(context).settingsFileExplorerSettings,
            visible: fileExplorerEnabled,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Row(children: [
              //   Expanded(child: Text(L10n.of(context).settingsFileExplorerShowHidden)),
              //   Switch(value: (feCfg['show_hidden'] ?? false) as bool, onChanged: (v) async => await prefs.setPluginConfig('file_explorer', 'show_hidden', v), activeColor: prefs.secondaryColor),
              // ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(L10n.of(context).settingsFileExplorerPreviewMarkdown)),
                Switch.adaptive(value: prefs.isPluginOptionEnabled('preview_markdown'), 
                onChanged: (v) async => await prefs.setPluginOptionEnabled('preview_markdown', v), 
                activeColor: prefs.secondaryColor,
                )]),
            ]),
          ) : SizedBox.shrink() ,

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              // Reset selected plugin flags and a few common configs to defaults via Prefs.
              // await prefs.setPluginEnabled('editor', false);
              await prefs.setPluginEnabled('file_explorer', false);
              await prefs.setPluginEnabled('theme_customizer', false);
              await prefs.setPluginEnabled('ai_assist', false);
              await prefs.setPluginEnabled('git_history', false);
              await prefs.setPluginEnabled('terminal', false);
              // remove a few plugin config keys
              // await prefs.setPluginConfig('editor', 'tabSize', null);
              // await prefs.setPluginConfig('editor', 'showLineNumbers', null);
              // await prefs.setPluginConfig('git', 'autoFetch', null);
              // await prefs.setPluginConfig('git', 'defaultBranch', null);
              // await prefs.setPluginConfig('file_explorer', 'show_hidden', null);
              // await prefs.setPluginConfig('file_explorer', 'preview_markdown', null);
              // await prefs.setPluginConfig('ai', 'model', null);
              // await prefs.setPluginConfig('ai', 'maxTokens', null);
              prefs.resetThemeCustomizerColors();
            },
            icon: Icon(Icons.restore, color: prefs.accentColor),
            label: Text(L10n.of(context).settingsResetPluginDefaults, style: TextStyle(color: prefs.accentColor)),
          ),
          const SizedBox(height: 12),
          // ad here
          _isNativeAdLoaded && _nativeAd != null
              ? SizedBox(
                  height: 250,
                  child: AdWidget(ad: _nativeAd!),
                )
              : const SizedBox.shrink(),
        ]),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    // make sure initialized Mobile Ads in main then load native ad for this screen
    _loadNativeAd();
    // Read current persisted values from Prefs singleton into temporary state
    final p = Prefs();
    // _tempPrimaryColor = p.primaryColor;
    _tempSecondaryColor = p.secondaryColor;
    _tempAccentColor = p.accentColor;

    // AI defaults
    _selectedAiMaxTokens = p.getPluginConfig('ai', 'maxTokens') ?? 512;
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

  Widget _providerTile(BuildContext context, String id, {required String label, required String assetName}) {
    final prefs =  ref.watch(prefsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Image.asset('assets/images/ai/$assetName', width: 36, height: 36, errorBuilder: (c, e, st) => const Icon(Icons.cloud, size: 28)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          width: 110,
          height: 20,
          child: OutlinedButton(
            onPressed: () => _showProviderConfigDialog(context, id, label),
            child: Text(L10n.of(context).settingsConfigure, style: TextStyle(fontSize: 9, color: prefs.secondaryColor)),
          ),
        ),
      ],
    );
  }

  void _showProviderConfigDialog(BuildContext context, String providerId, String label) {
    final prefs = ref.watch(prefsProvider);
    // Simple synchronous dialog: initialize fields synchronously from Prefs (no futures)
    // Models per provider
    final Map<String, List<String>> providerModels = {
      'gpt': ['gpt-4o', 'gpt-4o-mini', 'gpt-4', 'gpt-3.5-turbo'],
      'claude': ['claude-2', 'claude-instant'],
      'grok': ['grok-1'],
      'gemini': ['gemini-1'],
      // 'commonai': ['common-v1'],
      'openrouter': ['openrouter-default'],
      'xiaohongshu': ['xiaohongshu-v1'],
    };
    final models = providerModels[providerId] ?? ['default'];
    final lastModel = Prefs().getPluginConfig('ai', '${providerId}_last_model') as String?;
    String selectedModel = lastModel ?? (Prefs().getPluginConfig('ai', 'model') as String?) ?? models.first;
    // Load any previously entered temp values or persisted ones synchronously
    final tempUrlKey = '${providerId}_$selectedModel';
    final initialUrl = _tempApiUrls[tempUrlKey] ?? (Prefs().getPluginConfig('ai', '${providerId}_${selectedModel}_api_url') as String?) ?? '';
    final hasExistingKey = Prefs().hasPluginApiKey('ai_${providerId}_$selectedModel');
    final urlController = TextEditingController(text: initialUrl);
    final keyController = TextEditingController(text: _tempApiKeys['ai_${providerId}_$selectedModel'] ?? '');

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(L10n.of(context).settingsConfigureProvider(label)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedModel,
                  items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setStateDialog(() {
                      selectedModel = v;
                      // update url/key controllers for new model
                      final key = '${providerId}_$selectedModel';
                      urlController.text = _tempApiUrls[key] ?? (Prefs().getPluginConfig('ai', '${providerId}_${selectedModel}_api_url') as String?) ?? '';
                      keyController.text = _tempApiKeys['ai_${providerId}_$selectedModel'] ?? '';
                    });
                  },
                  decoration: InputDecoration(labelText: L10n.of(context).settingsModelLabel),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(labelText: L10n.of(context).settingsApiUrlOptional),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(labelText: L10n.of(context).settingsApiKey),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(hasExistingKey ? L10n.of(context).settingsApiKeySet : L10n.of(context).settingsApiKeyNotSet, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(L10n.of(context).commonCancel, style: TextStyle(color: prefs.secondaryColor))),
              FilledButton(
                style: ButtonStyle(backgroundColor: WidgetStateProperty.all(prefs.secondaryColor)),
                onPressed: () async {
                  final url = urlController.text.trim();
                  final key = keyController.text.trim();
                  // store temporarily; Apply will persist
                  final urlKey = '${providerId}_$selectedModel';
                  if (url.isNotEmpty) _tempApiUrls[urlKey] = url;
                  else _tempApiUrls.remove(urlKey);
                  final securePluginId = 'ai_${providerId}_$selectedModel';
                  if (key.isNotEmpty) _tempApiKeys[securePluginId] = key;
                  else _tempApiKeys[securePluginId] = '';
                  _tempLastModel[providerId] = selectedModel;
                  _tempActiveProvider = providerId;
                  _tempActiveModel = selectedModel;
                  Navigator.of(context).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).settingsProviderSaved(label))));
                },
                child: Text(L10n.of(context).commonSave),
              ),
            ],
          );
        });
      },
    );
  }

  Future<bool> _checkApiKey(String providerId) async {
    // Basic provider-specific connectivity check. This is intentionally lightweight
    // and does not exhaustively validate all provider API semantics.
    // prefer the active model (persisted) for per-model keys and URLs
    final model = (Prefs().getPluginConfig('ai', 'model') as String?) ?? (Prefs().getPluginConfig('ai', '${providerId}_last_model') as String?);
    final pluginId = model != null ? 'ai_${providerId}_$model' : 'ai_${providerId}';
    final key = await Prefs().getPluginApiKey(pluginId);
    if (key == null || key.isEmpty) return false;
    final modelUrl = model != null ? (Prefs().getPluginConfig('ai', '${providerId}_' + model + '_api_url') as String?) : null;
    final effectiveUrl = modelUrl ?? (Prefs().getPluginConfig('ai', '${providerId}_api_url') as String?);
    try {
      if (providerId == 'gpt') {
        // OpenAI: try listing models (allow custom URL if configured)
        final url = (effectiveUrl?.isNotEmpty == true ? effectiveUrl! : 'https://api.openai.com/v1/models');
        final resp = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $key'},
        ).timeout(const Duration(seconds: 6));
        return resp.statusCode == 200;
      } else if (providerId == 'claude') {
        // Anthropic: try listing models endpoint (allow custom URL)
        final url = (effectiveUrl?.isNotEmpty == true ? effectiveUrl! : 'https://api.anthropic.com/v1/models');
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
