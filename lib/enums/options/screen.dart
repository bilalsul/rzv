enum Screen {
  home,
  editor,
  ai,
  fileExplorer,
  gitHistory,
  terminal,
  settings,
}

// convert Screen enum to string
String screenToString(Screen screen) {
  switch (screen) {
    case Screen.home:
      return 'home';
    case Screen.editor:
      return 'editor';
    case Screen.ai:
      return 'ai';
    case Screen.fileExplorer:
      return 'file_explorer';
    case Screen.gitHistory:
      return 'git_history';
    case Screen.terminal:
      return 'terminal';
    case Screen.settings:
      return 'settings';
  }
}