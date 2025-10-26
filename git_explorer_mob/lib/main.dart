import 'package:flutter/material.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/utils/get_path/get_base_path.dart';
import 'package:git_explorer_mob/utils/log/common.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:git_explorer_mob/views/onboarding_page/onboarding_page.dart';
import 'home_screen.dart';

int initScreen = 0;

void main() async {
  
  initBasePath();
  GitExpLog.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Git Explorer',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        
        home: HomeScreen(),
    );
  }
}

