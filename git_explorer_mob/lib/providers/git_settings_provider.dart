import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/plugin_provider.dart';

class GitSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  GitSettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final cfg = ref.read(pluginSettingsProvider).pluginConfigs['git'];
    return Map<String, dynamic>.from(cfg ?? {'autoFetch': true, 'defaultBranch': 'main'});
  }

  void setAutoFetch(bool v) {
    state = {...state, 'autoFetch': v};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('git', 'autoFetch', v);
  }

  void setDefaultBranch(String name) {
    state = {...state, 'defaultBranch': name};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('git', 'defaultBranch', name);
  }
}

final gitSettingsProvider = StateNotifierProvider<GitSettingsNotifier, Map<String, dynamic>>(
  (ref) => GitSettingsNotifier(ref),
);
