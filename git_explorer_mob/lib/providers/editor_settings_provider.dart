import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';

class EditorSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  EditorSettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final tabSize = Prefs().getPluginConfig('editor', 'tabSize') ?? 2;
    final showLineNumbers = Prefs().getPluginConfig('editor', 'showLineNumbers') ?? true;
    return {'tabSize': tabSize, 'showLineNumbers': showLineNumbers};
  }

  void setTabSize(int size) {
    state = {...state, 'tabSize': size};
    Prefs().setPluginConfig('editor', 'tabSize', size);
  }

  void setShowLineNumbers(bool v) {
    state = {...state, 'showLineNumbers': v};
    Prefs().setPluginConfig('editor', 'showLineNumbers', v);
  }
}

final editorSettingsProvider = StateNotifierProvider<EditorSettingsNotifier, Map<String, dynamic>>(
  (ref) => EditorSettingsNotifier(ref),
);
