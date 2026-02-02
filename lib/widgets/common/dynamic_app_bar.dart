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
      case Screen.zipDownloader:
        return _buildText('zip downloader');
      case Screen.zipManager:
        return _buildText('zip manager');
    }
  }

  Widget _buildText(String text) {
        return Text(text, style: const TextStyle(fontSize: 19,fontWeight: FontWeight.w600));
    }
  }

  // List<Widget> _buildActions(Screen screen, BuildContext context, WidgetRef ref) {
  //   switch (screen) {
  //     case Screen.editor:
  //       return [
  //         IconButton(
  //           icon: const Icon(Icons.search),
  //           onPressed: () => _showSearch(context),
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.more_vert),
  //           onPressed: () => _showEditorMenu(context, ref),
  //         ),
  //       ];
  //     case Screen.fileExplorer:
  //       return [
  //         IconButton(
  //           icon: const Icon(Icons.refresh),
  //           onPressed: () => _refreshFileExplorer(ref),
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.create_new_folder),
  //           onPressed: () => _createNewFolder(context),
  //         ),
  //       ];
  //     case Screen.gitHistory:
  //       return [
  //         IconButton(
  //           icon: const Icon(Icons.abc), // Replace with pull request icon
  //           onPressed: () => _showGitActions(context, ref),
  //         ),
  //       ];
  //     case Screen.settings:
  //       return [
  //         IconButton(
  //           icon: const Icon(Icons.save),
  //           onPressed: () => _saveSettings(ref),
  //         ),
  //       ];
  //     default:
  //       return [
  //         IconButton(
  //           icon: const Icon(Icons.info_outline),
  //           onPressed: () => _showAppInfo(context),
  //         ),
  //       ];
  //   }
  // }

  // Color? _getAppBarColor(Screen screen, BuildContext context) {
  //   final theme = Theme.of(context);
  //   switch (screen) {
  //     case Screen.editor:
  //       return theme.colorScheme.primaryContainer;
  //     case Screen.gitHistory:
  //       return theme.colorScheme.secondaryContainer;
  //     case Screen.settings:
  //       return theme.colorScheme.tertiaryContainer;
  //     default:
  //       return theme.appBarTheme.backgroundColor;
  //   }
  // }

  // double _getAppBarElevation(Screen screen) {
  //   switch (screen) {
  //     case Screen.home:
  //       return 0;
  //     case Screen.editor:
  //       return 2;
  //     default:
  //       return 1;
  //   }
  // }

  // Action methods
  // void _showSearch(BuildContext context) {
  //   showSearch(context: context, delegate: _CodeSearchDelegate());
  // }

  // void _showEditorMenu(BuildContext context, WidgetRef ref) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => _EditorBottomSheet(ref: ref),
  //   );
  // }

  // void _refreshFileExplorer(WidgetRef ref) {
  //   // Refresh file explorer logic
  // }

  // void _createNewFolder(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => const _CreateFolderDialog(),
  //   );
  // }

  // void _showGitActions(BuildContext context, WidgetRef ref) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => _GitActionsSheet(ref: ref),
  //   );
  // }

  // void _saveSettings(WidgetRef ref) {
  //   // Save settings logic
  // }

  // void _showAppInfo(BuildContext context) {
  //   showAboutDialog(context: context);
  // }
// }

// class _CodeSearchDelegate extends SearchDelegate {
//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       IconButton(
//         icon: const Icon(Icons.clear),
//         onPressed: () => query = '',
//       ),
//     ];
//   }

//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () => close(context, null),
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     return Center(
//       child: Text('Search results for: $query'),
//     );
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     return const Center(
//       child: Text('Search in code...'),
//     );
//   }
// }

// class _EditorBottomSheet extends ConsumerWidget {
//   final WidgetRef ref;

//   const _EditorBottomSheet({required this.ref});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             leading: const Icon(Icons.format_size),
//             title: const Text('Font Size'),
//             onTap: () => _showFontSizeDialog(context, ref),
//           ),
//           ListTile(
//             leading: const Icon(Icons.palette),
//             title: const Text('Editor Theme'),
//             onTap: () => _showThemeDialog(context, ref),
//           ),
//           ListTile(
//             leading: const Icon(Icons.wrap_text),
//             title: const Text('Word Wrap'),
//             onTap: () => _toggleWordWrap(ref),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
//     // Show font size dialog
//   }

//   void _showThemeDialog(BuildContext context, WidgetRef ref) {
//     // Show theme dialog
//   }

//   void _toggleWordWrap(WidgetRef ref) {
//     // Toggle word wrap
//   }
// }

// class _CreateFolderDialog extends StatelessWidget {
//   const _CreateFolderDialog();

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Create New Folder'),
//       content: TextField(
//         decoration: const InputDecoration(hintText: 'Folder name'),
//         onSubmitted: (value) {
//           Navigator.of(context).pop();
//         },
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Create'),
//         ),
//       ],
//     );
//   }
// }

// class _GitActionsSheet extends ConsumerWidget {
//   final WidgetRef ref;

//   const _GitActionsSheet({required this.ref});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             leading: const Icon(Icons.download),
//             title: const Text('Pull Changes'),
//             onTap: () => _pullChanges(ref),
//           ),
//           ListTile(
//             leading: const Icon(Icons.upload),
//             title: const Text('Push Changes'),
//             onTap: () => _pushChanges(ref),
//           ),
//           ListTile(
//             leading: const Icon(Icons.code),
//             title: const Text('Commit Changes'),
//             onTap: () => _showCommitDialog(context, ref),
//           ),
//         ],
//       ),
//     );
//   }

//   void _pullChanges(WidgetRef ref) {
//     // Pull changes logic
//   }

//   void _pushChanges(WidgetRef ref) {
//     // Push changes logic
//   }

//   void _showCommitDialog(BuildContext context, WidgetRef ref) {
//     showDialog(
//       context: context,
//       builder: (context) => const _CommitDialog(),
//     );
//   }
// }

// class _CommitDialog extends StatelessWidget {
//   const _CommitDialog();

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Commit Changes'),
//       content: TextField(
//         decoration: const InputDecoration(hintText: 'Commit message'),
//         maxLines: 3,
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Commit'),
//         ),
//       ],
//     );
//   }
// }