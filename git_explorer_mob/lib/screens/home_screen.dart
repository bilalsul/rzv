import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<_Project> _projects = [];
  _Project? _openedProject;
  List<String> _pathStack = <String>[];
  String? _selectedFileContent;
  String? _selectedFilePath;
  bool _diskLoaded = false;

  @override
  void initState() {
    super.initState();

    // Wait for SharedPreferences to be ready and react to plugin toggles.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // await ref.read(sharedPreferencesProvider.future);

      // If file explorer is enabled at startup, ensure projects root and load projects.
      if (Prefs().isPluginEnabled('file_explorer')) {
        await _prepareProjectsDir();
        if (Prefs().tutorialProject) await _ensureTutorialProjectExists();
        await _loadProjectsFromDisk();
        setState(() {
          _diskLoaded = true;
        });
      } else {
        // Not enabled: show in-memory samples so the UI is not empty.
        _projects.clear();
        setState(() {});
      }
    });

    // Listen for changes to prefs so we can react to toggles (e.g., enabling File Explorer)
    // NOTE: Do not provide an `async` callback to `ref.listen` because it must be
    // synchronous; schedule any async work via Future.microtask instead.
  }

  Future<void> _prepareProjectsDir() async {
    await Prefs().projectsRoot();
  }

  Future<void> _ensureTutorialProjectExists() async {
    final projRoot = await Prefs().projectsRoot();
    final id = 'tutorial_project';
    final dir = Directory('${projRoot.path}/$id');
    // if (!await dir.exists()) {
    await dir.create(recursive: true);
    final readme = File('${dir.path}/README.md');
    final title = L10n.of(context).tutorialProjectReadmeTitle;
    final body = L10n.of(context).tutorialProjectReadmeBody;
    final content = '$title\n\n$body';
    await readme.writeAsString(content);
    Prefs().setTutorialProject(false);
    // }
  }

  Future<void> _loadProjectsFromDisk() async {
    final projRoot = await Prefs().projectsRoot();
    final entries = projRoot.listSync().whereType<Directory>();
    final List<_Project> found = [];
    for (final d in entries) {
      final id = p.basename(d.path);
      // Build an in-memory tree map of the directory so the UI can render it.
      final fsMap = await _buildFsMapFromDir(d);
      final files = d.listSync(recursive: true).whereType<File>().toList();
      final stat = await d.stat();
      found.add(
        _Project(
          id: id,
          name: id == 'tutorial_project'
              ? L10n.of(context).tutorialProjectName
              : id,
          fileCount: files.length,
          lastModified: stat.modified,
          type: 'Local',
          fs: fsMap,
        ),
      );
    }
    // Replace the current list atomically to avoid duplicates and keep order
    _projects.clear();
    found.sort(
      (a, b) => (b.lastModified ?? DateTime(0)).compareTo(
        a.lastModified ?? DateTime(0),
      ),
    );
    _projects.addAll(found);
  }

  /// Recursively build a Map<String,dynamic> representation of [dir].
  /// Files are loaded as Strings (utf8) where possible; directories as nested maps.
  Future<Map<String, dynamic>> _buildFsMapFromDir(Directory dir) async {
    final map = <String, dynamic>{};
    final entities = dir.list(recursive: false, followLinks: false);
    await for (final e in entities) {
      final name = e.path.split('/').last;
      if (e is File) {
        try {
          final bytes = await e.readAsBytes();
          // Attempt to decode as utf8; if fails, store placeholder
          try {
            map[name] = utf8.decode(bytes);
          } catch (_) {
            map[name] = '(binary)';
          }
        } catch (_) {
          map[name] = '(error)';
        }
      } else if (e is Directory) {
        map[name] = await _buildFsMapFromDir(e);
      }
    }
    return map;
  }

  Future<void> _createProjectWithDetails() async {
    final nameTc = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.of(context).homeCreateProject),
        content: TextField(
          controller: nameTc,
          decoration: InputDecoration(
            hintText: L10n.of(context).homeAddProjectName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L10n.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L10n.of(context).homeCreateProject),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final name = nameTc.text.trim();
    if (name.isEmpty) return;
    // If file explorer (disk-based projects) is enabled, create a real folder under projects root.
    if (Prefs().isPluginEnabled('file_explorer')) {
      try {
        final base = await Prefs().projectsRoot();
        final baseName = name;
        var slug = baseName
            .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
            .replaceAll(' ', '_');
        var id = slug;
        final candidate = Directory('${base.path}/$id');
        if (await candidate.exists()) {
          id = '${slug}_${DateTime.now().millisecondsSinceEpoch}';
        }
        final dir = Directory('${base.path}/$id');
        if (!await dir.exists()) await dir.create(recursive: true);
        final readme = File('${dir.path}/README.md');
        final title = L10n.of(
          context,
        ).tutorialProjectReadmeTitle.replaceAll('Git Explorer', name);
        final body = L10n.of(context).tutorialProjectReadmeBody;
        await readme.writeAsString('$title\n\n$body');
        await _loadProjectsFromDisk();
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).homeCreatedNewProject)),
        );
        return;
      } catch (_) {
        // fall back to in-memory
      }
    }

    setState(() {
      final p = _Project(
        id: name,
        name: name,
        fileCount: 0,
        lastModified: DateTime.now(),
        type: 'Custom',
        fs: {},
      );
      _projects.insert(0, p);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.of(context).homeCreatedNewProject)),
    );
  }

  // Future<void> _importZipProject() async {
  // // Let user pick a zip file using the native picker, then extract into projects dir
  // final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
  // if (result == null || result.files.isEmpty) return;
  // final path = result.files.single.path;
  // if (path == null) return;
  // final f = File(path);
  // if (!await f.exists()) {
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeImportedZipNotFound)));
  // return;
  // }
  // try {
  // final bytes = await f.readAsBytes();
  // final archive = ZipDecoder().decodeBytes(bytes);
  // final projRoot = await Prefs().projectsRoot();
  // final pickedPath = path;
  // final baseName = p.basenameWithoutExtension(pickedPath);
  // // Create a safe slug for the project directory
  // var slug = baseName.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').replaceAll(' ', '_');
  // var id = slug;
  // final candidate = Directory('${projRoot.path}/$id');
  // if (await candidate.exists()) {
  // id = '${slug}_${DateTime.now().millisecondsSinceEpoch}';
  // }
  // final dir = Directory('${projRoot.path}/$id');
  // await dir.create(recursive: true);
  // // fileCount was intentionally omitted (not used) but kept for future use
  // for (final file in archive) {
  // final name = file.name;
  // final outPath = '${dir.path}/$name';
  // if (file.isFile) {
  // final outFile = File(outPath);
  // await outFile.create(recursive: true);
  // if (file.content is List<int>) {
  // await outFile.writeAsBytes(file.content as List<int>);
  // } else {
  // // Fallback to text
  // await outFile.writeAsString(utf8.decode(file.content as List<int>));
  // }
  // } else {
  // final d = Directory(outPath);
  // if (!await d.exists()) await d.create(recursive: true);
  // }
  // }
  // // Reload disk projects and refresh UI so the imported project appears immediately
  // await _loadProjectsFromDisk();
  // if (!mounted) return;
  // setState(() {});
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeImportZipAsProject)));
  // } catch (e) {
  // final msg = L10n.of(context).importFailed(e.toString());
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  // }
  // }

  // _insertIntoFsMap was removed because the function wasn't referenced anywhere.
  Future<void> _importZipProject(BuildContext context) async {
    // Let user pick a zip file using the native picker, then extract into projects dir
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final f = File(path);
    if (!await f.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).homeImportedZipNotFound)),
      );
      return;
    }

    Uint8List? bytes;
    Archive? archive;
    StateSetter? dialogSetState;
    BuildContext? dialogContext;

    try {
      bytes = await f.readAsBytes();
      archive = ZipDecoder().decodeBytes(bytes);

      final projRoot = await Prefs().projectsRoot();
      final pickedPath = path;
      final baseName = p.basenameWithoutExtension(pickedPath);

      // Create a safe slug for the project directory
      var slug = baseName
          .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
          .replaceAll(' ', '_')
          .trim();
      if (slug.isEmpty) slug = 'project';
      var id = slug;
      final candidate = Directory('${projRoot.path}/$id');
      if (await candidate.exists()) {
        id = '${slug}_${DateTime.now().millisecondsSinceEpoch}';
      }
      final dir = Directory('${projRoot.path}/$id');
      await dir.create(recursive: true);

      // === PROGRESS DIALOG SETUP ===
      bool isCancelled = false;
      int processed = 0;
      String currentItem = L10n.of(
        context,
      ).homeExtractInitializing; //'Initializing...'
      // StateSetter? dialogSetState;
      // BuildContext? dialogContext;

      // Show non-dismissible progress dialog with live updates and cancel button
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dc) {
          dialogContext = dc;
          return StatefulBuilder(
            builder: (context, StateSetter setState) {
              dialogSetState = setState;
              return AlertDialog(
                title: Text(
                  L10n.of(context).homeExtractImporting,
                ), // importing.........
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${L10n.of(context).homeDefaultProjectName}: $baseName',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: archive!.isEmpty
                            ? null
                            : processed / archive.length,
                        semanticsLabel: L10n.of(
                          context,
                        ).homeExtractProgress, // extraction progress
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$processed / ${archive.length} ${L10n.of(context).homeExtractItemsExtracted}',
                      ), //items extracted
                      const SizedBox(height: 12),
                      Text(
                        '${L10n.of(context).homeExtractCurrentFile}: $currentItem', //current
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      isCancelled = true;
                      Navigator.of(dc).pop();
                    },
                    child: Text(L10n.of(context).commonCancel),
                  ),
                ],
              );
            },
          );
        },
      );

      // Force initial dialog update
      currentItem = L10n.of(
        context,
      ).homeExtractStarting; //'Starting extraction...'

      dialogSetState?.call(() {});

      // === EXTRACTION LOOP ===
      for (final ArchiveFile file in archive) {
        if (isCancelled) break;

        currentItem = file.name.isEmpty ? '/' : file.name;
        dialogSetState?.call(() {});

        // Safely build output path (handles leading slashes, empty parts, etc.)
        final parts = file.name.split('/')..removeWhere((part) => part.isEmpty);
        // final outPath = p.join(dir.path, ...parts);
        final outPath = p.join(dir.path, parts.join(p.separator));

        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          final outDir = Directory(outPath);
          await outDir.create(recursive: true);
        }

        processed++;
        dialogSetState?.call(() {}); // Live progress update after every item
      }

      // === COMPLETION / CANCELLATION HANDLING ===
      final bool success = !isCancelled;

      if (isCancelled || !success) {
        // Delete everything if cancelled or failed part-way
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).commonCanceled),
            ), // import canceled
          );
        }
      } else {
        // Success path
        await _loadProjectsFromDisk();
        if (context.mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).homeImportZipAsProject),
            ), // 'Project imported successfully'
          );
        }
      }
    } catch (e) {
      // Any exception → clean up partial project and show error
      final projRoot = await Prefs().projectsRoot();
      final baseName = p.basenameWithoutExtension(path);
      var slug = baseName
          .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
          .replaceAll(' ', '_')
          .trim();
      if (slug.isEmpty) slug = 'project';
      var id = slug;
      final candidate = Directory('${projRoot.path}/$id');
      if (await candidate.exists()) {
        id = '${slug}_${DateTime.now().millisecondsSinceEpoch}';
      }
      final dir = Directory('${projRoot.path}/$id');

      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).importFailed(e.toString()))),
        );
      }
    } finally {
      // Always ensure dialog is closed
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop();
      }
    }
  }

  Future<void> _openProject(_Project p) async {
    // Open project inside HomeScreen: set as opened project and reset navigation stack
    String? readmeContent;
    String? readmePath;
    final node = _getNodeAtPath(p, <String>[]);
    final readme = _findReadmeInNode(node);
    if (p.fileCount == 1 && readme != null) {
      readmeContent = readme;
      try {
        final projRoot = await Prefs().projectsRoot();
        readmePath = '${projRoot.path}/${p.id}/README.md';
      } catch (_) {}
    }
    setState(() {
      _openedProject = p;
      _pathStack = <String>[];
      _selectedFileContent = readmeContent;
      _selectedFilePath = readmePath;
    });
    // Persist current project to Prefs so AppDrawer shows it
    try {
      // If this is a disk-backed project, compute absolute path and store it
      final projRoot = await Prefs().projectsRoot();
      final absPath = Directory('${projRoot.path}/${p.id}').path;
      await Prefs().saveCurrentProject(
        id: p.id,
        name: p.name ?? p.id,
        path: absPath,
      );
    } catch (_) {}
  }

  void _closeProject() {
    setState(() {
      _openedProject = null;
      _pathStack = <String>[];
      _selectedFileContent = null;
    });
  }

  Future<void> _refreshProjects(BuildContext context) async {
    try {
      await _loadProjectsFromDisk();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).homeRefreshedProjects)),
      ); // 'Projects refreshed'
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${L10n.of(context).homeRefreshProjectsFailed}: $e'),
          ), // 'Failed to refresh projects'
        );
    }
  }

  Future<void> _deleteAllProjects(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          L10n.of(context).homeDeleteAllProjects,
        ), //'Delete all projects'
        content: Text(
          L10n.of(context).homeDeleteAllProjectsPrompt,
        ), // 'You are going to delete ALL projects. This action cannot be undone. Do you want to proceed?'
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              L10n.of(context).commonCancel,
              style: TextStyle(color: Prefs().accentColor),
            ),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Prefs().accentColor),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              L10n.of(context).commonDelete,
              // style: TextStyle(backgroundColor: Prefs().accentColor),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final projRoot = await Prefs().projectsRoot();
      final entries = projRoot.listSync().whereType<Directory>().toList();
      for (final d in entries) {
        try {
          if (await d.exists()) await d.delete(recursive: true);
        } catch (_) {}
      }

      _projects.clear();
      _openedProject = null;
      _pathStack = <String>[];
      _selectedFileContent = null;

      try {
        await Prefs().saveCurrentProject(id: '', name: '', path: '');
        await Prefs().saveCurrentOpenFile('', '', '');
      } catch (_) {}

      await _loadProjectsFromDisk();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).homeDeletedAllProjects)),
      ); // 'All projects are deleted'
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${L10n.of(context).homeDeleteAllProjectsFailed}: $e',
            ),
          ), // 'Failed to delete projects'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    ref.listen<Prefs>(prefsProvider, (previous, next) {
      final prevEnabled = previous?.isPluginEnabled('file_explorer') ?? false;
      final nowEnabled = next.isPluginEnabled('file_explorer');
      if (!prevEnabled && nowEnabled) {
        // Just enabled: schedule async work to prepare and load projects
        Future.microtask(() async {
          await _prepareProjectsDir();
          if (Prefs().tutorialProject) await _ensureTutorialProjectExists();
          await _loadProjectsFromDisk();
          if (!mounted) return;
          setState(() {
            _diskLoaded = true;
          });
        });
      } else if (prevEnabled && !nowEnabled) {
        // Disabled: fall back to samples (synchronous)
        if (!mounted) return;
        setState(() {
          _diskLoaded = false;
        });
      }
    });
    return Scaffold(
      appBar: _openedProject == null
          ? AppBar(
              title: Text(L10n.of(context).homeProjectsTitle),
              actions: [
                IconButton(
                  tooltip: L10n.of(context).homeRefreshProjects,
                  icon: const Icon(Icons.refresh),
                  onPressed: () async => await _refreshProjects(context),
                ),
                IconButton(
                  tooltip: L10n.of(context).homeDeleteAllProjects,
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => _deleteAllProjects(context),
                ),
              ],
            )
          : AppBar(
              title: Text(
                _openedProject?.name ?? L10n.of(context).homeDefaultProjectName,
              ),
              // actions: [
              //   IconButton(
              //     tooltip: L10n.of(context).homeRefreshProjects,
              //     icon: const Icon(Icons.refresh),
              //     onPressed: () async => await _refreshProjects(context),
              //   ),
              //   IconButton(
              //     tooltip: L10n.of(context).homeDeleteAllProjects,
              //     icon: const Icon(Icons.delete_forever),
              //     onPressed: () => _deleteAllProjects(context),
              //   ),
              // ],
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // navigate up one level or close project if at root
                  if (_pathStack.isNotEmpty) {
                    setState(() {
                      _pathStack.removeLast();
                      // if len==1
                      final node = _getNodeAtPath(_openedProject!, _pathStack);
                      if (node is Map<String, dynamic> && node.length == 1) {
                        _selectedFileContent = _findReadmeInNode(node);
                      }
                    });
                  } else {
                    _closeProject();
                  }
                },
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Builder(
            builder: (context) {
              try {
                // Only show empty state after we've finished loading projects from disk.
                // This avoids a flash where the UI shows "no projects" before the background
                // disk scan completes and populates `_projects`.
                if (!_diskLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_projects.isEmpty)
                  return EmptyState(
                    onCreate: _createProjectWithDetails,
                    onImport: () => _importZipProject(context),
                  );

                // If a project is opened, show ProjectBrowser inside HomeScreen
                if (_openedProject != null) {
                  return _ProjectBrowser(
                    controller: widget.controller,
                    project: _openedProject!,
                    pathStack: _pathStack,
                    selectedFileContent: _selectedFileContent,
                    onEnterDirectory: (name) {
                      setState(() {
                        _pathStack.add(name);
                        final node = _getNodeAtPath(
                          _openedProject!,
                          _pathStack,
                        );
                        if (node is Map<String, dynamic> && node.length == 1) {
                          _selectedFileContent = _findReadmeInNode(node);
                          _selectedFilePath = null;
                          // compute path async
                          Future.microtask(() async {
                            final readmeName = 'README.md';
                            try {
                              final projRoot = await Prefs().projectsRoot();
                              final abs =
                                  '${projRoot.path}/${_openedProject!.id}/${_pathStack.join('/')}/$readmeName';
                              if (mounted)
                                setState(() => _selectedFilePath = abs);
                            } catch (_) {}
                          });
                        }
                      });
                    },
                    onOpenFile: (content, absPath) {
                      setState(() {
                        _selectedFileContent = content;
                        _selectedFilePath = absPath;
                      });
                    },
                  );
                }

                // Responsive: show Grid on wide screens, List on narrow screens
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    if (isWide) {
                      final crossAxisCount = (constraints.maxWidth ~/ 280)
                          .clamp(2, 5);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: _projects.length,
                        itemBuilder: (context, idx) {
                          final p = _projects[idx];
                          return _safeProjectCard(p);
                        },
                      );
                    } else {
                      return ListView.separated(
                        controller: widget.controller,
                        itemCount: _projects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final p = _projects[idx];
                          return _safeProjectCard(p);
                        },
                      );
                    }
                  },
                );
              } catch (e) {
                // Defensive: if something in the build fails, show a recoverable error UI instead of letting the app crash.
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 8),
                      Text(L10n.of(context).commonFailed),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: Text(L10n.of(context).commonRetry),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: _openedProject != null
          ? Padding(
              padding: EdgeInsets.only(bottom: 70),
              child: Builder(
                builder: (ctx) {
                  final previewing =
                      _selectedFileContent != null &&
                      (_openedProject!.id == 'tutorial_project' ||
                          Prefs().isPluginOptionEnabled('preview_markdown'));
                  if (previewing) {
                    return FloatingActionButton.extended(
                      // heroTag: 'open_in_editor',
                      icon: Icon(Icons.open_in_new, color: prefs.accentColor),
                      backgroundColor: prefs.secondaryColor,
                      label: Text(L10n.of(context).navBarEditor),
                      tooltip: L10n.of(context).homeOpenFileEditorNotice,
                      onPressed: () async {
                        if (_openedProject == null) return;
                        try {
                          final projRoot = await Prefs().projectsRoot();
                          String abs = _selectedFilePath ?? '';
                          if (abs.isEmpty) {
                            // Try common README names in current folder
                            final base =
                                '${projRoot.path}/${_openedProject!.id}${_pathStack.isEmpty ? '' : '/' + _pathStack.join('/')}';
                            final candidates = [
                              'README.md',
                              'Readme.md',
                              'readme.md',
                              'README.MD',
                              'README',
                            ];
                            for (final c in candidates) {
                              final f = File('$base/$c');
                              if (await f.exists()) {
                                abs = f.path;
                                break;
                              }
                            }
                          }
                          await Prefs().saveCurrentOpenFile(
                            _openedProject!.id,
                            abs,
                            _selectedFileContent ?? '',
                          );
                          await Prefs().saveCurrentProject(
                            id: _openedProject!.id,
                            name: _openedProject!.name ?? _openedProject!.id,
                            path: projRoot.path + '/${_openedProject!.id}',
                          );
                          await Prefs().saveLastKnownRoute('editor');
                        } catch (_) {}
                      },
                    );
                  }
                  return FloatingActionButton.extended(
                    // heroTag: 'create_file',
                    icon: Icon(Icons.note_add, color: prefs.accentColor),
                    backgroundColor: prefs.secondaryColor,
                    label: Text(L10n.of(context).commonCreate),
                    onPressed: _createFileInCurrentFolder,
                  );
                },
              ),
            )
          : Padding(
              padding: EdgeInsets.only(bottom: 70),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    // heroTag: 'create_details',
                    onPressed: _createProjectWithDetails,
                    tooltip: L10n.of(context).homeTooltipCreateDetails,
                    backgroundColor: prefs.secondaryColor,
                    child: Icon(Icons.add, color: prefs.accentColor),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    // heroTag: 'sample_zip',
                    onPressed: () => _importZipProject(context),
                    tooltip: L10n.of(context).homeTooltipCreateSampleZip,
                    backgroundColor: prefs.secondaryColor,
                    child: Icon(Icons.archive, color: prefs.accentColor),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _createFileInCurrentFolder() async {
    if (_openedProject == null) return;
    final nameTc = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.of(context).commonCreate),
        content: TextField(
          controller: nameTc,
          decoration: InputDecoration(
            hintText: L10n.of(context).drawerFolderNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L10n.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L10n.of(context).commonCreate),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final filename = nameTc.text.trim();
    if (filename.isEmpty) return;
    try {
      final base = await Prefs().projectsRoot();
      final folderPath = (_pathStack.isEmpty)
          ? '${base.path}/${_openedProject!.id}'
          : '${base.path}/${_openedProject!.id}/${_pathStack.join('/')}';
      final f = File('$folderPath/$filename');
      await f.create(recursive: true);
      await f.writeAsString('');
      // reload disk projects and re-open this project
      await _loadProjectsFromDisk();
      setState(() {
        _openedProject = _projects.firstWhere(
          (p) => p.id == _openedProject!.id,
          orElse: () => _openedProject!,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L10n.of(context).commonFailed)));
    }
  }

  Widget _safeProjectCard(_Project p) {
    final prefs = ref.watch(prefsProvider);
    try {
      return _ProjectCard(
        project: p,
        onOpen: () => _openProject(p),
        onDelete: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(L10n.of(context).commonDelete),
              content: Text(L10n.of(context).homeDeleteProjectDialogContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    L10n.of(context).commonCancel,
                    style: TextStyle(color: prefs.accentColor),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    L10n.of(context).commonDelete,
                    style: TextStyle(color: prefs.accentColor),
                  ),
                ),
              ],
            ),
          );
          if (confirm != true) return;

          setState(() {
            _projects.removeWhere((x) => x.id == p.id);
            if (_openedProject?.id == p.id) {
              _openedProject = null;
              _pathStack = <String>[];
              _selectedFileContent = null;
            }
          });
          try {
            final root = await Prefs().projectsRoot();
            final dir = Directory('${root.path}/${p.id}');
            if (await dir.exists()) await dir.delete(recursive: true);
            if (Prefs().currentProjectId == p.id) {
              await Prefs().saveCurrentProject(id: '', name: '', path: '');
            }
            if (Prefs().currentOpenProject == p.id) {
              await Prefs().saveCurrentOpenFile('', '', '');
            }
          } catch (_) {}
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n.of(context).homeProjectRemoved)),
          );
        },
      );
    } catch (_) {
      // If building the card fails for some reason, return a minimal placeholder so the list/grid stays stable.
      return Card(
        child: ListTile(
          leading: const Icon(Icons.folder),
          title: Text(p.name ?? 'Unnamed'),
          subtitle: Text(L10n.of(context).homeUnableToDisplayDetails),
          onTap: () => _openProject(p),
        ),
      );
    }
  }
}

/* 
Maintain the currentopenedfilePath, currentProject, exact absolute locations in pref flags.
Replace the entirely in-file model for temporary/demo usage, I am implementing for REAL WORLD
create in Application root dir, projects directory path if doesnt exist.
then if pref.tutorialProject == true, create tutorial project
where the folder name, is the project name(similar to other imported/created projects)
then add a README.md file containing title and body from L10n.of(context).
if the project(folder) contains only a README file view it inside a markdown view.
if the project(folder) contains 2 or more files, then view the project(folder) files
in tree view. everything about the project(folder) you get from files.
Inside a folder dir, add a floating button that allow me to create a file, add a name to it
and then add it to the tree view. when the file is opened, open it inside the editor screen.
I want to import,add,create and delete projects and files to the current directory.
when a zip file is imported, extract the zip in the projects root directory and save the extracted folders and tree.
Make it accessable to the user like other existing projects that are created/imported.
*/
// Small in-file model for temporary/demo usage.
class _Project {
  final String id;
  final String? name;
  final int? fileCount;
  final DateTime? lastModified;
  final String? type;
  final Map<String, dynamic> fs;
  _Project({
    required this.id,
    this.name,
    this.fileCount,
    this.lastModified,
    this.type,
    Map<String, dynamic>? fs,
  }) : fs = fs ?? {};
}

class _ProjectCard extends StatelessWidget {
  final _Project project;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const _ProjectCard({
    Key? key,
    required this.project,
    this.onOpen,
    this.onDelete,
  }) : super(key: key);

  String _shortName(String? n) {
    if (n == null || n.isEmpty) return 'Untitled';
    return n.length > 28 ? '${n.substring(0, 25)}…' : n;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blueGrey.shade700,
                child: Text(
                  (project.name?.trim().isNotEmpty == true
                      ? project.name!.trim()[0].toUpperCase()
                      : 'P'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shortName(project.name),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${project.fileCount ?? 0} ${L10n.of(context).homeFiles} · ${project.type ?? L10n.of(context).homeUnknown}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.lastModified != null
                          ? '${L10n.of(context).homeModified} ${project.lastModified!.toLocal().toString().split('.').first}'
                          : L10n.of(context).homeNoModificationInfo,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'open')
                    onOpen?.call();
                  else if (v == 'delete')
                    onDelete?.call();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'open',
                    child: Text(L10n.of(ctx).homeOpenMenu),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(L10n.of(ctx).commonDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final Future<void> Function() onImport;

  const EmptyState({super.key, required this.onCreate, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            L10n.of(context).homeNoProjects,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(L10n.of(context).homeGetStarted),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: Icon(Icons.add, color: Prefs().accentColor),
                label: Text(
                  L10n.of(context).homeCreateProject,
                  style: TextStyle(color: Prefs().accentColor),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await onImport();
                },
                icon: Icon(Icons.archive, color: Prefs().accentColor),
                label: Text(
                  L10n.of(context).homeImportProject,
                  style: TextStyle(color: Prefs().accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- Project Browser ----------------

class _ProjectBrowser extends StatelessWidget {
  final _Project project;
  final List<String> pathStack;
  final String? selectedFileContent;
  final void Function(String name) onEnterDirectory;
  final void Function(String content, String absPath) onOpenFile;
  final ScrollController controller;

  const _ProjectBrowser({
    required this.controller,
    required this.project,
    required this.pathStack,
    required this.onEnterDirectory,
    required this.onOpenFile,
    this.selectedFileContent,
  });

  dynamic _nodeAtPath() {
    dynamic node = project.fs;
    for (final seg in pathStack) {
      if (node is Map<String, dynamic> && node.containsKey(seg)) {
        node = node[seg];
      } else {
        return null;
      }
    }
    return node;
  }

  @override
  Widget build(BuildContext context) {
    final node = _nodeAtPath();
    // by default show the tutorial readme
    // if (selectedFileContent != null) {
    //   return Column(
    //     children: [
    //       Expanded(
    //         child: Markdown(
    //           data: L10n.of(context).tutorialProjectReadmeBody,
    //           selectable: true,
    //         ),
    //       ),
    //     ],
    //   );
    // }
    // If a file's content was selected and either this is the tutorial
    // project or the user enabled markdown preview, render it as Markdown.
    if (selectedFileContent != null &&
        (project.id == 'tutorial_project' ||
            Prefs().isPluginOptionEnabled('preview_markdown'))) {
      return Column(
        children: [
          Expanded(
            child: Markdown(data: selectedFileContent!, selectable: true),
          ),
        ],
      );
    }

    // If node is a file (string) but not selected (non-md), show placeholder
    if (node is String) {
      return Center(child: Text(L10n.of(context).homeFilePreviewUnavailable));
    }

    // Expecting a directory map here
    final Map<String, dynamic> dir = (node is Map<String, dynamic>)
        ? node
        : <String, dynamic>{};
    final dirs =
        dir.entries
            .where((e) => e.value is Map<String, dynamic>)
            .map((e) => e.key)
            .toList()
          ..sort();
    final files =
        dir.entries.where((e) => e.value is String).map((e) => e.key).toList()
          ..sort();

    if (dirs.isEmpty && files.isEmpty) {
      return Center(child: Text(L10n.of(context).homeEmptyDirectory));
    }

    return ListView.builder(
      controller: controller,
      itemCount: dirs.length + files.length,
      itemBuilder: (context, index) {
        if (index < dirs.length) {
          final name = dirs[index];
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(name),
            onTap: () => onEnterDirectory(name),
          );
        }
        final fileName = files[index - dirs.length];
        final isMarkdown =
            fileName.toLowerCase().endsWith('.md') ||
            fileName.toLowerCase().endsWith('.markdown');
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(fileName),
          subtitle: isMarkdown ? Text(L10n.of(context).homeMarkdownFile) : null,
          onTap: () async {
            // Compute absolute path and read file content (prefer disk, fallback to in-memory map)
            try {
              final base = await Prefs().projectsRoot();
              final projRoot = base;
              final relPath = (pathStack.isEmpty
                  ? fileName
                  : '${pathStack.join('/')}/$fileName');
              final abs = '${projRoot.path}/${project.id}/$relPath';
              String content = '';
              final f = File(abs);
              if (await f.exists()) {
                try {
                  content = await f.readAsString();
                } catch (_) {
                  content = '(binary)';
                }
              } else {
                // Fall back to in-memory map if present
                final node = _getNodeAtPath(project, [...pathStack, fileName]);
                if (node is String) content = node;
              }

              // If this is a markdown file and preview is enabled (or it's the tutorial project),
              // show the content in-place via the provided callback. Otherwise, open in editor.
              if (isMarkdown &&
                  (project.id == 'tutorial_project' ||
                      Prefs().isPluginOptionEnabled('preview_markdown'))) {
                onOpenFile(content, abs);
                return;
              }

              // Fallback: persist current open file and route to editor
              await Prefs().saveCurrentOpenFile(project.id, abs, content);
              // Also save current project absolute path
              await Prefs().saveCurrentProject(
                id: project.id,
                name: project.name ?? project.id,
                path: projRoot.path + '/${project.id}',
              );
              await Prefs().saveLastKnownRoute('editor');
              // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorScreen()));
            } catch (_) {}
          },
        );
      },
    );
  }
}

// ---------------- Helpers ----------------

dynamic _getNodeAtPath(_Project p, List<String> path) {
  dynamic node = p.fs;
  for (final seg in path) {
    if (node is Map<String, dynamic> && node.containsKey(seg)) {
      node = node[seg];
    } else {
      return null;
    }
  }
  return node;
}

String? _findReadmeInNode(dynamic node) {
  if (node is! Map<String, dynamic>) return null;
  const candidates = [
    'README.md',
    'Readme.md',
    'readme.md',
    'README.MD',
    'README',
  ];
  for (final k in candidates) {
    final v = node[k];
    if (v is String) return v;
  }
  return null;
}
