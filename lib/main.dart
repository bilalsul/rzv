// import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:rzv/app/app_shell_3.dart';
import 'package:rzv/l10n/generated/L10n.dart';
import 'package:rzv/providers/shared_preferences_provider.dart';
import 'package:rzv/utils/get_path/get_base_path.dart';
import 'package:rzv/utils/error/common.dart';
import 'package:rzv/utils/log/common.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
// import 'package:window_manager/window_manager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs().initPrefs();
  // if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
  //   await windowManager.ensureInitialized();
  //   final size = Size(
  //     Prefs().windowInfo.width,
  //     Prefs().windowInfo.height,
  //   );
  //   final offset = Offset(
  //     Prefs().windowInfo.x,
  //     Prefs().windowInfo.y,
  //   );

  //   WindowManager.instance.setTitle('Git Explorer');
  //   if (size.width > 0 && size.height > 0) {
  //     await WindowManager.instance.setPosition(offset);
  //     await WindowManager.instance.setSize(size);
  //   }
  //   await WindowManager.instance.show();
  //   await WindowManager.instance.focus();
  // }

  initBasePath();
  GitExpLog.init();
  GitExpError.init();

  SmartDialog.config.custom = SmartConfigCustom(
    // maskColor: Colors.black.withAlpha(35),
    // maskColor: prefs.secondaryColor,
    useAnimation: true,
    animationType: SmartAnimationType.centerFade_otherSlide,
  );

  // runApp(const MyApp());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Prefs>(create: (_) => Prefs()),
      ],
      child: const ProviderScope(child: MyApp()),
      // child: const MyApp(),
    ),
  );
}

Locale? getEffectiveLocale(Prefs prefs, List<Locale> supportedLocales) {
  // Get the locale from prefs
  Locale? storedLocale = prefs.locale;
  
  if (storedLocale != null) {
    // If user has explicitly selected a locale, respect it
    return storedLocale;
  }
  
  // Get system locale
  Locale systemLocale = WidgetsBinding.instance.window.locale;
  
  // Check if system locale is supported
  bool isSystemLocaleSupported = supportedLocales.any((supportedLocale) => 
      supportedLocale.languageCode == systemLocale.languageCode &&
      (supportedLocale.countryCode == null || 
       supportedLocale.countryCode == systemLocale.countryCode)
  );
  
  if (isSystemLocaleSupported) {
    return systemLocale;
  } else {
    // Default to English if system locale is not supported
    return const Locale('en');
  }
}
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  //   // windowManager.addListener(this);
  // }

  // @override
  // void dispose() {
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }

  // @override
  // Future<void> onWindowMoved() async {
  //   await _updateWindowInfo();
  // }

  // @override
  // Future<void> onWindowResized() async {
  //   await _updateWindowInfo();
  // }

  // Future<void> _updateWindowInfo() async {
  //     if (!Platform.isWindows) {
  //       return;
  //     }
  //     final windowOffset = await windowManager.getPosition();
  //     final windowSize = await windowManager.getSize();

  //     // Prefs().windowInfo = WindowInfo(
  //     //   x: windowOffset.dx,
  //     //   y: windowOffset.dy,
  //     //   width: windowSize.width,
  //     //   height: windowSize.height,
  //     // );
  //     GitExpLog.info('onWindowClose: Offset: $windowOffset, Size: $windowSize');
  //   }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: prefs.getEffectiveLocale(prefs, L10n.supportedLocales),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      // scrollBehavior: ScrollConfiguration.of(context).copyWith(
      //   physics: const BouncingScrollPhysics(),
      //   // dragDevices: {
      //   //   PointerDeviceKind.touch,
      //   //   PointerDeviceKind.mouse,
      //   // },
      // ),
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
      navigatorKey: navigatorKey,
      // theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: prefs.themeMode,
      title: 'Gzip Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: prefs.accentColor),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
