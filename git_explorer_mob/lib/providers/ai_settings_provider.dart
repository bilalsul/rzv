import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';

class AISettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  AISettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final model = Prefs().getPluginConfig('ai', 'model') ?? 'gpt';
    final maxTokens = Prefs().getPluginConfig('ai', 'maxTokens') ?? 512;
    return {'model': model, 'maxTokens': maxTokens};
  }

  void setModel(String m) {
    state = {...state, 'model': m};
    Prefs().setPluginConfig('ai', 'model', m);
  }

  void setMaxTokens(int v) {
    state = {...state, 'maxTokens': v};
    Prefs().setPluginConfig('ai', 'maxTokens', v);
  }
}

final aiSettingsProvider = StateNotifierProvider<AISettingsNotifier, Map<String, dynamic>>(
  (ref) => AISettingsNotifier(ref),
);
