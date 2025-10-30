import 'package:flutter/material.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';

class TemplateScreen extends StatelessWidget {
  final String screen;
  const TemplateScreen({super.key, required this.screen });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(screen),
    );
  }
}