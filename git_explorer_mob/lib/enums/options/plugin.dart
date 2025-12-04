enum Plugin {
  themeCustomizer('theme_customizer'),

  readOnlyMode('readonly_mode'),
  syntaxHighlighting('syntax_highlighting'),
  codeFolding('code_folding'),

  advancedEditorOptions('advanced_editor_options'),
  editorZoomInOut('editor_zoom_in_out'),
  editorLineNumbers('editor_line_numbers'),
  editorMinimap('editor_minimap'),
  editorRenderControlCharacters('editor_render_control_characters'),
  editorWordWrap('editor_word_wrap'),

  ai('ai_assist'),

  fileExplorer('file_explorer'),
  previewMarkdown('preview_markdown');

  final String id;
  const Plugin(this.id);
}
