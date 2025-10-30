# packages

```yaml
name: git-explorer
description: A mobile code editor for viewing and editing local codebases. DOESNT SUPPORT git !
version: 1.0.0
environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  http: ^1.2.2
  flutter_web_auth_2: ^3.0.2
  flutter_secure_storage: ^9.2.2
  archive: ^3.6.1
  path_provider: ^2.1.4
  file_picker: ^8.1.2
  flutter_code_editor: ^0.3.1
  webview_flutter: ^4.9.0
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  go_router: ^14.3.0
  intl: ^0.19.0
  flutter_markdown: ^0.7.3
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8
  firebase_core: ^3.4.0
  firebase_analytics: ^11.3.0
  firebase_crashlytics: ^4.1.0
  sentry_flutter: ^8.9.0
  logger: ^2.4.0
  get_it: ^7.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  bloc_test: ^9.1.7
  integration_test:
    sdk: flutter
  test: ^1.25.8
  build_runner: ^2.4.12
  mocktail: ^1.0.4
```

## Loggers

```dart
final logger = Logger();
logger.v('You don\'t always want to see all of these');
logger.d('Logs a debug message');
logger.i('Public Function called');
logger.w('This might become a problem');
logger.e('Something has happened');
```

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  cupertino_icons: ^1.0.6
  file_picker: ^9.0.2
  path_provider: ^2.1.2
  image: ^4.3.0
  sqflite: ^2.3.2
  path: ^1.9.0
  shared_preferences: ^2.2.2
  provider: ^6.1.2
  flutter_gen_runner: ^5.4.0
  intl: 0.20.2
  flutter_colorpicker: ^1.0.3
  html: ^0.15.4
  flutter_html: ^3.0.0-beta.2
  archive: ^3.6.1
  flutter_inappwebview: 
    git:
      url: https://github.com/Anxcye/flutter_inappwebview.git
      ref: 4a275c3
      path: flutter_inappwebview
  shelf: ^1.4.1
  fl_chart: ^0.70.2
  graphview: ^1.3.2
  flutter_rating_bar: ^4.0.1
  permission_handler: ^11.3.1
  webdav_client:
    git:
      url: https://github.com/Anxcye/webdav_client.git
  fluttertoast: ^8.2.6
  dio: ^5.4.3+1
  pubspec_parse: ^1.2.3
  logging: ^1.2.0
  flutter_file_dialog: ^3.0.2
  contentsize_tabbarview:
    git:
      url: https://github.com/Anxcye/contentsize_tabbarview.git
      ref: feat/animation
  wakelock_plus: ^1.2.5
  icons_plus: ^5.0.0
  url_launcher: ^6.2.6
  sqflite_common_ffi: ^2.3.3
  battery_plus: ^6.2.1
  flutter_tts:
    git:
      url: https://github.com/Anxcye/flutter_tts.git
      ref: master
  sticky_headers: ^0.3.0+2
  photo_view: ^0.15.0
  flutter_smart_dialog: ^4.9.8+1
  saver_gallery: ^4.0.1
  share_plus: ^11.1.0
  device_info_plus: ^11.3.2
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  chinese_font_library: ^1.2.0
  flex_color_scheme: ^8.3.0
  sqlite3_flutter_libs: ^0.5.26
  flutter_reorderable_grid_view: ^5.4.0
  uuid: ^4.5.1
  desktop_drop: ^0.5.0
  audio_service: ^0.18.16
  audio_session: ^0.1.23
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0
  flutter_heatmap_calendar:
    git:
      url: https://github.com/Anxcye/flutter_heatmap_calendar
  csv: ^6.0.0
  fast_gbk: ^1.0.0
  window_manager: ^0.4.3
  pretty_dio_logger: ^1.4.0
  dio_intercept_to_curl: ^0.2.0
  flutter_gemini: ^3.0.0
  gpt_markdown: ^1.1.4
  pointer_interceptor: ^0.10.1+2
  connectivity_plus: ^6.1.3
  http: ^1.3.0
  web_socket_channel: ^3.0.2
  crypto: ^3.0.6
  audioplayers: ^6.4.0
  in_app_purchase: ^3.2.1
  asn1lib: ^1.6.2
  in_app_purchase_storekit: ^0.3.21
  charset: ^2.0.1
  flutter_slidable: ^4.0.0
  cached_network_image: ^3.4.1
  lpinyin: ^2.0.3
  mongol: ^9.0.0
  introduction_screen: ^3.1.17
  flutter_floating_bottom_bar: ^1.3.0
  langchain: ^0.7.9
  langchain_anthropic: ^0.2.1+3
  langchain_google: ^0.6.5+2
  langchain_openai:
    git:
      url: https://github.com/Anxcye/langchain_dart.git
      ref: bb06c17ca667a906e3e37154b0bda95023d0c9bd
      path: packages/langchain_openai
  langchain_core: ^0.3.9
  skeletonizer: ^2.1.0+1
  scrollable_positioned_list: ^0.3.8
  math_expressions: ^2.5.0
  share_handler: ^0.0.25
  volume_key_board: ^0.0.1

dependency_overrides:
  openai_dart:
    git:
      url: https://github.com/Anxcye/langchain_dart.git
      ref: bb06c17ca667a906e3e37154b0bda95023d0c9bd
      path: packages/openai_dart
  

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  test: any
  build_runner: ^2.4.13
  custom_lint: ^0.7.5
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  freezed: ^3.0.2
  json_serializable: ^6.9.0
#  flutter_launcher_icons: ^0.11.0


flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/fonts/SourceHanSerifSC-Regular.otf
    - pubspec.yaml
    - assets/foliate-js/index.html
    - assets/foliate-js/dist/
    # - assets/foliate-js/vendor/
    - assets/foliate-js/src/vendor/pdfjs/
    - assets/foliate-js/src/
    - assets/foliate-js/src/vendor/
    - assets/images/
    - assets/images/book_share/
    - assets/images/bgimg/
    - assets/icon/
    - assets/CHANGELOG.md

  fonts:
    - family: SourceHanSerif
      fonts:
        - asset: assets/fonts/SourceHanSerifSC-Regular.otf
          weight: 400
        - asset: assets/fonts/SourceHanSerifSC-Bold.otf
          weight: 700
```
