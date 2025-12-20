# Changelog

## 0.0.14
- Feat: Support setting up both secondary and accent colors in onboarding
- Fix: Support Dark mode for Onboarding users
- Fix: Support Dark mode for About Gzip Explorer in Settings
- Fix: Theme Customizer not showing current selected theme
- Clean: Removed features that have broken links yet. Will be added when they are fully supported

## 0.0.12
- Feat: Added app onboarding explaining app's purpose
- Feat: Added App About in settings
- Clean: Added a way to detect where new app instance start should take you.

## 0.0.11
- Fix: detect device language, not supported? show english by default.

## 0.0.10
- Fix: Cleaned plugin definitions from breakage
- Clean: Removed unused packages and minimized app size from bloating user's device.

## 0.0.8
- Feat: Added home action buttons (delete all projects, refresh)
- Feat: Unfocus popping up keyboard on editor screen
- Fix: Fixed not working markdown previewer in home screen
- Feat: Added button to open current markdown in editor
- Fix: Fixed not working refresh projects action button
- Fix: Updated cached home screen and cached editor screen to not rebuild fully
- Fix: Cleaned up broken scroll controller breaking app internal

## 0.0.7
- UI: Cleaned up settings screen UI
- UI: Enhanced theme selector and language selector widgets
- UI: Updated legacy BottomNavigationBar with scroll detection
- Feat: Added font family selector
- UI: Improved floating action buttons alignment

## 0.0.6
- Feat: Cleaned up hardcoded feature disabled and feature not supported screens localizations
- Feat: Added supported features list
- Feat: Added zoom in/out changing editor font size
- Feat: Added font family options
- Feat: Updated empty editor file placeholder message
- Feat: Render unsupported characters in editor with warning bell
- Feat: Implemented app about and send feedback with URL navigation

## 0.0.4
- Feat: Placed native ads placeholders in settings and app-drawer
- Feat: Added Italian language support
- Feat: Added Turkish language support
- Feat: Added Portuguese language support
- Feat: Added Russian language support
- Feat: Added Japanese language support
- Feat: Added Korean language support
- Feat: Added Chinese language variants support

## 0.0.2
- UI: Added loading indicator to remove empty state flashing
- Feat: Added theme customization support
- Fix: Updated release pipeline to release app for different Android platforms

## 0.0.1
- Feat: Added timer that tracks when current project was last opened
- Feat: Fixed i18n support issue
- Feat: Supported localization for home and settings screens
- Fix: Fixed MaterialApp not rebuilding when language is changed
- Feat: Supported app_drawer localization
- Feat: Fixed unzipping archives and showing them from file
- Feat: Added MonacoEditor to editor
- Feat: Added French language support
- Feat: Added German language support
- Feat: Added Arabic language support
- Docs: Updated widget hierarchy and project structure documentation
- UI: Added branding app icon