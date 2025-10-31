import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/plugin_provider.dart';

class EditorSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  EditorSettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final cfg = ref.read(pluginSettingsProvider).pluginConfigs['editor'];
    return Map<String, dynamic>.from(cfg ?? {'tabSize': 2, 'showLineNumbers': true});
  }

  void setTabSize(int size) {
    state = {...state, 'tabSize': size};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('editor', 'tabSize', size);
  }

  void setShowLineNumbers(bool v) {
    state = {...state, 'showLineNumbers': v};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('editor', 'showLineNumbers', v);
  }
}

final editorSettingsProvider = StateNotifierProvider<EditorSettingsNotifier, Map<String, dynamic>>(
  (ref) => EditorSettingsNotifier(ref),
);
