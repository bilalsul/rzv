import 'package:rzv/enums/options/plugin.dart';

enum Screen {
  home,
  editor,
  ai,
  fileExplorer,
  gitHistory,
  terminal,
  settings,
  zipManager
}

// convert Screen enum to string
String screenToString(Screen screen) {
  switch (screen) {
    case Screen.home:
      return 'home';
    case Screen.editor:
      return 'editor';
    case Screen.ai:
      return Plugin.ai.id;
    case Screen.fileExplorer:
      return Plugin.fileExplorer.id;
    case Screen.gitHistory:
      return 'git_history';
    case Screen.terminal:
      return 'terminal';
    case Screen.settings:
      return 'settings';
    case Screen.zipManager:
      return Plugin.zipManager.id;
  }
}