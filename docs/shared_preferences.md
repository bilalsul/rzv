# Prefs (SharedPreferences)

This document explains the `Prefs` singleton used across Git Explorer Mobile to centralize app settings, feature flags, and editor/session state. It documents the public API, stored SharedPreferences keys, intended behavior, edge cases, migration tips, and troubleshooting steps.

- [Prefs (SharedPreferences)](#prefs-sharedpreferences)
  - [Introduction](#introduction)
    - [Why this exists](#why-this-exists)
  - [How Prefs is wired into the app](#how-prefs-is-wired-into-the-app)
  - [Initialization lifecycle](#initialization-lifecycle)
  - [Key categories and naming conventions](#key-categories-and-naming-conventions)
  - [API reference (high-level)](#api-reference-high-level)
  - [Secure API key helpers](#secure-api-key-helpers)
  - [Current project \& editor helpers](#current-project--editor-helpers)
  - [Projects root handling](#projects-root-handling)
  - [Plugin helpers \& flags](#plugin-helpers--flags)
  - [Theme \& UI preferences](#theme--ui-preferences)
  - [Editor preferences](#editor-preferences)
  - [App/session \& misc keys](#appsession--misc-keys)
  - [Best practices \& patterns](#best-practices--patterns)
  - [Migration \& compatibility notes](#migration--compatibility-notes)
  - [Troubleshooting \& FAQ](#troubleshooting--faq)
  - [Appendix: full key list (alphabetical)](#appendix-full-key-list-alphabetical)
  - [Notes \& final recommendations](#notes--final-recommendations)

## Introduction

`Prefs` is a singleton ChangeNotifier that wraps Flutter's `SharedPreferences` and a `FlutterSecureStorage` instance to provide a single source of truth for app settings. Widgets observe `Prefs` via the `prefsProvider` (a Riverpod ChangeNotifierProvider) so UI can rebuild when preferences change.

### Why this exists

- Centralize persistent settings so multiple widgets and screens don't read/write SharedPreferences directly.
- Provide convenience getters and typed setters for common concepts (themes, projects, editor settings).
- Emit `notifyListeners()` for UI updates when preferences change.

## How Prefs is wired into the app

- `sharedPreferencesProvider` is a `FutureProvider<SharedPreferences>` used to ensure SharedPreferences is ready early in startup.
- `prefsProvider` is a `ChangeNotifierProvider<Prefs>` that constructs the singleton and exposes its state.
- Example usage in code:

```dart
// Wait for SharedPreferences during app bootstrap
await ref.read(sharedPreferencesProvider.future);
// Then access Prefs via Riverpod
final prefs = ref.watch(prefsProvider);
// Read a value
final themeMode = prefs.themeMode;
// Save a value
await prefs.saveThemeMode('dark');
```

## Initialization lifecycle

1. `prefsProvider` constructs a `Prefs` singleton (via factory returning `_instance`).
2. In `Prefs._internal()`, `initPrefs()` is called which awaits `SharedPreferences.getInstance()` and stores it in `prefs`.
3. Code that needs to access `SharedPreferences` early should await `sharedPreferencesProvider.future` to guarantee readiness.

Important: many getters in `Prefs` directly access `prefs`. If `initPrefs()` hasn't completed yet callers may read default values. During app startup prefer to await the `sharedPreferencesProvider` or use `areSettingsLoadedProvider`.

## Key categories and naming conventions

The project follows a predictable key naming convention to keep preferences organized:

- App-level keys: prefixed with `app_` (e.g., `app_last_opened_project`, `app_last_known_route`).
- Editor keys: prefixed with `editor_` (e.g., `editor_current_file`, `editor_current_content`).
- Theme keys: prefixed with `theme_` (e.g., `theme_mode`, `theme_primary_color`).
- Plugin flags: stored in a `plugins_enabled` string-list or per-plugin keys like `plugin_<id>_<config>`.
- Plugin API keys: stored in secure storage under `plugin_<pluginId>_api_key` and mirrored by a flag `plugin_<pluginId>_has_api_key`.

This convention makes it easy to search and migrate keys when needed.

## API reference (high-level)

The following sections describe the main getters and methods available on the `Prefs` object. This is not a line-by-line copy of the source but a practical reference for consumers.

## Secure API key helpers

- Future<void> setPluginApiKey(String pluginId, String apiKey)
  - Stores `apiKey` in `FlutterSecureStorage` under `plugin_<pluginId>_api_key` and sets a boolean flag `plugin_<pluginId>_has_api_key` in SharedPreferences. Calls `notifyListeners()`.

- Future<String?> getPluginApiKey(String pluginId)
  - Reads the secure storage entry for a plugin API key (may be null).

- bool hasPluginApiKey(String pluginId)
  - Synchronous helper that returns the boolean flag from SharedPreferences.

- Future<void> removePluginApiKey(String pluginId)
  - Deletes secure storage entry and clears the boolean flag.

## Current project & editor helpers

- Future<void> saveCurrentProject({required String id, required String name, required String path})
  - Persists `current_project_id`, `current_project_name`, and `current_project_path` and also updates legacy `app_last_opened_project` and `app_last_opened_project_time` ISO timestamp. Calls `notifyListeners()`.

- String get currentProjectId / currentProjectName / currentProjectPath
  - Read-only getters returning empty string if not present.

- Future<void> saveCurrentOpenFile(String projectId, String filePath, String content)
  - Persists `editor_current_project`, `editor_current_file`, and `editor_current_content`. Use this before navigating to the editor to keep the editor and drawer in sync.

- String get currentOpenProject / currentOpenFile / currentOpenFileContent
  - Accessors for the editor session. `currentOpenFileContent` defaults to a small placeholder if empty.

- Future<void> saveCurrentOpenFileContent(String content)
  - Update only the editor's in-progress content.

## Projects root handling

- Future<Directory> projectsRoot()
  - Returns a `Directory` pointing to the app-specific `projects` folder. Implementation uses `getApplicationDocumentsDirectory()` and creates `${base.path}/projects` if it does not exist.
  - Note: The code contains commented-out Android external storage handling; the current implementation uses sandboxed app documents directory for cross-platform safety.

## Plugin helpers & flags

- List<String> get enabledPlugins
  - Returns the list stored in SharedPreferences under `plugins_enabled`.

- bool isPluginEnabled(String pluginId)
  - Convenience wrapper that checks whether `plugins_enabled` contains the plugin id.

- Future<void> setPluginEnabled(String pluginId, bool enabled)
  - Adds or removes `pluginId` from `plugins_enabled` and calls `notifyListeners()`.

- dynamic getPluginConfig(String pluginId, String configKey)
  - Reads a `plugin_<pluginId>_<configKey>` key from SharedPreferences returning the raw primitive (String, int, bool, List<String> or null).

- Future<void> setPluginConfig(String pluginId, String configKey, dynamic value)
  - Writes a plugin-scoped config value. Accepts String/int/double/bool/List<String> and falls back to toString() for other values. Calls `notifyListeners()`.

## Theme & UI preferences

Common theme getters and setters encode values as simple primitives:

- ThemeMode get themeMode — uses a string `theme_mode` with values `dark`, `light`, `system`.
- Color getters: `primaryColor`, `secondaryColor`, `backgroundColor`, `surfaceColor`, `errorColor` — stored as ARGB integer values (ints) using keys like `theme_primary_color`.
- Other UI: `borderRadius` (double), `elevationLevel` (double), `appFontSize` (double), `appFontFamily` (String), `uiDensity` (String), `buttonStyle` (String).

## Editor preferences

Editor preferences use keys prefixed with `editor_` and control the in-app (Monaco) editor: font, theme, autosave, minimap, line numbers, tab size, code formatting, etc. Examples:

- `editor_monaco_theme` (String)
- `editor_font_size` (double)
- `editor_minimap_enabled` (bool)
- `editor_auto_save` (bool)
- `editor_auto_save_delay` (int)

There are also helper methods like `getEditorSettings()` which returns a Map used to initialize/configure the editor in the UI.

## App/session & misc keys

- `app_last_opened_project` (String) and `app_last_opened_project_time` (ISO8601 timestamp String) — used to show "Last opened" metadata in the UI.
- `app_last_known_route` — used to remember the last screen the user was on (e.g., `/editor`).
- `app_session_start_time` — stored as ISO8601 string.
- `app_onboarding_completed` (bool), `app_terms_accepted` (bool), `app_analytics_opted_in` (bool).

## Best practices & patterns

- Always await `sharedPreferencesProvider.future` during app startup if you rely on preferences being initialized.
- When updating more than one pref that should be considered a single operation, update all keys then call `notifyListeners()` once (the current class already calls it in setters). Avoid doing multiple isolated writes in rapid succession when possible.
- Prefer using the typed helpers (`saveThemeMode`, `saveCurrentProject`, etc.) instead of calling `prefs.setString` directly. The helpers keep related keys (and legacy compatibility) synchronized.
- Avoid storing large blobs or binary data in SharedPreferences — keep those on disk and store references/paths in prefs.

## Migration & compatibility notes

- Key renames: If you rename a key in code, add migration logic at startup to read the old key, write the new key, and delete the old key to avoid data loss for existing users.
- Schema upgrades: Prefer additive changes to keys. When deprecating keys, leave read helpers that fallback gracefully so older stored values don't cause crashes.

## Troubleshooting & FAQ

Q: My widget reads `prefs.currentProjectPath` but gets an empty string on cold start.

A: Ensure you awaited `sharedPreferencesProvider.future` before accessing `prefsProvider`. During early bootstrap `Prefs.initPrefs()` may still be awaiting the SharedPreferences instance.

Q: I deleted a project folder on disk but the app still shows it in the UI.

A: Use the `_loadProjectsFromDisk()` flow implemented in `HomeScreen` which enumerates the `projects` directory. Also confirm that `projectsRoot()` returns the same directory your file operations target. When deleting a project remove both the folder and any Prefs keys referencing it (`current_project_id`, `editor_current_project`, `editor_current_file`).

Q: Where are plugin API keys stored?

A: API keys are stored securely in `FlutterSecureStorage` under `plugin_<pluginId>_api_key`. A boolean mirror `plugin_<pluginId>_has_api_key` exists in SharedPreferences for fast synchronous checks.

## Appendix: full key list (alphabetical)

Below is a practical, near-exhaustive list of keys that `Prefs` reads/writes. Use this list when searching or migrating keys.

- app_first_install_date (String ISO8601)
- app_last_known_route (String)
- app_last_opened_project (String)
- app_last_opened_project_time (String ISO8601)
- app_onboarding_completed (bool)
- app_session_start_time (String ISO8601)
- app_terms_accepted (bool)
- build_number (String) / stored as `app_build_number` (String)
- editor_current_content (String)
- editor_current_file (String)
- editor_current_project (String)
- editor_font_family (String)
- editor_font_size (double)
- editor_line_numbers (String/bool depending on usage)
- editor_minimap_enabled (bool)
- editor_monaco_theme (String)
- editor_auto_save (bool)
- editor_auto_save_delay (int)
- editor_format_on_save (bool)
- plugins_enabled (List<String>)
- plugin_<pluginId>_<configKey> (primitive)
- plugin_<pluginId>_has_api_key (bool)
- plugin_<pluginId>_api_key (secure storage)
- theme_app_font_family (String)
- theme_app_font_size (double)
- theme_background_color (int)
- theme_button_style (String)
- theme_custom_name (String)
- theme_elevation_level (double)
- theme_error_color (int)
- theme_heading_font_scale (double)
- theme_primary_color (int)
- theme_secondary_color (int)
- theme_surface_color (int)
- theme_ui_density (String)
- theme_mode (String: dark|light|system)

## Notes & final recommendations

- Keep `Prefs` as the single canonical place for reading/writing app preferences. This reduces accidental key naming differences and makes migrations simpler.
- Consider adding unit tests that assert keys are preserved during refactors and that migration helpers move old keys to new names.
- If you plan to store larger state (project content, file contents), prefer writing to the app documents directory and storing paths in `Prefs`.

If you'd like, I can:

- Generate a programmatic reference table that maps every getter/method to the concrete SharedPreferences key and type.
- Add example migration code for renaming a key.
- Add a short developer checklist for onboarding contributors to the `Prefs` system.
