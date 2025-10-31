import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';

class FileExplorerSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  FileExplorerSettingsNotifier(this.ref) : super(_initial(ref));

  static Map<String, dynamic> _initial(Ref ref) {
    final showHidden = Prefs().getPluginConfig('file_explorer', 'showHidden') ?? false;
    final previewMarkdown = Prefs().getPluginConfig('file_explorer', 'previewMarkdown') ?? true;
    return {'showHidden': showHidden, 'previewMarkdown': previewMarkdown};
  }

  void setShowHidden(bool v) {
    state = {...state, 'showHidden': v};
    Prefs().setPluginConfig('file_explorer', 'showHidden', v);
  }

  void setPreviewMarkdown(bool v) {
    state = {...state, 'previewMarkdown': v};
    Prefs().setPluginConfig('file_explorer', 'previewMarkdown', v);
  }
}

final fileExplorerSettingsProvider = StateNotifierProvider<FileExplorerSettingsNotifier, Map<String, dynamic>>(
  (ref) => FileExplorerSettingsNotifier(ref),
);
