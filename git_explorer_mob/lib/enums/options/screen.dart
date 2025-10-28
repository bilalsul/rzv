enum Screen {
  home,
  editor,
  fileExplorer,
  gitHistory,
  settings,
}

// convert Screen enum to string
String screenToString(Screen screen) {
  switch (screen) {
    case Screen.home:
      return 'home';
    case Screen.editor:
      return 'editor';
    case Screen.fileExplorer:
      return 'file_explorer';
    case Screen.gitHistory:
      return 'git_history';
    case Screen.settings:
      return 'settings';
  }
}