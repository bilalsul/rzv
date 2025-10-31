import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/plugin_provider.dart';

class FileExplorerSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  FileExplorerSettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final cfg = ref.read(pluginSettingsProvider).pluginConfigs['file_explorer'];
    return Map<String, dynamic>.from(cfg ?? {'showHidden': false, 'previewMarkdown': true});
  }

  void setShowHidden(bool v) {
    state = {...state, 'showHidden': v};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('file_explorer', 'showHidden', v);
  }

  void setPreviewMarkdown(bool v) {
    state = {...state, 'previewMarkdown': v};
    ref.read(pluginSettingsProvider.notifier).updatePluginConfig('file_explorer', 'previewMarkdown', v);
  }
}

final fileExplorerSettingsProvider = StateNotifierProvider<FileExplorerSettingsNotifier, Map<String, dynamic>>(
  (ref) => FileExplorerSettingsNotifier(ref),
);
