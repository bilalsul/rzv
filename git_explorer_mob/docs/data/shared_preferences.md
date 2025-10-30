# Global Shared Preferences Categories

- [Global Shared Preferences Categories](#global-shared-preferences-categories)
  - [1. Editor Settings Category](#1-editor-settings-category)
  - [2. Appearance \& Theme Category](#2-appearance--theme-category)
  - [3. Plugin System Category](#3-plugin-system-category)
  - [4. File Management Category](#4-file-management-category)
  - [5. Git Integration Category](#5-git-integration-category)
  - [6. Navigation \& Layout Category](#6-navigation--layout-category)
  - [7. Performance \& Advanced Category](#7-performance--advanced-category)
  - [8. Keyboard \& Input Category](#8-keyboard--input-category)
  - [9. Internationalization Category](#9-internationalization-category)
  - [10. Backup \& Sync Category](#10-backup--sync-category)
  - [11. Accessibility Category](#11-accessibility-category)
  - [12. Application State Category](#12-application-state-category)

## 1. Editor Settings Category

```yaml
editor_settings:
  # Monaco Editor Configuration
  monaco_theme: "vs-dark" , "vs" , "hc-black" , "hc-light"
  font_size: 14.0
  font_family: "Fira Code, Monaco, Menlo, Consolas"
  tab_size: 2
  insert_spaces: true
  word_wrap: "on" , "off" , "wordWrapColumn" , "bounded"
  line_numbers: "on" , "off" , "relative" , "interval"
  minimap_enabled: true
  auto_indent: true
  match_brackets: true
  code_lens: false
  
  # Editor Behavior
  auto_save: true
  auto_save_delay: 1000
  format_on_save: false
  trim_trailing_whitespace: false
  insert_final_newline: true
  
  # Advanced Editor Settings
  cursor_style: "line" , "block" , "underline" , "line-thin" , "block-outline" , "underline-thin"
  cursor_blinking: "blink" , "smooth" , "phase" , "expand" , "solid"
  render_whitespace: "none" , "boundary" , "selection" , "trailing" , "all"
  render_control_characters: false
```

## 2. Appearance & Theme Category

```yaml
appearance_settings:
  # Theme System
  theme_mode: "system" , "light" , "dark" , "custom"
  custom_theme_name: "default_custom"
  
  # Color Scheme
  primary_color: 0xFF2196F3
  secondary_color: 0xFFFF9800
  background_color: 0xFF121212
  surface_color: 0xFF1E1E1E
  error_color: 0xFFCF6679
  
  # UI Density
  ui_density: "comfortable" , "compact" , "expanded"
  button_style: "elevated" , "filled" , "tonal" , "outlined" , "text"
  border_radius: 8.0
  elevation_level: 2.0
  
  # Typography
  app_font_family: "Roboto"
  app_font_size: 14.0
  heading_font_scale: 1.5
  code_font_scale: 1.0
  
  # Animation
  animation_speed: 1.0
  reduce_animations: false
  ripple_effect: true
```

## 3. Plugin System Category

```yaml
plugin_settings:
  # Plugin Management
  enabled_plugins: ["readonly_mode", "git_history", "theme_customizer", "file_explorer"]
  disabled_plugins: ["experimental_feature_x"]
  plugin_load_order: ["core", "editor", "git", "utility"]
  
  # Plugin States
  plugin_states:
    readonly_mode:
      enabled: false
      auto_enable_large_files: true
      file_size_threshold: 1000000
      
    git_history:
      enabled: true
      max_commit_history: 1000
      show_author_names: true
      show_commit_hashes: true
      
    theme_customizer:
      enabled: true
      sync_with_system: true
      auto_switch_dark: true
      
    file_explorer:
      enabled: true
      show_hidden_files: false
      sort_by: "name" , "modified" , "size" , "type"
      sort_order: "ascending" , "descending"
  
  # Plugin Dependencies
  dependency_graph: {}
  conflicting_plugins: []
```

## 4. File Management Category

```yaml
file_settings:
  # File Operations
  default_encoding: "utf-8"
  auto_detect_encoding: true
  line_endings: "system" , "lf" , "crlf"
  
  # File Associations
  file_associations:
    ".dart": "dart"
    ".js": "javascript"
    ".ts": "typescript"
    ".py": "python"
    ".java": "java"
    ".cpp": "cpp"
    ".html": "html"
    ".css": "css"
    ".json": "json"
    ".md": "markdown"
    ".yaml": "yaml"
    ".xml": "xml"
  
  # Recent Files
  recent_projects: ["/path/to/project1", "/path/to/project2"]
  max_recent_projects: 10
  reopen_last_project: true
  
  # File Explorer
  file_explorer_visible: true
  file_explorer_position: "left" , "right"
  file_explorer_width: 250.0
```

## 5. Git Integration Category

```yaml
git_settings:
  # Git Configuration
  git_enabled: true
  git_path: "/usr/bin/git"
  auto_fetch: true
  fetch_interval: 300
  
  # Git Behavior
  show_untracked_files: true
  show_ignored_files: false
  default_commit_message: "Update"
  auto_stage_changes: false
  
  # Git Visualization
  graph_style: "simple" , "detailed" , "graph"
  show_author_avatars: true
  show_commit_dates: "relative" , "absolute" , "both"
  
  # Git Authentication
  git_username: ""
  git_email: ""
  remember_credentials: false
  credential_helper: "store" , "cache" , "osxkeychain" , "wincred" , "libsecret"
```

## 6. Navigation & Layout Category

```yaml
navigation_settings:
  # Layout Configuration
  default_home_screen: "projects" , "recent" , "editor"
  navigation_style: "drawer" , "bottom_nav" , "rail"
  multi_pane_enabled: false
  
  # Screen States
  visible_screens: ["editor", "file_explorer", "git_history"]
  hidden_screens: ["debug_panel"]
  screen_positions: {}
  
  # Workspace Management
  workspace_layout: "mobile" , "tablet" , "desktop"
  restore_layout_on_startup: true
  remember_panel_sizes: true
```

## 7. Performance & Advanced Category

```yaml
performance_settings:
  # Memory Management
  max_file_size_mb: 10
  large_file_handling: "readonly" , "limit_operations" , "deny_open"
  cache_size_mb: 100
  clear_cache_on_exit: false
  
  # Editor Performance
  syntax_highlighting: true
  bracket_matching: true
  code_folding: true
  semantic_highlighting: false
  
  # App Performance
  background_processing: true
  git_operations_in_background: true
  file_watcher_enabled: true
  
  # Debug & Development
  developer_mode: false
  show_performance_overlay: false
  debug_paint_enabled: false
  inspector_enabled: false
```

## 8. Keyboard & Input Category

```yaml
input_settings:
  # Keyboard Shortcuts
  keybindings_scheme: "default"
  custom_keybindings: {}
  
  # Touch Gestures
  pinch_to_zoom: true
  double_tap_to_zoom: true
  swipe_to_navigate: true
  
  # Input Behavior
  auto_complete: true
  auto_close_brackets: true
  auto_close_quotes: true
  suggest_on_trigger_characters: true
  accept_suggestion_on_enter: "on" , "off" , "smart"
```

## 9. Internationalization Category

```yaml
i18n_settings:
  # Language & Locale
  app_locale: "en" , "es" , "fr" , "de" , "ja" , "zh"
  fallback_locale: "en"
  
  # Regional Settings
  date_format: "system" , "yyyy-MM-dd" , "MM/dd/yyyy" , "dd/MM/yyyy"
  time_format: "system" , "12h" , "24h"
  first_day_of_week: "monday" , "sunday"
  
  # Text Direction
  text_direction: "locale" , "ltr" , "rtl"
```

## 10. Backup & Sync Category

```yaml
backup_settings:
  # Auto Backup
  auto_backup: true
  backup_interval: 300
  max_backup_files: 10
  
  # Cloud Sync
  cloud_sync_enabled: false
  cloud_provider: "none" , "google_drive" , "dropbox" , "icloud"
  sync_frequency: "daily" , "weekly" , "on_change"
  
  # Export Settings
  settings_export_path: "/backups/settings"
  auto_export_settings: false
```

## 11. Accessibility Category

```yaml
accessibility_settings:
  # Visual Accessibility
  high_contrast: false
  large_text: false
  bold_text: false
  reduce_transparency: false
  
  # Interaction
  screen_reader_support: true
  keyboard_navigation: true
  touch_target_size: "normal" , "large" , "extra_large"
  
  # Cognitive
  disable_animations: false
  simplified_ui: false
  focus_mode: false
```

## 12. Application State Category

```yaml
app_state:
  # Session Management
  last_opened_project: "/path/to/last/project"
  last_known_route: "/editor/project123"
  session_start_time: "2024-01-15T10:30:00Z"
  
  # User Preferences
  onboarding_completed: true
  terms_accepted: true
  analytics_opted_in: false
  crash_reporting_enabled: true
  
  # App Information
  app_version: "1.0.0"
  build_number: "1"
  first_install_date: "2024-01-01T00:00:00Z"
```
