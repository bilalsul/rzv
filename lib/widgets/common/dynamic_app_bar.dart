import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rzv/enums/options/screen.dart';
import 'package:rzv/l10n/generated/L10n.dart';

class DynamicAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Screen currentScreen;

  const DynamicAppBar({
    super.key,
    required this.scaffoldKey,
    required this.currentScreen,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final prefs = ref.watch(prefsProvider);
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
      ),
      title: _buildTitle(currentScreen, context),
      // actions: _buildActions(currentScreen, context, ref),
      // backgroundColor: _getAppBarColor(currentScreen, context),
      // backgroundColor: prefs.secondaryColor,
      // elevation: _getAppBarElevation(currentScreen),
    );
  }

  Widget _buildTitle(Screen screen, BuildContext context) {
    switch (screen) {
      case Screen.home:
        return _buildText(L10n.of(context).navBarHome);
      case Screen.editor:
        return _buildText(L10n.of(context).navBarEditor);
      case Screen.fileExplorer:
        return _buildText(L10n.of(context).navBarFileExplorer);
      case Screen.gitHistory:
        return _buildText(L10n.of(context).navBarGitHistory);
      case Screen.settings:
        return _buildText(L10n.of(context).navBarSettings);
      case Screen.terminal:
        return _buildText(L10n.of(context).navBarTerminal);
      case Screen.ai:
        return _buildText(L10n.of(context).navBarAI);
      case Screen.zipManager:
        return _buildText(L10n.of(context).zipManagerTitle);
    }
  }

  Widget _buildText(String text) {
        return Text(text, style: const TextStyle(fontSize: 19,fontWeight: FontWeight.w600));
    }
  }
