import 'dart:io';
import 'package:rzv/providers/shared_preferences_provider.dart';

String getCurrentLanguageCode() {
  String? locale = Prefs().locale?.toLanguageTag();

  locale ??= Platform.localeName;

  if (locale.startsWith('zh_Hans') || locale.startsWith('zh-CN')) {
    return 'zh-CN';
  } else if (locale.startsWith('zh_Hant') ||
      locale.startsWith('zh-TW') ||
      locale.startsWith('zh-HK')) {
    return 'zh-TW';
  } else {
    return Platform.localeName.split('_')[0];
  }
}