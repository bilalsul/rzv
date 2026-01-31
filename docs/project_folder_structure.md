# Project structure (rzv)

This file documents the actual layout of the `rzv` Flutter module in this repository. Use it as a quick reference when navigating the codebase.

- [Project structure (git\_explorer\_mob)](#project-structure-rzv)
  - [Top-level layout](#top-level-layout)
  - [Key files](#key-files)
  - [`lib/` layout (application code)](#lib-layout-application-code)
  - [Notable directories and roles](#notable-directories-and-roles)
  - [Testing](#testing)
  - [Development notes \& conventions](#development-notes--conventions)

## Top-level layout

rzv/
├── .dart_tool/                  # Dart/Flutter tool cache (generated)
├── android/                     # Android native project
├── ios/                         # iOS native project
├── linux/                       # Linux artifacts and CMake files
├── macos/                       # macOS native project
├── web/                         # Web entry (index.html, manifest)
├── windows/                     # Windows native project
├── build/                       # Build outputs
├── docs/                        # Documentation (this file, others)
├── lib/                         # Main Flutter app code (see below)
├── test/                        # Unit, widget, integration tests
├── pubspec.yaml                 # Flutter package manifest
├── pubspec.lock                 # Locked dependency versions
├── l10n.yaml                    # Flutter localization configuration
├── analysis_options.yaml        # Lint / analyzer configuration
├── README.md                    # High-level project README
└── rzv.iml         # IDE project file

## Key files

- `pubspec.yaml` — declares package name, dependencies, assets, and l10n settings.
- `l10n.yaml` — controls Flutter's gen-l10n behavior (output location, template ARB, etc.).
- `README.md` — high-level introduction and developer notes.

## `lib/` layout (application code)

The primary application code lives in `lib/`. The repository uses a feature- and purpose-oriented layout.

lib/
├── app/            # App-level composition widgets, top-level app shell
├── data/           # Data sources and helpers used by the app
├── enums/          # Shared enums used across features
├── l10n/           # ARB files and generated localization artifacts
├── main.dart       # App entrypoint (runs the Flutter app)
├── models/         # Data models and plain Dart classes
├── providers/      # Riverpod providers and state singletons (Prefs provider, etc.)
├── screens/        # Top-level screens (Home, Editor, Settings, etc.)
├── services/       # Service classes (file access, git helpers, etc.)
├── utils/          # Utility helpers, formatters, and misc helpers
├── views/          # Reusable view fragments, smaller than screens
└── widgets/        # Reusable widgets

## Notable directories and roles

- `lib/providers/` — Contains the `Prefs` provider (`shared_preferences_provider.dart`) which centralizes app settings and the Riverpod wiring used across the app.
- `lib/screens/` — Hosts major UI screens such as the Home/projects browser, Editor, Settings, and other app flows.
- `lib/l10n/` — Stores ARB files (`app_en.arb`, `app_es.arb`) and the generated L10n classes used for i18n.
- `lib/services/` — File-system and archive handling (zip extraction), permission helpers, and other cross-cutting services.

## Testing

- Unit and widget tests are under `test/`. Run tests with `flutter test`.

## Development notes & conventions

- The project uses Riverpod for state management and exposes key singletons via providers in `lib/providers/`.
- Persistent settings are stored via `SharedPreferences` (wrapped in `Prefs`) and secure values in `FlutterSecureStorage`.
- Projects and imported ZIP contents are stored under the app documents `projects` directory (returned by `Prefs.projectsRoot()`).
- Localization is driven by ARB files in `lib/l10n/` and configured through `l10n.yaml`.

If you'd like, I can also generate:

- A flattened file tree (for a chosen subfolder) for quick browsing.
- An ER-style diagram of the major providers and service relationships.
