# Cross-cutting notes

## Providers & Prefs

- `sharedPreferencesProvider` (FutureProvider<SharedPreferences>) — ensures prefs ready on startup.
- `prefsProvider` (ChangeNotifierProvider<Prefs>) — central source of truth for flags, theme, editor prefs and session info.
- Use `ref.watch(prefsProvider)` when you need to rebuild on any prefs change.
    Use `ref.read` or `ref.select` to read values without rebuilding.

## Asynchronous patterns & lifecycle

- Never perform blocking work inside widget build methods. Use post-frame callbacks or microtasks for async side-effects triggered by UI events.
- When using `ref.listen`, ensure the listener is synchronous and schedule async work with `Future.microtask` to respect Riverpod rules.

## Testing & automation

- Unit test providers (Prefs, AppStateNotifier) separately from widgets.
- Widget tests: pumpWidget with mocked Prefs by overriding `prefsProvider`.
- Integration tests: use `flutter_driver` or `integration_test` to exercise permission flows, zip import and editor saving behavior.

## Accessibility & localization

- All user-facing strings must be in ARB files and accessed via the generated
    `L10n` class.
- Use semantic labels on interactive icons and ensure tappable areas are at
    least 44x44 logical pixels.

## Extension points for plugins

- Plugins are primarily UI-level feature flags that toggle visibility of screens and toolbar buttons. For deep plugin integration, expose clearly defined extension points (e.g., EditorOverlay, Drawer plugin settings area) and document the contract (input props, expected return widgets).

## Appendix: checklist for modifying screens

- Add a provider test for any state changes you introduce.
- Add widget tests for visible UI behavior (button toggles, import flow).
- Verify localization entries for any new strings.
- Run `flutter analyze` and `flutter test` before merging.
