import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/app/app_shell.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/utils/get_path/get_base_path.dart';
import 'package:git_explorer_mob/utils/error/common.dart';
import 'package:git_explorer_mob/utils/log/common.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart' as provider;

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
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
    maskColor: Colors.black.withAlpha(35),
    useAnimation: true,
    animationType: SmartAnimationType.centerFade_otherSlide,
  );

  // runApp(const MyApp());
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );  
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

   @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with WidgetsBindingObserver, WindowListener {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // windowManager.addListener(this);
  }

@override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> onWindowMoved() async {
    await _updateWindowInfo();
  }

  @override
  Future<void> onWindowResized() async {
    await _updateWindowInfo();
  }

Future<void> _updateWindowInfo() async {
    if (!Platform.isWindows) {
      return;
    }
    final windowOffset = await windowManager.getPosition();
    final windowSize = await windowManager.getSize();

    // Prefs().windowInfo = WindowInfo(
    //   x: windowOffset.dx,
    //   y: windowOffset.dy,
    //   width: windowSize.width,
    //   height: windowSize.height,
    // );
    GitExpLog.info('onWindowClose: Offset: $windowOffset, Size: $windowSize');
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<Prefs>(
          create: (_) => Prefs(),
        ),
      ],
      child: provider.Consumer<Prefs>(
        builder: (context, prefsNotifier, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
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
            title: 'Git Explorer',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const AppShell()
          );
        },
      ),
    );
  }
}

