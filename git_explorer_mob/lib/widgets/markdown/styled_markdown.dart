import 'package:git_explorer_mob/widgets/markdown/selection_control.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// A custom Markdown widget with theme-aware styling.
/// This widget provides better contrast and readability in both light and dark modes,
/// especially for blockquotes and code blocks that appear in AI chat responses.
class StyledMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;

  const StyledMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SelectableRegion(
      selectionControls: selectionControls(),
      child: GptMarkdown(data,
          followLinkColor: true,
          onLinkTap: (href, text) => launchUrlString(href),
          linkBuilder: (context, text, url, style) => Text.rich(
                text,
                style: style.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              )),
    );
  }
}