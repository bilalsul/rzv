import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings {
  final String themeMode;
  final String customThemeName;
  final int primaryColor;
  final int secondaryColor;
  final int backgroundColor;
  final int surfaceColor;
  final int errorColor;
  final String uiDensity;
  final String buttonStyle;
  final double borderRadius;
  final double elevationLevel;
  final String appFontFamily;
  final double appFontSize;
  final double headingFontScale;
  final double codeFontScale;
  final double animationSpeed;
  final bool reduceAnimations;
  final bool rippleEffect;

  const ThemeSettings({
    this.themeMode = 'system',
    this.customThemeName = 'default_custom',
    this.primaryColor = 0xFF2196F3,
    this.secondaryColor = 0xFFFF9800,
    this.backgroundColor = 0xFF121212,
    this.surfaceColor = 0xFF1E1E1E,
    this.errorColor = 0xFFCF6679,
    this.uiDensity = 'comfortable',
    this.buttonStyle = 'elevated',
    this.borderRadius = 8.0,
    this.elevationLevel = 2.0,
    this.appFontFamily = 'Roboto',
    this.appFontSize = 14.0,
    this.headingFontScale = 1.5,
    this.codeFontScale = 1.0,
    this.animationSpeed = 1.0,
    this.reduceAnimations = false,
    this.rippleEffect = true,
  });

  ThemeSettings copyWith({
    String? themeMode,
    String? customThemeName,
    int? primaryColor,
    int? secondaryColor,
    int? backgroundColor,
    int? surfaceColor,
    int? errorColor,
    String? uiDensity,
    String? buttonStyle,
    double? borderRadius,
    double? elevationLevel,
    String? appFontFamily,
    double? appFontSize,
    double? headingFontScale,
    double? codeFontScale,
    double? animationSpeed,
    bool? reduceAnimations,
    bool? rippleEffect,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      customThemeName: customThemeName ?? this.customThemeName,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      errorColor: errorColor ?? this.errorColor,
      uiDensity: uiDensity ?? this.uiDensity,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      elevationLevel: elevationLevel ?? this.elevationLevel,
      appFontFamily: appFontFamily ?? this.appFontFamily,
      appFontSize: appFontSize ?? this.appFontSize,
      headingFontScale: headingFontScale ?? this.headingFontScale,
      codeFontScale: codeFontScale ?? this.codeFontScale,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      rippleEffect: rippleEffect ?? this.rippleEffect,
    );
  }

  static ThemeSettings fromPreferences(SharedPreferences prefs) {
    return ThemeSettings(
      themeMode: prefs.getString('theme_mode') ?? 'system',
      customThemeName: prefs.getString('theme_custom_name') ?? 'default_custom',
      primaryColor: prefs.getInt('theme_primary_color') ?? 0xFF2196F3,
      secondaryColor: prefs.getInt('theme_secondary_color') ?? 0xFFFF9800,
      backgroundColor: prefs.getInt('theme_background_color') ?? 0xFF121212,
      surfaceColor: prefs.getInt('theme_surface_color') ?? 0xFF1E1E1E,
      errorColor: prefs.getInt('theme_error_color') ?? 0xFFCF6679,
      uiDensity: prefs.getString('theme_ui_density') ?? 'comfortable',
      buttonStyle: prefs.getString('theme_button_style') ?? 'elevated',
      borderRadius: prefs.getDouble('theme_border_radius') ?? 8.0,
      elevationLevel: prefs.getDouble('theme_elevation_level') ?? 2.0,
      appFontFamily: prefs.getString('theme_app_font_family') ?? 'Roboto',
      appFontSize: prefs.getDouble('theme_app_font_size') ?? 14.0,
      headingFontScale: prefs.getDouble('theme_heading_font_scale') ?? 1.5,
      codeFontScale: prefs.getDouble('theme_code_font_scale') ?? 1.0,
      animationSpeed: prefs.getDouble('theme_animation_speed') ?? 1.0,
      reduceAnimations: prefs.getBool('theme_reduce_animations') ?? false,
      rippleEffect: prefs.getBool('theme_ripple_effect') ?? true,
    );
  }

  Future<void> saveToPreferences(SharedPreferences prefs) async {
    await prefs.setString('theme_mode', themeMode);
    await prefs.setString('theme_custom_name', customThemeName);
    await prefs.setInt('theme_primary_color', primaryColor);
    await prefs.setInt('theme_secondary_color', secondaryColor);
    await prefs.setInt('theme_background_color', backgroundColor);
    await prefs.setInt('theme_surface_color', surfaceColor);
    await prefs.setInt('theme_error_color', errorColor);
    await prefs.setString('theme_ui_density', uiDensity);
    await prefs.setString('theme_button_style', buttonStyle);
    await prefs.setDouble('theme_border_radius', borderRadius);
    await prefs.setDouble('theme_elevation_level', elevationLevel);
    await prefs.setString('theme_app_font_family', appFontFamily);
    await prefs.setDouble('theme_app_font_size', appFontSize);
    await prefs.setDouble('theme_heading_font_scale', headingFontScale);
    await prefs.setDouble('theme_code_font_scale', codeFontScale);
    await prefs.setDouble('theme_animation_speed', animationSpeed);
    await prefs.setBool('theme_reduce_animations', reduceAnimations);
    await prefs.setBool('theme_ripple_effect', rippleEffect);
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  final Ref ref;

  ThemeSettingsNotifier(this.ref) : super(const ThemeSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = ThemeSettings.fromPreferences(prefs);
  }

  Future<void> updateSettings(ThemeSettings newSettings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await newSettings.saveToPreferences(prefs);
    state = newSettings;
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = const ThemeSettings();
    await updateSettings(defaultSettings);
  }
}

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  (ref) => ThemeSettingsNotifier(ref),
);

// Convenience provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  switch (settings.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
});
