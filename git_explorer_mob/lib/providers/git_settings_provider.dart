import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';

class GitSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  GitSettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final autoFetch = Prefs().getPluginConfig('git', 'autoFetch') ?? true;
    final defaultBranch = Prefs().getPluginConfig('git', 'defaultBranch') ?? 'main';
    return {'autoFetch': autoFetch, 'defaultBranch': defaultBranch};
  }

  void setAutoFetch(bool v) {
    state = {...state, 'autoFetch': v};
    Prefs().setPluginConfig('git', 'autoFetch', v);
  }

  void setDefaultBranch(String name) {
    state = {...state, 'defaultBranch': name};
    Prefs().setPluginConfig('git', 'defaultBranch', name);
  }
}

final gitSettingsProvider = StateNotifierProvider<GitSettingsNotifier, Map<String, dynamic>>(
  (ref) => GitSettingsNotifier(ref),
);
