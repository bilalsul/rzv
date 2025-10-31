import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/plugin_provider.dart';

class AISettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  AISettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final cfg = ref.read(pluginSettingsProvider).pluginConfigs['ai'];
    return Map<String, dynamic>.from(cfg ?? {'model': 'gpt', 'maxTokens': 512});
  }

  void setModel(String m) {
    state = {...state, 'model': m};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('ai', 'model', m);
  }

  void setMaxTokens(int v) {
    state = {...state, 'maxTokens': v};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('ai', 'maxTokens', v);
  }
}

final aiSettingsProvider = StateNotifierProvider<AISettingsNotifier, Map<String, dynamic>>(
  (ref) => AISettingsNotifier(ref),
);
