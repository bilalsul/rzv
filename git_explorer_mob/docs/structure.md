# structure

git-explorer/
├── android/                  # Android-specific native code
├── ios/                      # iOS-specific native code
├── web/                      # Web-specific configuration (if targeting web)
├── lib/                      # Main Flutter source code
│   ├── core/                 # Core utilities and shared functionality
│   │   ├── constants/        # App-wide constants (e.g., API keys, colors)
│   │   │   ├── api.dart
│   │   │   ├── colors.dart
│   │   │   └── strings.dart
│   │   ├── di/              # Dependency Injection (e.g., using get_it or injectable)
│   │   │   └── setup.dart
│   │   ├── error/           # Custom error types and handling
│   │   │   ├── exceptions.dart
│   │   │   └── failure.dart
│   │   ├── extensions/      # Dart extensions (e.g., String, Context)
│   │   │   └── extensions.dart
│   │   ├── network/         # Network configuration (e.g., HTTP client)
│   │   │   ├── api_client.dart
│   │   │   └── network_info.dart
│   │   └── utils/           # General utilities (e.g., logging, helpers)
│   │       ├── logger.dart
│   │       └── helpers.dart
│   ├── features/             # Feature-specific modules
│   │   ├── auth/            # GitHub authentication
│   │   │   ├── data/        # Data layer (API, local storage)
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   │   └── auth_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── auth_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/      # Business logic
│   │   │   │   ├── entities/
│   │   │   │   │   └── auth_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── login_with_github.dart
│   │   │   └── presentation/ # UI and state management
│   │   │       ├── blocs/
│   │   │       │   └── auth_bloc.dart
│   │   │       ├── pages/
│   │   │       │   └── login_page.dart
│   │   │       └── widgets/
│   │   │           └── github_login_button.dart
│   │   ├── github/          # GitHub repository and download management
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── github_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── repo_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── github_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── repo_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── github_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── fetch_repos.dart
│   │   │   │       └── download_repo.dart
│   │   │   └── presentation/
│   │   │       ├── blocs/
│   │   │       │   └── github_bloc.dart
│   │   │       ├── pages/
│   │   │       │   └── repo_list_page.dart
│   │   │       └── widgets/
│   │   │           └── repo_card.dart
│   │   ├── file_management/ # File extraction and storage
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── file_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── file_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── file_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── file_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── file_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── extract_zip.dart
│   │   │   │       └── list_files.dart
│   │   │   └── presentation/
│   │   │       ├── blocs/
│   │   │       │   └── file_bloc.dart
│   │   │       ├── pages/
│   │   │       │   └── file_explorer_page.dart
│   │   │       └── widgets/
│   │   │           └── file_tree.dart
│   │   ├── editor/          # Code editor functionality
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── editor_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── editor_state_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── editor_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── editor_state_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── editor_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── load_file_content.dart
│   │   │   │       └── save_file.dart
│   │   │   └── presentation/
│   │   │       ├── blocs/
│   │   │       │   └── editor_bloc.dart
│   │   │       ├── pages/
│   │   │       │   └── editor_page.dart
│   │   │       └── widgets/
│   │   │           ├── code_editor.dart
│   │   │           └── editor_toolbar.dart
│   │   ├── settings/        # App settings (themes, editor preferences)
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── settings_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── settings_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── settings_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── settings_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── settings_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── update_theme.dart
│   │   │   │       └── update_font_size.dart
│   │   │   └── presentation/
│   │   │       ├── blocs/
│   │   │       │   └── settings_bloc.dart
│   │   │       ├── pages/
│   │   │       │   └── settings_page.dart
│   │   │       └── widgets/
│   │   │           └── theme_selector.dart
│   │   └── legal/           # Terms of service, privacy policy
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   └── legal_datasource.dart
│   │       │   ├── models/
│   │       │   │   └── legal_model.dart
│   │       │   └── repositories/
│   │       │       └── legal_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   └── legal_entity.dart
│   │       │   ├── repositories/
│   │       │   │   └── legal_repository.dart
│   │       │   └── usecases/
│   │       │       └── fetch_terms.dart
│   │       └── presentation/
│   │           ├── blocs/
│   │           │   └── legal_bloc.dart
│   │           ├── pages/
│   │           │   ├── terms_page.dart
│   │           │   └── privacy_policy_page.dart
│   │           └── widgets/
│   │               └── legal_content.dart
│   ├── i18n/                # Internationalization and localization
│   │   ├── l10n/            # Generated localization files
│   │   │   ├── app_en.arb
│   │   │   └── app_es.arb
│   │   └── localization.dart # Localization setup and utilities
│   ├── navigation/           # App navigation (e.g., using go_router)
│   │   ├── routes.dart
│   │   └── router.dart
│   ├── theme/               # App-wide theming
│   │   ├── app_theme.dart
│   │   └── colors.dart
│   ├── widgets/             # Reusable widgets
│   │   ├── custom_button.dart
│   │   └── loading_indicator.dart
│   └── main.dart            # App entry point
├── assets/                  # Static assets
│   ├── images/
│   ├── fonts/
│   └── legal/               # Terms and privacy policy files
│       ├── terms.md
│       └── privacy_policy.md
├── test/                    # Tests
│   ├── unit/
│   │   ├── auth_test.dart
│   │   └── github_test.dart
│   ├── widget/
│   │   └── editor_page_test.dart
│   └── integration/
│       └── app_test.dart
├── scripts/                 # Build and automation scripts
│   └── generate_l10n.sh
├── pubspec.yaml             # Dependencies and metadata
├── analysis_options.yaml    # Linter rules
├── .gitignore               # Git ignore rules
├── README.md                # Project documentation
├── CHANGELOG.md             # Version history
└── .github/                 # CI/CD configuration
    ├── workflows/
    │   ├── build.yml
    │   └── test.yml
