# Git Explorer (git_explorer_mob) — Full Project Context

Generated: 2025-11-01

This document is a single, self-contained, large context file intended to capture everything a developer (or an assistant) needs to know to understand, modify, or continue work on the `git_explorer_mob` Flutter application inside the `git-explorer` workspace. Use this file as the canonical context when you ask follow-up questions or provide patches.

---

## High-level overview

- Project: Git Explorer (mobile flavor: `git_explorer_mob`)
- Tech stack: Flutter (Dart). Riverpod is used in places for reactive providers. Several key dependencies include `flutter_monaco` (editor), `flutter_secure_storage` (secure API keys), `http` (AI service), and `shared_preferences` (settings persistence). The app targets mobile and desktop (and web partially, but some features use `dart:io` and are desktop-only).
- Primary purpose: A code and repository explorer/editor with plugin system, AI chat integration, editor (Monaco) embedding, project browser/home screen, settings, and other utilities.
- Architectural pattern: Single-source-of-truth via a `Prefs` ChangeNotifier provider that centralizes feature toggles, editor settings, AI model & API key storage (secure + prefs), and small session state (open file, last route). UI widgets and screens read/write through `Prefs`.

---

## Top-level repository layout (relevant parts)

(Truncated to the parts that matter for this mobile app flavor.)

- git_explorer_mob/
  - `pubspec.yaml` — declared dependencies (e.g., `flutter_monaco`, `flutter_secure_storage`, `http`, `flutter_riverpod`).
  - android/, ios/, linux/, macos/, web/, windows/ — platform folders.
  - lib/
    - `main.dart` — app entry (wires `AppShell` / navigation).
    - `app/app_shell.dart` — main app shell, bottom navigation, AppDrawer.
    - `providers/shared_preferences_provider.dart` — `Prefs` ChangeNotifier centralizing app settings and secure API helpers.
    - `screens/`
      - `home_screen.dart` — Home/project browser, README inline viewer, file listing; navigates to editor for non-markdown files.
        - New: supports creating projects with user-provided details, importing projects from .zip archives (decoded via the `archive` package), and a helper that programmatically generates a demo .zip and imports it. Imported zips are decoded into the in-memory `fs` map used by `_Project`.
      - `editor_screen.dart` — Editor screen; uses `MonacoWrapper` widget or fallback.
      - `settings_screen.dart` — Settings with AI model selection, terminal options, theme customizer.
      - `ai_screen.dart` — Entry point for AI features; currently returns `ChatScreen`.
      - `chat_screen.dart` — Chat UI with streaming (fake or real depending on API), attachments, clipboard, quick questions.
    - `services/`
      - `ai_chat_service.dart` — AI HTTP client, streaming shim (simulates streaming for a special input "gen"), fallback to non-streaming requests.
    - `widgets/`
      - `monaco/monaco_wrapper.dart` — wrapper for `flutter_monaco` with a safe TextField fallback to keep the project buildable while mapping the Monaco API correctly.
      - `chat/chat_bubble.dart` — chat message UI and actions (copy/edit/regenerate).
    - other directories: `models/`, `utils/`, `widgets/` — usual UI and helper code.

- docs/ — contains documentation and the file created by this task: `PROJECT_FULL_CONTEXT.md`.

---

## Important files and their responsibilities (deeper)

- `lib/providers/shared_preferences_provider.dart` (Prefs)
  - Purpose: Provide a single ChangeNotifier (exposed via `prefsProvider`) that contains:
    - A `SharedPreferences` instance (`prefs.prefs`) for non-sensitive settings and persisted data.
    - Secure storage wrappers (using `flutter_secure_storage`) to store plugin API keys securely: `setPluginApiKey(pluginId, key)`, `getPluginApiKey(pluginId)`, `removePluginApiKey(pluginId)`, `hasPluginApiKey(pluginId)`.
    - Editor/session helpers: `saveCurrentOpenFile`, `currentOpenFile*`, `saveCurrentOpenFileContent`, `detectLanguageFromFilename()`.
    - Editor preferences: theme, font family, font size, tab size, line numbers, minimap on/off, auto save, format on save, etc.
    - AI-specific keys: `ai_model`, `ai_max_tokens`, `ai_temperature`, `ai_system_prompt`, and indexing keys like `ai_conversation`.
  - Usage: UI watches `prefsProvider` to rebuild on changes. The Prefs design centralizes plugin toggles and settings so previous providers (plugin_provider, navigation_provider, theme_provider) were commented-out in favor of `Prefs`.

- `lib/services/ai_chat_service.dart` (AiChatService)
  - Purpose: Minimal OpenAI-compatible client.
  - Behavior:
    - `sendMessage(String message)`: sends a non-streaming Chat Completions request to OpenAI's `v1/chat/completions` using the API key from secure storage. Reads `ai_model`, `ai_max_tokens`, and `ai_temperature` from `Prefs`.
    - `streamMessage(String message)`: streaming variant. Currently implements a streaming shim (fake streaming) when the message is exactly `gen`, otherwise verifies API key presence and calls `sendMessage` as a single yield reply.
  - Important: Real SSE-based streaming is not implemented and is noted as a possible improvement.

- `lib/screens/chat_screen.dart` (ChatScreen)
  - Purpose: Modern chat UI for AI interactions.
  - Features:
    - Centered floating input when the chat is empty; bottom-aligned input when messages exist.
    - Clipboard paste button, attach-file-by-path (desktop-only, uses `dart:io` to read files), quick-question suggestions derived from attached files or conversation.
    - Attachments show as removable chips above the input. When sending, attachments are concatenated and prepended as "CONTEXT FILES:" to the user message (with truncation to keep payload reasonable) and attachments are cleared after a successful send.
    - Stores messages to `SharedPreferences` under key `ai_conversation` as JSON-encoded list of message objects.
    - Streaming handling: listens to `AiChatService.streamMessage()` and updates an assistant placeholder message incrementally. Supports regenerate/edit/copy actions via `ChatBubble`.
  - Data model for messages in the UI: `List<Map<String, dynamic>>` where each message has fields like `id`, `role` ("user"|"assistant"), `text`, `time`, `streaming`, and optional `attachments`.

- `lib/widgets/chat/chat_bubble.dart` (ChatBubble)
  - Purpose: Visual tile for each chat message.
  - Features: selectable text, avatar (assistant uses `Icons.smart_toy`), long-press action sheet (Copy/Edit/Regenerate), timestamp display, layout variations for user vs assistant messages.

- `lib/widgets/monaco/monaco_wrapper.dart` (MonacoWrapper)
  - Purpose: Place to instantiate the `MonacoEditor` from `flutter_monaco` and map Prefs-backed settings into editor options.
  - Current state: The wrapper attempts to instantiate `MonacoEditor` but due to API mismatches the code keeps a robust fallback — a multiline `TextField` — to avoid breaking the build. This wrapper is the safe swap-in point to switch to the correct `flutter_monaco` API when its constructor/signature is mapped precisely.
  - Known action: the wrapper is intentionally left to allow incremental replacement; see the Known Issues section for details.

- `lib/screens/home_screen.dart` (Home & Project Browser)
  - Purpose: List projects/repos, show README inline for markdown files; open files in Editor for non-markdown files. When opening files, the app writes session info to Prefs so the Editor can restore the last open file.

- `lib/screens/editor_screen.dart` (EditorScreen)
  - Purpose: Host the MonacoWrapper and provide Save/format/other editor actions. Save currently triggers a snackbar and persists content to Prefs (via editor session helpers). Files opened from Home populate the editor with content and detected language via `detectLanguageFromFilename()` helper.
  - Behavior update: when the `EditorScreen` mounts it now synchronizes the Prefs state to ensure `currentOpenFile`, `currentOpenFileContent`, and `currentOpenProject` (derived from the file path) are saved via `saveCurrentOpenFile(...)`. This makes the AppDrawer header show the currently opened file and project.

- `lib/screens/settings_screen.dart` (Settings)
  - Purpose: Centralized settings UI that reads/writes to `Prefs`.
  - Features implemented: AI provider options, model selection, secure API key dialog, terminal options, theme customizer (color circles, accent color), and an Apply flow to commit theme changes. Plugin toggles were moved to the AppDrawer and persisted via Prefs.

- `lib/app/app_shell.dart` (AppShell)
  - Purpose: The main scaffold with bottom navigation, AppDrawer, and wiring to `Prefs` for plugin toggles and theme.

- `lib/widgets/common/app_drawer.dart` (AppDrawer)
  - Purpose: Drawer UI with plugin toggles and a compact header.
  - Behavior update: the header now displays the currently opened file (from `Prefs.currentOpenFile`) if present; otherwise it falls back to the last opened project. The editor writes to Prefs when files are opened so this header reflects live editor state.

---

## Data shapes and keys (canonical)

These are the canonical preference keys and message shapes used throughout the app. Use them when integrating features or reading/writing preferences to avoid duplication.

- SharedPreferences keys (non-sensitive):
  - `ai_model` (String) — e.g., `gpt-3.5-turbo`, `gpt-4`.
  - `ai_max_tokens` (int)
  - `ai_temperature` (double)
  - `ai_system_prompt` (String)
  - `ai_conversation` (String JSON) — conversation history serialized as JSON array of message objects.
  - `editor_...` keys: `editor_theme`, `editor_font_family`, `editor_font_size`, `editor_tab_size`, `editor_line_numbers` (bool), `editor_minimap_enabled` (bool), `editor_auto_save` (bool), `editor_format_on_save` (bool)
  - `lastKnownRoute` / `lastKnownScreen` (String) — for session restore.
  - Plugin toggles: e.g., `plugin_ai_enabled` (bool) — exact names vary; prefer reading `Prefs` implementation for exact key names.

- Secure storage (flutter_secure_storage):
  - Per-plugin API keys stored under e.g., `plugin_openai_api_key` (the actual key name is internal to Prefs and retrieved via `getPluginApiKey('openai')`).
  - Use `prefs.setPluginApiKey(pluginId, apiKey)` / `prefs.getPluginApiKey(pluginId)` / `prefs.removePluginApiKey(pluginId)`.

- Chat message object (internal representation held in `List<Map<String, dynamic>>`):
  - id: String (unique id, often a timestamp-based string)
  - role: String `user` | `assistant` | `system`
  - text: String
  - time: ISO8601 timestamp string
  - streaming: (optional) bool — true when assistant message is being incrementally filled
  - attachments: (optional) `List<String>` — file basenames attached to the user message

- Editor session object (in Prefs) — example fields stored by helper methods:
  - `current_open_project` (String)
  - `current_open_file_path` (String)
  - `current_open_file_content` (String)
  - `current_open_file_language` (String)

---

## How routing/navigation is done

- `AppShell` hosts bottom navigation. One tab is AI (wired to `ai_screen.dart` which returns `ChatScreen`), one tab opens the Home (projects), one opens Settings. The Home screen navigates to EditorScreen when a non-markdown file is opened.
- `Prefs` houses `lastKnownRoute` for session restoration; Home writes in the last opened file so the Editor can open on launch.

---

## Key runtime behaviors and UX details

- Chat input is a floating, rounded Material input that is centered while the conversation is empty; once messages appear, the input aligns to the bottom center. This gives a modern UX where first-time users see the input front-and-center.
- Typing `gen` into the chat input demonstrates the streaming UI by producing a fake streaming reply (the `AiChatService` yields chunked strings so the assistant placeholder message is updated progressively). Real streaming against OpenAI requires SSE/parsing.
- Attach-file-by-path is implemented for desktop using `dart:io`. The file content is read and truncated to the first ~2000 characters to avoid huge payloads. On web, the feature shows a message that insertion is unsupported.
- The `MonacoWrapper` contains a fallback `TextField` in case `flutter_monaco` API mismatches otherwise break the build. Mapping to the `MonacoEditor` constructor/options remains to be finalized.

---

## Dependencies (high-level)

Key packages (non-exhaustive); check `pubspec.yaml` for exact versions:

- flutter
- flutter_riverpod
- shared_preferences
- flutter_secure_storage
- http
- flutter_monaco
- (possibly) url_launcher, path_provider, file_picker (not yet added, but recommended for file picker UX)

---

## Known issues / TODOs / technical debt

- Monaco integration: `MonacoWrapper` currently uses a fallback `TextField` because earlier attempts to instantiate `MonacoEditor` were done with guessed constructor parameters and produced compile-time diagnostics. Action: inspect `flutter_monaco` package (pub-cache or upstream docs) and adapt the wrapper to the exact API. Then replace fallback with a live `MonacoEditor` wired to Prefs settings and an editor controller.

- Streaming: `AiChatService.streamMessage` currently fakes streaming when message == `gen`. Real streaming against OpenAI (chat completions with `stream: true`) requires capturing and parsing chunked responses or SSE and yielding incremental text. Implementing the streaming path will also require robust cancellation, backpressure handling, and safety (API key errors, partial data handling).

- File attachments: current UI asks for an absolute path typed by the user. This is not ideal UX. Suggestion: add `file_picker` (native) or platform-specific file selector. On mobile, proper file picking is recommended since absolute paths are rarely used.

- Tests: There are only a few tests (some unit tests under test/). Add integration/widget tests, at least covering chat screen happy path + attachment flow, and EditorScreen mounting fallback vs real Monaco.

- Lints and static checks: run `dart analyze` and address warnings; there remain some minor lints after iterative edits.

- Security: The app stores API keys in secure storage (good). However, when sending attachments, content is concatenated into the plaintext message payload and sent to the AI provider. Warn users before sending sensitive files. Consider allowing opt-in to redact or omit sensitive parts.

---

## Running and debugging locally

- Basic run (mobile/desktop):

```bash
# from repository root or package directory
cd git_explorer_mob
flutter pub get
flutter run -d <device>
```

- Analyze and test:

```bash
flutter analyze
flutter test
```

- If you add native dependencies (e.g., `file_picker`), run `flutter pub get` and platform-specific setup as required.

---

## Developer recommendations and next steps

Prioritized actions you may want to take next:

1. Properly wire Monaco
   - Inspect the `flutter_monaco` package version in `pubspec.lock`.
   - Import the package source (from `~/.pub-cache`) or the package docs to map the constructor and controller APIs precisely.
   - Replace the fallback `TextField` with `MonacoEditor` and map Prefs options (theme, font size, minimap, line numbers). Ensure that the editor controller can persist content back into Prefs on save or auto-save.

2. Implement real streaming
   - Implement SSE or chunked-response parsing for OpenAI streaming with cancellation and error handling. Use a StreamController to yield incremental text. Make sure to respect model/temperature/max_tokens settings from Prefs.

3. Improve attachments UX
   - Add `file_picker` (or platform-specific code) so users get a native file picker instead of typing paths.
   - Add an optional preview modal showing the first N lines or tokens of attached content. Add a confirmation checkbox if attachment may contain secrets.

4. Add tests
   - Widget tests for `ChatScreen` covering send, fake streaming, attachments, quick questions, and clipboard paste.
   - Unit tests for `AiChatService` (mock HTTP responses + streaming path) and `Prefs` behavior.

5. Lint and type-safety
   - Run `dart analyze` and address any analyzer hints.
   - Add stricter typing for message objects (create a `Message` model class with fromJson/toJson) instead of `Map<String, dynamic>` for maintainability.

6. Security and privacy
   - Add a user-facing prompt or policy when a file attachment is about to be sent to a remote AI provider.
   - Consider encryption-at-rest for more sensitive settings, or provide a toggle to opt out of uploading content to third-party services.

---

## Quick reference: code pointers

- To find the Prefs implementation: `lib/providers/shared_preferences_provider.dart`
- To modify the chat input UI: `lib/screens/chat_screen.dart`
- To adjust chat message UI or long-press actions: `lib/widgets/chat/chat_bubble.dart`
- To modify editor behavior or swap in `MonacoEditor`: `lib/widgets/monaco/monaco_wrapper.dart` and `lib/screens/editor_screen.dart`
- AI HTTP client: `lib/services/ai_chat_service.dart`

---

## Example: message lifecycle (how the UI flows on send)

1. User types text or attaches a file and clicks send.
2. `ChatScreen._send()` creates a `user` message entry (with attachments metadata) and pushes a placeholder `assistant` message with `streaming:true`.
3. The chat code calls `_service.streamMessage(finalMessage)` where `finalMessage` is `text` plus the concatenated, truncated attachment contents (prefixed with `CONTEXT FILES:`).
4. `AiChatService.streamMessage()` yields strings incrementally (for `gen`) or yields one full reply (calls `sendMessage`).
5. The stream subscriber appends each chunk to the assistant placeholder message and persists the conversation to `SharedPreferences` intermittently.
6. When stream completes, the placeholder is marked `streaming:false`; attachments are cleared.

---

## Troubleshooting hints

- If the app fails to build with Monaco-related errors: temporarily revert to the last working commit that used the `MonacoWrapper` fallback, or fix the `MonacoWrapper` by checking the `flutter_monaco` package API.
- If the chat fails with `No API key configured for OpenAI`: set the OpenAI API key via the key dialog from the AI/Chat screen or via Settings. The key is stored using `Prefs.setPluginApiKey('openai', 'sk-...')`.
- If file attachments silently fail on web: the app uses `dart:io` for file reads; this only works for desktop and may fail on web. Use a file picker plugin for cross-platform support.

---

## Appendix: project-specific constants & hints

- Special streaming demo trigger: sending the exact message `gen` triggers the fake streaming path in `AiChatService` so you can validate streaming UI without an API.
- Truncation length for file attachments: ~2000 characters (implemented to avoid excessively large messages).
- Conversation persistence key: `ai_conversation`.

---

If you want this file expanded with concrete API shapes (e.g., exact Prefs methods and their parameter names, or the exact `pubspec.yaml` dependency list), tell me which parts to embed verbatim. I can also generate a TypeScript-like spec (OpenAPI-style) for the message shapes, or produce a `README_RUN.md` with step-by-step reproduction for CI.

End of PROJECT_FULL_CONTEXT.md
