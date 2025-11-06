
# Application Widget Hierarchy

This document describes the app-level widget structure, each screen's core components, extension/plugin points and developer notes. It also documents common data flow patterns (how `Prefs`, service classes and providers are used) and testing/accessibility considerations.

- [Application Widget Hierarchy](#application-widget-hierarchy)
  - [App shell and navigation](#app-shell-and-navigation)
    - [Typical structure (conceptual)](#typical-structure-conceptual)
    - [Developer notes](#developer-notes)
  - [AppDrawer](#appdrawer)
    - [Main components](#main-components)
    - [Extension points](#extension-points)
    - [Behavior notes](#behavior-notes)
  - [HomeScreen](#homescreen)
    - [HomeScreen Components](#homescreen-components)
    - [ProjectCard](#projectcard)
    - [Data flow](#data-flow)
    - [Concurrency notes](#concurrency-notes)
  - [ProjectBrowser (inside HomeScreen)](#projectbrowser-inside-homescreen)
    - [ProjectBrowser Components](#projectbrowser-components)
    - [Important behaviors](#important-behaviors)
  - [EditorScreen](#editorscreen)
    - [Responsibilities](#responsibilities)
    - [EditorScreen Components](#editorscreen-components)
    - [Performance notes](#performance-notes)
  - [Git History screen](#git-history-screen)
  - [SettingsScreen](#settingsscreen)
    - [SettingsScreen Components](#settingsscreen-components)

## App shell and navigation

AppShell (top-level) — composes the high-level app chrome and decides which screen is visible. Key responsibilities:

- Provide `Scaffold` and app-level `Theme`/`Locale` wiring.
- Host `AppDrawer` and optional `BottomNavigationBar` / `NavigationRail`.
- Route changes: the app keeps `Prefs.lastKnownRoute` and uses navigation
    methods to navigate to saved routes (Home, Editor, Settings, etc.).

### Typical structure (conceptual)

AppShell
├── AppDrawer (left drawer)
├── AppBar (dynamic title / actions)
└── Body (current route/screen) — managed by router or manual switch
        ├── HomeScreen
        ├── EditorScreen
        ├── GitHistoryScreen (NOT SUPPORTED YET)
        └── SettingsScreen

### Developer notes

- Keep AppShell lightweight; heavy work belongs to screens.
- Avoid subscribing to large providers directly in AppShell; delegate to children.

## AppDrawer

Purpose: quick access to plugins, the current project, and common actions.

### Main components

- DrawerHeader
  - App logo + app name
  - Current open project name (reads `Prefs.currentProjectName`)
  - 'Last opened' metadata (reads `Prefs.lastOpenedProjectTime` and formats it)
- Plugin toggles list
  - Section per category (Editor, Git, Utilities, Experimental)
  - Each plugin row: icon, localized name/description (via L10n), toggle switch that calls `Prefs.setPluginEnabled(pluginId, enabled)`
- Quick actions (optional): import project, create new, feedback
- Footer: version, about, settings link

### Extension points

- PluginSettings: expandable area per plugin to expose plugin-specific configuration UI. Those settings are persisted using `Prefs.setPluginConfig`.

### Behavior notes

- When enabling file-explorer the drawer should request platform storage permission (Android) before setting the plugin enabled flag.
- Drawer toggles must be fast and synchronous in UI; any async work (like creating tutorial projects) should be scheduled outside the toggle handler (post-frame or a microtask) to avoid blocking the UI.

## HomeScreen

Purpose: list available projects (local + imported), enable import/createproject, and open a project.

### HomeScreen Components

- Project grid/list — shows `ProjectCard` items
- Empty state — call-to-action to create/import projects
- Floating action buttons — create/import actions

### ProjectCard

- Thumbnail/avatar (first letter or repo icon)
- Project name, type (Sample/Imported/Local/Tutorial), file count, last modified
- Popup menu: Open, Delete (with confirm) — delete must clear disk and prefs

### Data flow

- On startup HomeScreen checks `Prefs.fileExplorerEnabled` and, if true, calls `Prefs.projectsRoot()` and loads directories (via `_loadProjectsFromDisk`).
- The in-memory `_projects` list is a snapshot of directories found under the projects root and is rebuilt after create/import/delete operations.

### Concurrency notes

- Disk operations (zip extraction, recursive reads) must run asynchronously and the UI must await a reload before showing results to avoid duplicates.

## ProjectBrowser (inside HomeScreen)

When a project is opened inside HomeScreen the ProjectBrowser displays a file tree and README previews.

### ProjectBrowser Components

- Breadcrumb/back navigation (path stack)
- Directory listing (folders first, then files)
- README / Markdown preview (uses `flutter_markdown`)
- File open action: resolves absolute path and writes `Prefs.saveCurrentOpenFile` and `Prefs.saveCurrentProject` then navigates to the editor.

### Important behaviors

- When opening a file, prefer reading from disk; fallback to the in-memory tree snapshot if the file is absent.
- Creating a file: write to disk under the project directory and reload the project snapshot so the file becomes visible immediately.

## EditorScreen

### Responsibilities

- Display current file (reads `Prefs.currentOpenFile` and `Prefs.currentOpenFileContent`).
- Provide save action to persist to disk and `Prefs.saveCurrentOpenFileContent`.
- Provide editor settings toolbar (monaco options wired from `Prefs.getEditorSettings`).

### EditorScreen Components

- EditorToolbar (format/save/undo/redo, plugin quick-actions)
- MonacoEditor widget or equivalent code editor (hosted in WebView or native)
- Status bar (language, encoding, line/column)

### Performance notes

- Avoid rebuilding the editor widget on unrelated preference changes — scope provider listeners to the precise values needed (use `ref select`).
- Use `debounce` for autosave and run heavy formatting/analysis in an isolate using `compute`.

## Git History screen

NOT SUPPORTED YET

## SettingsScreen

Settings are grouped into categories. Each SettingItem writes to `Prefs` and calls `notifyListeners()` so consumers update.

### SettingsScreen Components

- Categories (Editor, Appearance, Plugins, Git, Files, Advanced)
- Each setting row has a localized title and optional description (L10n)
- Controls: toggles, dropdowns, sliders, color pickers, text inputs
