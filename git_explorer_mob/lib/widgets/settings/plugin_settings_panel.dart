import 'package:flutter/material.dart';

/// A simple container that conditionally shows child settings when visible.
class PluginSettingsPanel extends StatelessWidget {
  final String title;
  final bool visible;
  final Widget child;

  const PluginSettingsPanel({super.key, required this.title, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}
