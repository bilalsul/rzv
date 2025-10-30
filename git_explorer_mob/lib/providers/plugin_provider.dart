import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PluginSettings {
  final List<String> enabledPlugins;
  final Map<String, dynamic> pluginConfigs;

  const PluginSettings({
    // initially no plugins are enabled
    this.enabledPlugins = const [],
    this.pluginConfigs = const {},
  });

  PluginSettings copyWith({
    List<String>? enabledPlugins,
    Map<String, dynamic>? pluginConfigs,
  }) {
    return PluginSettings(
      enabledPlugins: enabledPlugins ?? this.enabledPlugins,
      pluginConfigs: pluginConfigs ?? this.pluginConfigs,
    );
  }

  static PluginSettings fromPreferences(SharedPreferences prefs) {
    return PluginSettings(
      enabledPlugins: prefs.getStringList('plugins_enabled') ?? [],
      pluginConfigs: _parsePluginConfigs(prefs),
    );
  }

  static Map<String, dynamic> _parsePluginConfigs(SharedPreferences prefs) {
    final configs = <String, dynamic>{};
    
    // Parse plugin-specific configurations
    final pluginKeys = prefs.getKeys().where((key) => key.startsWith('plugin_'));
    
    for (final key in pluginKeys) {
      final pluginName = key.replaceFirst('plugin_', '').split('_').first;
      final configKey = key.replaceFirst('plugin_${pluginName}_', '');
      
      if (!configs.containsKey(pluginName)) {
        configs[pluginName] = {};
      }
      
      final value = prefs.get(key);
      if (value != null) {
        configs[pluginName][configKey] = value;
      }
    }
    
    return configs;
  }

  Future<void> saveToPreferences(SharedPreferences prefs) async {
    // Save enabled plugins list
    await prefs.setStringList('plugins_enabled', enabledPlugins);
    
    // Save plugin configurations
    for (final pluginName in pluginConfigs.keys) {
      final config = pluginConfigs[pluginName] as Map<String, dynamic>;
      for (final configKey in config.keys) {
        final key = 'plugin_${pluginName}_$configKey';
        final value = config[configKey];
        
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
    }
  }

  bool isPluginEnabled(String pluginId) {
    return enabledPlugins.contains(pluginId);
  }
}

class PluginSettingsNotifier extends StateNotifier<PluginSettings> {
  final Ref ref;

  PluginSettingsNotifier(this.ref) : super(const PluginSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = PluginSettings.fromPreferences(prefs);
  }

  Future<void> togglePlugin(String pluginId, bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    List<String> updatedPlugins = List.from(state.enabledPlugins);
    
    if (enabled && !updatedPlugins.contains(pluginId)) {
      updatedPlugins.add(pluginId);
    } else if (!enabled && updatedPlugins.contains(pluginId)) {
      updatedPlugins.remove(pluginId);
    }

    await prefs.setStringList('plugins_enabled', updatedPlugins);
    state = state.copyWith(enabledPlugins: updatedPlugins);
  }

  Future<void> updatePluginConfig(String pluginId, String configKey, dynamic value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final updatedConfigs = Map<String, dynamic>.from(state.pluginConfigs);
    
    if (!updatedConfigs.containsKey(pluginId)) {
      updatedConfigs[pluginId] = {};
    }
    
    updatedConfigs[pluginId][configKey] = value;
    
    // Save the specific config
    final key = 'plugin_${pluginId}_$configKey';
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
    
    state = state.copyWith(pluginConfigs: updatedConfigs);
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = const PluginSettings();
    await updateSettings(defaultSettings);
  }

  Future<void> updateSettings(PluginSettings newSettings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await newSettings.saveToPreferences(prefs);
    state = newSettings;
  }
}

final pluginSettingsProvider = StateNotifierProvider<PluginSettingsNotifier, PluginSettings>(
  (ref) => PluginSettingsNotifier(ref),
);

// Convenience provider for enabled plugins list
final enabledPluginsProvider = Provider<List<String>>((ref) {
  return ref.watch(pluginSettingsProvider).enabledPlugins;
});

// Convenience provider to check if a specific plugin is enabled
ProviderFamily<bool, String> isPluginEnabledProvider = ProviderFamily<bool, String>(
  (ref, pluginId) {
    final plugins = ref.watch(pluginSettingsProvider);
    return plugins.isPluginEnabled(pluginId);
  },
);
