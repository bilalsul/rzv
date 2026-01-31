import 'dart:io';

class EnvVar {
  // static const bool isAppStore =
      // String.fromEnvironment('isAppStore', defaultValue: 'false') == 'true';

  static const bool isPlayStore =
      String.fromEnvironment('isPlayStore', defaultValue: 'false') == 'true';
  // static const bool isFdroid =
      // String.fromEnvironment('isFdroid', defaultValue: 'false') == 'true';

  static bool get _isChineseMainlandLocale =>
      Platform.localeName == 'zh_Hans_CN';

  static bool get isStoreBuild => isPlayStore;
  // static bool get isStoreBuild => isAppStore || isPlayStore;

  // static bool get enableCheckUpdate => !isStoreBuild && !isFdroid;
  static bool get enableCheckUpdate => !isStoreBuild;

  static bool get enableDonation => !isStoreBuild;
  static bool get enableInAppPurchase => isStoreBuild;

  // static bool get showBeian => isAppStore && _isChineseMainlandLocale;
  static bool get showBeian => _isChineseMainlandLocale;
 
  // static bool get enableOpenAiConfig => !showBeian;
  static bool get showTelegramLink => !showBeian;
}