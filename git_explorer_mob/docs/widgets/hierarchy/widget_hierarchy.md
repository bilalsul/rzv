# Application Widget Hierarchy

- [Application Widget Hierarchy](#application-widget-hierarchy)
  - [Main](#main)
  - [AppDrawer](#appdrawer)
  - [HomeScreen](#homescreen)
  - [EditorScreen](#editorscreen)
  - [FileExplorerScreen](#fileexplorerscreen)
  - [GitHistoryScreen](#githistoryscreen)
  - [SettingsScreen](#settingsscreen)
    - [SettingsCategories](#settingscategories)

## Main

```py
AppShell
├── AppDrawer # Plugin Toggles
├── DynamicAppBar # Dynamic based on Screen
│   └── Body # based on whats the currentScreen flag, if all plugins/features ON, one is currentScreen
│       ├── HomeScreen # Projects
│       ├── EditorScreenEditor
│       ├── AIScreen # AI
│       ├── GitHistoryScreen # Git History
│       ├── TerminalScreen # Terminal
│       └── SettingsScreen # Settings
├── BottomNavigationBar # if all plugins enabled, default are Projects, Editor and Settings
│   ├── Projects
│   ├── Editor
│   ├── AI
│   ├── Git History
│   ├── Terminal
│   └── Settings

```

## AppDrawer

```py
AppDrawer
├── DrawerHeader
│   ├── AppLogo
│   ├── CurrentProject
│   └── ProjectQuickInfo
├── PluginTogglesSection # for each plugin category
│   ├── PluginToggleItem # for each member of a plugin category
│   │   ├── PluginIcon
│   │   ├── PluginName
│   │   ├── PluginDescription
│   │   ├── ToggleSwitch
│   │   └── PluginSettings # expandable
│   └── PluginCategories
│       ├── EditorPlugins
│       ├── GitPlugins
│       ├── UtilityPlugins
│       └── ExperimentalPlugins
"""
├── QuickActionsSection
│   ├── QuickAction
│   │   ├── ActionIcon
│   │   ├── ActionLabel
│   │   └── ShortcutHint
│   └── ActionGroups
"""
└── DrawerFooter
    ├── FeedbackButton
    ├── AboutButton
    └── AppVersion
```

## HomeScreen

```py
HomeScreen
""" there is an already existing DynamicAppBar
├── HomeAppBar
│   ├── AppTitle
│   └── QuickSettingsMenu
"""
├── ProjectGrid/List
│   ├── ProjectCard
│   │   ├── ProjectThumbnail
│   │   ├── ProjectName
│   │   ├── ProjectMetadata
│   │   │   ├── FileCount
│   │   │   ├── LastModified
│   │   │   └── ProjectType
│   │   └── ProjectActions
│   │       ├── OpenProjectButton
│   │       └── ProjectMenu
│   └── EmptyState # when no projects
│       ├── EmptyIllustration
│       ├── EmptyMessage
│       └── CallToAction
├── FloatingActionArea
│   ├── ImportProjectButton
│   └── CreateProjectButton # if needed
"""
└── BottomNavigation # optional
    ├── GridViewToggle
    ├── SortOptions
    └── FilterOptions
"""
```

## EditorScreen

```txt
EditorScreen
├── EditorToolbar
│   ├── FileActions
│   ├── EditorSettings
│   └── PluginQuickActions
└── MonacoEditor
    └── EditorOverlay (plugins can inject here)
```

## FileExplorerScreen

```txt
FileExplorerScreen
├── ExplorerAppBar
│   ├── BreadcrumbNavigation
│   │   ├── RootLink
│   │   ├── PathSegments
│   │   └── CurrentDirectory
│   ├── SearchBar
│   │   ├── SearchInput
│   │   └── SearchFilters
│   └── ViewOptions
│       ├── ViewTypeToggle (List/Grid)
│       ├── SortMenu
│       └── FilterMenu
├── FileTree
│   ├── DirectoryNode
│   │   ├── ExpandCollapseButton
│   │   ├── FolderIcon
│   │   ├── DirectoryName
│   │   └── ChildFiles (recursive)
│   └── FileNode
│       ├── FileIcon (type-based)
│       ├── FileName
│       ├── FileMetadata
│       │   ├── FileSize
│       │   └── ModifiedTime
│       └── FileActions
│           ├── OpenFileButton
│           ├── QuickPreview
│           └── FileMenu
├── PreviewPanel (optional)
│   ├── PreviewHeader
│   ├── FilePreview
│   └── QuickActions
└── StatusBar
    ├── SelectedCount
    ├── TotalItems
    └── StorageInfo
```

## GitHistoryScreen

```txt
GitHistoryScreen
├── GitAppBar
│   ├── RepositorySelector
│   ├── BranchSelector
│   └── RefreshButton
├── HistoryView
│   ├── Timeline
│   │   └── CommitNode
│   │       ├── CommitHash (abbreviated)
│   │       ├── CommitMessage
│   │       ├── CommitAuthor
│   │       ├── CommitDate
│   │       ├── CommitActions
│   │       │   ├── ExpandDiff
│   │       │   └── ViewDetails
│   │       └── FileChanges
│   │           ├── ChangedFile
│   │           │   ├── ChangeType (M/A/D/R)
│   │           │   ├── FilePath
│   │           │   └── DiffStats
│   │           └── DiffSummary
│   └── GraphVisualization (optional)
│       ├── BranchLines
│       ├── MergeNodes
│       └── CommitDots
├── DiffViewer (when expanded)
│   ├── DiffHeader
│   │   ├── FilePath
│   │   ├── ChangeStats
│   │   └── ViewOptions
│   ├── SideBySideDiff
│   │   ├── OldVersion
│   │   │   ├── LineNumbers
│   │   │   └── CodeContent
│   │   └── NewVersion
│   │       ├── LineNumbers
│   │       └── CodeContent
│   └── UnifiedDiff (alternative view)
└── GitControls
    ├── FetchButton
    ├── PullButton
    ├── PushButton
    └── GitLog
```

## SettingsScreen

```txt
SettingsScreen
├── SettingsAppBar
│   ├── ScreenTitle
│   └── SearchSettings (optional)
├── SettingsCategories
│   ├── CategorySection
│   │   ├── CategoryHeader
│   │   └── SettingsGroup
│   │       ├── SettingItem
│   │       │   ├── SettingIcon
│   │       │   ├── SettingTitle
│   │       │   ├── SettingDescription
│   │       │   └── SettingControl
│   │       │       ├── ToggleSwitch
│   │       │       ├── SliderControl
│   │       │       ├── DropdownMenu
│   │       │       ├── ColorPicker
│   │       │       └── TextInput
│   │       └── SubSettings (nested)
│   └── PluginSettings
│       ├── PluginToggle
│       ├── PluginConfiguration
│       └── PluginDependencies
├── PreviewPanel (real-time preview)
│   ├── ThemePreview
│   ├── EditorPreview
│   └── LayoutPreview
└── SettingsActions
    ├── ExportSettings
    ├── ImportSettings
    ├── ResetDefaults
    └── SaveButton
```

### SettingsCategories

```txt
SettingsCategories
├── Editor
│   ├── Appearance
│   ├── Behavior
│   └── Keybindings
├── Appearance
│   ├── Theme
│   ├── Layout
│   └── Fonts
├── Plugins
│   ├── InstalledPlugins
│   ├── AvailablePlugins
│   └── PluginManager
├── Git
│   ├── Integration
│   ├── Authentication
│   └── Behavior
├── Files
│   ├── FileAssociations
│   ├── AutoSave
│   └── FileEncoding
└── Advanced
    ├── Performance
    ├── Experimental
    └── Debug
```
