import 'package:flutter/material.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: Container(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(L10n.of(context).helloWorld),
        
      ),
      body: Center(
        child: Text(L10n.of(context).hello('Bilal')),
      ),
    );
  }
}