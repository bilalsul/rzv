import 'package:flutter/material.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/utils/theme_mode_to_string.dart';
import 'package:git_explorer_mob/widgets/common/gitr_segmented_button.dart';

class ChangeThemeMode extends StatefulWidget {
  const ChangeThemeMode({super.key});
  
  @override
  _ChangeThemeModeState createState() => _ChangeThemeModeState();
}

class _ChangeThemeModeState extends State<ChangeThemeMode> {
  late String _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = themeModeToString(Prefs().themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return GitrSegmentedButton<String>(
      segments: <SegmentButtonItem<String>>[
        SegmentButtonItem(
          value: 'auto',
          label: L10n.of(context).settingsSystemMode,
          icon: const Icon(Icons.brightness_auto),
        ),
        SegmentButtonItem(
          value: 'dark',
          label: L10n.of(context).settingsDarkMode,
          icon: const Icon(Icons.brightness_2),
        ),
        SegmentButtonItem(
          value: 'light',
          label: L10n.of(context).settingsLightMode,
          icon: const Icon(Icons.brightness_5),
        ),
      ],
      selected: {_themeMode},
      onSelectionChanged: (Set<String> newSelection) {
        final String mode = newSelection.first;
        Prefs().saveThemeMode(mode);
        setState(() {
          _themeMode = mode;
        });
        },
    );
  }
}