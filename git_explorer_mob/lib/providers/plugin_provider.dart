/*
  Plugin provider implementation disabled.

  This file previously exposed Riverpod providers for plugin state
  (enabled plugin list and per-plugin configs). The project has been
  migrated to rely on `Prefs` (in `shared_preferences_provider.dart`) as
  the single source of truth. To avoid accidental usage of the old
  providers this file's implementation has been commented out.

  If you need to re-enable the provider-based approach revert this
  change and restore the original implementation.
*/
