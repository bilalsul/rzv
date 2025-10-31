
/*
  Navigation provider implementation disabled.

  Navigation was previously provided via Riverpod (currentScreenProvider,
  NavigationSettings). The application now reads navigation state from
  `Prefs` (see `shared_preferences_provider.dart`) and the UI components
  manage navigation locally (for example, `AppShell` uses `Prefs().lastKnownScreen`).

  The original provider code is commented out to avoid accidental usage.
*/