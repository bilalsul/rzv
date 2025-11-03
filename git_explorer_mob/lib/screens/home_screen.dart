import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_Project> _projects = [];
  _Project? _openedProject;
  List<String> _pathStack = <String>[];
  String? _selectedFileContent;

  @override
  void initState() {
    super.initState();
    // Load persisted projects from the app data directory (if file explorer is enabled),
    // otherwise keep the in-memory sample projects for demo.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepareProjectsDir();
      final fileExplorerEnabled = Prefs().isPluginEnabled('file_explorer');
      // add a flag, if first time, enable tutorialProjectflag then add it to dir
      if (fileExplorerEnabled) {
        // add an if (tutorialProjectflag) then ensure it exists, saving it to file.
        await _ensureTutorialProjectExists();
        await _loadProjectsFromDisk();
      } else {
        // Add some temporary sample data so the screen isn't empty on first run.
        // _projects.addAll(List.generate(3, (i) => _makeSampleProject(i + 1)));
      }
      // setState(() {});
    });
  }

  Future<Directory> _projectsRoot() async {
    final base = await getApplicationDocumentsDirectory();
    final projects = Directory('${base.path}/projects');
    if (!await projects.exists()) await projects.create(recursive: true);
    return projects;
  }

  Future<void> _prepareProjectsDir() async {
    await _projectsRoot();
  }

  Future<void> _ensureTutorialProjectExists() async {
    final projRoot = await _projectsRoot();
    final id = 'tutorial_project';
    final dir = Directory('${projRoot.path}/$id');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      final readme = File('${dir.path}/README.md');
      // Use immediate locale-based strings to avoid depending on generated L10n getters here.
      final locale = Localizations.localeOf(context).languageCode;
      final title = locale == 'es' ? '# Bienvenido al tutorial de Git Explorer' : '# Welcome to the Git Explorer Tutorial';
      final body = locale == 'es'
          ? 'Este README te guía por las funciones de la pantalla Inicio y cómo abrir, editar, guardar y eliminar archivos.\n\n- Toca un proyecto para abrirlo\n- Toca un archivo para previsualizarlo o abrirlo en el editor\n- Usa el cajón para activar funciones como el Explorador de archivos\n- Crea, importa (.zip) o elimina proyectos desde aquí\n\n¡Disfruta explorando la app!'
          : 'This README walks you through the Home screen features and how to open, edit, save and delete files.\n\n- Tap a project to open it\n- Tap a file to preview or open it in the editor\n- Use the drawer to toggle features like File Explorer\n- Create, import (.zip) or remove projects from here\n\nEnjoy exploring the app!';
      final content = '$title\n\n$body';
      await readme.writeAsString(content);
    }
  }

  Future<void> _loadProjectsFromDisk() async {
    final projRoot = await _projectsRoot();
    final entries = projRoot.listSync().whereType<Directory>();
    _projects.clear();
    for (final d in entries) {
      final id = d.path.split('/').last;
      // Build an in-memory tree map of the directory so the UI can render it.
      final fsMap = await _buildFsMapFromDir(d);
      final files = d.listSync(recursive: true).whereType<File>().toList();
      final stat = await d.stat();
      _projects.add(_Project(
        id: id,
        name: id == 'tutorial_project' ? L10n.of(context).tutorialProjectName : id,
        fileCount: files.length,
        lastModified: stat.modified,
        type: 'Local',
        fs: fsMap,
      ));
    }
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
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(L10n.of(context).homeCreateProject),
      content: TextField(controller: nameTc, decoration: InputDecoration(hintText: L10n.of(context).homeAddProjectName)),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(L10n.of(context).commonCancel)), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(L10n.of(context).homeCreateProject))],
    ));
    if (confirmed != true) return;
    final name = nameTc.text.trim();
    if (name.isEmpty) return;
    // If file explorer (disk-based projects) is enabled, create a real folder under projects root.
    if (Prefs().isPluginEnabled('file_explorer')) {
      try {
        final base = await _projectsRoot();
        final slug = name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').replaceAll(' ', '_');
        final id = '${slug}_${DateTime.now().millisecondsSinceEpoch}';
        final dir = Directory('${base.path}/$id');
        if (!await dir.exists()) await dir.create(recursive: true);
        final readme = File('${dir.path}/README.md');
        final title = L10n.of(context).tutorialProjectReadmeTitle.replaceAll('Git Explorer', name);
        final body = L10n.of(context).tutorialProjectReadmeBody;
        await readme.writeAsString('$title\n\n$body');
        await _loadProjectsFromDisk();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeCreatedNewProject)));
        return;
      } catch (_) {
        // fall back to in-memory
      }
    }

    setState(() {
      final p = _Project(id: 'proj_${_projects.length + 1}_${DateTime.now().millisecondsSinceEpoch}', name: name, fileCount: 0, lastModified: DateTime.now(), type: 'Custom', fs: {});
      _projects.insert(0, p);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeCreatedNewProject)));
  }

  Future<void> _importZipProject() async {
    // Let user pick a zip file using the native picker, then extract into projects dir
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final f = File(path);
    if (!await f.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeImportedZipNotFound)));
      return;
    }
    try {
      final bytes = await f.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final projRoot = await _projectsRoot();
      final id = 'import_${DateTime.now().millisecondsSinceEpoch}';
      final dir = Directory('${projRoot.path}/$id');
      await dir.create(recursive: true);
      int fileCount = 0;
      for (final file in archive) {
        final name = file.name;
        final outPath = '${dir.path}/$name';
        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.create(recursive: true);
          if (file.content is List<int>) {
            await outFile.writeAsBytes(file.content as List<int>);
          } else {
            // Fallback to text
            await outFile.writeAsString(utf8.decode(file.content as List<int>));
          }
          fileCount++;
        } else {
          final d = Directory(outPath);
          if (!await d.exists()) await d.create(recursive: true);
        }
      }
      final proj = _Project(id: id, name: 'Imported ${f.uri.pathSegments.last}', fileCount: fileCount, lastModified: DateTime.now(), type: 'Imported', fs: {});
      setState(() {
        _projects.insert(0, proj);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeImportZipAsProject)));
    } catch (e) {
      final msg = L10n.of(context).importFailed(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _insertIntoFsMap(Map<String, dynamic> root, List<String> parts, dynamic value) {
    if (parts.isEmpty) return;
    final head = parts.first;
    if (parts.length == 1) {
      root[head] = value;
      return;
    }
    root[head] ??= <String, dynamic>{};
    final child = root[head];
    if (child is Map<String, dynamic>) {
      _insertIntoFsMap(child, parts.sublist(1), value);
    }
  }

  Future<void> _createSampleZipAndImport() async {
    try {
      final archive = Archive();
      final readmeBytes = utf8.encode('# Sample Imported Project\n\nThis project was created from a generated zip.');
      archive.addFile(ArchiveFile('README.md', readmeBytes.length, readmeBytes));
      final mainBytes = utf8.encode("void main() { print('Hello from imported sample'); }");
      archive.addFile(ArchiveFile('src/main.dart', mainBytes.length, mainBytes));
      final bytes = ZipEncoder().encode(archive)!;
      final tmp = Directory.systemTemp.createTempSync('git_explorer_sample_');
      final zipFile = File('${tmp.path}/sample_project.zip');
      await zipFile.writeAsBytes(bytes);
      final archiveDecoded = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      final fs = <String, dynamic>{};
      for (final file in archiveDecoded) {
        final name = file.name;
        if (file.isFile) {
          String content = '';
          try {
            content = utf8.decode(file.content as List<int>);
          } catch (_) {
            content = '(binary)';
          }
          _insertIntoFsMap(fs, name.split('/'), content);
        } else {
          _insertIntoFsMap(fs, name.split('/'), <String, dynamic>{});
        }
      }
      final proj = _Project(id: 'sample_${DateTime.now().millisecondsSinceEpoch}', name: 'Imported Sample', fileCount: archiveDecoded.length, lastModified: DateTime.now(), type: 'Imported', fs: fs);
      setState(() {
        _projects.insert(0, proj);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeSampleZipCreatedAndImported)));
    } catch (e) {
  final msg = L10n.of(context).homeSampleImportFailed(e.toString());
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openProject(_Project p) async {
    // Open project inside HomeScreen: set as opened project and reset navigation stack
    setState(() {
      _openedProject = p;
      _pathStack = <String>[];
      _selectedFileContent = null;
      
      // if only one file exists in the directory
      if(p.fileCount == 1){
      // Try load README at root
      final node = _getNodeAtPath(p, _pathStack);
      final readme = _findReadmeInNode(node);
      if (readme != null) _selectedFileContent = readme;
      }
    });
    // Persist current project to Prefs so AppDrawer shows it
    try {
      final prefs = Prefs();
      // If this is a disk-backed project, compute absolute path and store it
      final projRoot = await _projectsRoot();
      final absPath = Directory('${projRoot.path}/${p.id}').path;
      await prefs.saveCurrentProject(id: p.id, name: p.name ?? p.id, path: absPath);
    } catch (_) {}
  }

  void _closeProject() {
    setState(() {
      _openedProject = null;
      _pathStack = <String>[];
      _selectedFileContent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _openedProject == null
          ? AppBar(title: Text(L10n.of(context).homeProjectsTitle))
          : AppBar(
              title: Text(_openedProject?.name ?? L10n.of(context).homeDefaultProjectName),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // navigate up one level or close project if at root
                  if (_pathStack.isNotEmpty) {
                    setState(() {
                      _pathStack.removeLast();
                      // if len==1
                      if(_getNodeAtPath(_openedProject!, _pathStack).length == 1){
                      _selectedFileContent = _findReadmeInNode(_getNodeAtPath(_openedProject!, _pathStack));
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
          child: Builder(builder: (context) {
            try {
              if (_projects.isEmpty) return _EmptyState(onCreate: ()=>{}, onImport: ()=>{});

              // If a project is opened, show ProjectBrowser inside HomeScreen
              if (_openedProject != null) {
                return _ProjectBrowser(
                  project: _openedProject!,
                  pathStack: _pathStack,
                  selectedFileContent: _selectedFileContent,
                  onEnterDirectory: (name) {
                    setState(() {
                      _pathStack.add(name);
                      if(_getNodeAtPath(_openedProject!, _pathStack).length == 1){
                      _selectedFileContent = _findReadmeInNode(_getNodeAtPath(_openedProject!, _pathStack));
                      }
                    });
                  },
                  onOpenFile: (content) {
                    setState(() {
                      _selectedFileContent = content;
                    });
                  },
                );
              }

              // Responsive: show Grid on wide screens, List on narrow screens
              return LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  final crossAxisCount = (constraints.maxWidth ~/ 280).clamp(2, 5);
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
                    itemCount: _projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final p = _projects[idx];
                      return _safeProjectCard(p);
                    },
                  );
                }
              });
            } catch (e) {
              // Defensive: if something in the build fails, show a recoverable error UI instead of letting the app crash.
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  Text(L10n.of(context).commonFailed),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => setState(() {}), child: Text(L10n.of(context).commonRetry)),
                ]),
              );
            }
          }),
        ),
      ),
      floatingActionButton: _openedProject != null
          ? FloatingActionButton.extended(
              heroTag: 'create_file',
              icon: const Icon(Icons.note_add),
              label: Text(L10n.of(context).commonCreate),
              onPressed: _createFileInCurrentFolder,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'import',
                  onPressed: _importZipProject,
                  tooltip: L10n.of(context).homeTooltipImportTemp,
                  child: const Icon(Icons.file_upload),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'create_details',
                  onPressed: _createProjectWithDetails,
                  tooltip: L10n.of(context).homeTooltipCreateDetails,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'sample_zip',
                  onPressed: _createSampleZipAndImport,
                  tooltip: L10n.of(context).homeTooltipCreateSampleZip,
                  child: const Icon(Icons.archive),
                ),
              ],
            ),
    );
  }

  Future<void> _createFileInCurrentFolder() async {
    if (_openedProject == null) return;
    final nameTc = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(L10n.of(context).commonCreate),
      content: TextField(controller: nameTc, decoration: InputDecoration(hintText: L10n.of(context).drawerFolderNameHint)),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(L10n.of(context).commonCancel)), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(L10n.of(context).commonCreate))],
    ));
    if (confirmed != true) return;
    final filename = nameTc.text.trim();
    if (filename.isEmpty) return;
    try {
      final base = await _projectsRoot();
      final folderPath = (_pathStack.isEmpty) ? '${base.path}/${_openedProject!.id}' : '${base.path}/${_openedProject!.id}/${_pathStack.join('/')}';
      final f = File('$folderPath/$filename');
      await f.create(recursive: true);
      await f.writeAsString('');
      // reload disk projects and re-open this project
      await _loadProjectsFromDisk();
      setState(() {
        _openedProject = _projects.firstWhere((p) => p.id == _openedProject!.id, orElse: () => _openedProject!);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).commonFailed)));
    }
  }

  Widget _safeProjectCard(_Project p) {
    try {
      return _ProjectCard(
        project: p,
        onOpen: () => _openProject(p),
          onDelete: () {
          setState(() {
            _projects.removeWhere((x) => x.id == p.id);
          });
          // Also delete from disk if present
          try {
            _projectsRoot().then((root) async {
              final dir = Directory('${root.path}/${p.id}');
              if (await dir.exists()) await dir.delete(recursive: true);
            });
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeProjectRemoved)));
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
  _Project({required this.id, this.name, this.fileCount, this.lastModified, this.type, Map<String, dynamic>? fs}) : fs = fs ?? {};
}

class _ProjectCard extends StatelessWidget {
  final _Project project;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const _ProjectCard({Key? key, required this.project, this.onOpen, this.onDelete}) : super(key: key);

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
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blueGrey.shade700,
              child: Text(
                (project.name?.trim().isNotEmpty == true ? project.name!.trim()[0].toUpperCase() : 'P'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_shortName(project.name), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('${project.fileCount ?? 0} files · ${project.type ?? 'Unknown'}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 6),
                Text(project.lastModified != null ? 'Modified ${project.lastModified!.toLocal().toString().split('.').first}' : L10n.of(context).homeNoModificationInfo, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'open') onOpen?.call();
                else if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'open', child: Text(L10n.of(ctx).homeOpenMenu)),
                PopupMenuItem(value: 'delete', child: Text(L10n.of(ctx).commonDelete)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onImport;

  const _EmptyState({Key? key, required this.onCreate, required this.onImport}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(L10n.of(context).homeNoProjects, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(L10n.of(context).homeGetStarted, style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: Text(L10n.of(context).homeCreateProject)),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.file_upload), label: Text(L10n.of(context).homeImportProject)),
        ])
      ]),
    );
  }
}

// ---------------- Project Browser ----------------

class _ProjectBrowser extends StatelessWidget {
  final _Project project;
  final List<String> pathStack;
  final String? selectedFileContent;
  final void Function(String name) onEnterDirectory;
  final void Function(String content) onOpenFile;

  _ProjectBrowser({required this.project, required this.pathStack, required this.onEnterDirectory, required this.onOpenFile, this.selectedFileContent});

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
    // If a markdown file is selected, render it
    if (selectedFileContent != null) {
      return Column(children: [
        Expanded(
          child: Markdown(
            data: selectedFileContent!,
            selectable: true,
          ),
        ),
      ]);
    }

    // If node is a file (string) but not selected (non-md), show placeholder
    if (node is String) {
      return Center(child: Text(L10n.of(context).homeFilePreviewUnavailable));
    }

    // Expecting a directory map here
    final Map<String, dynamic> dir = (node is Map<String, dynamic>) ? node : <String, dynamic>{};
    final dirs = dir.entries.where((e) => e.value is Map<String, dynamic>).map((e) => e.key).toList()..sort();
    final files = dir.entries.where((e) => e.value is String).map((e) => e.key).toList()..sort();

    if (dirs.isEmpty && files.isEmpty) {
      return Center(child: Text(L10n.of(context).homeEmptyDirectory));
    }

    return ListView.builder(
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
        final isMarkdown = fileName.toLowerCase().endsWith('.md') || fileName.toLowerCase().endsWith('.markdown');
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(fileName),
                subtitle: isMarkdown ? Text(L10n.of(context).homeMarkdownFile) : null,
                onTap: () async {
                  // Compute absolute path and save as current open file, then open editor
                  try {
                    final base = await getApplicationDocumentsDirectory();
                    final projRoot = Directory('${base.path}/projects');
                    final relPath = (pathStack.isEmpty ? fileName : '${pathStack.join('/')}/$fileName');
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
                    await Prefs().saveCurrentOpenFile(project.id, abs, content);
                    // Also save current project absolute path
                    await Prefs().saveCurrentProject(id: project.id, name: project.name ?? project.id, path: projRoot.path + '/${project.id}');
                    // Navigate to editor
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
  const candidates = ['README.md', 'Readme.md', 'readme.md', 'README.MD', 'README'];
  for (final k in candidates) {
    final v = node[k];
    if (v is String) return v;
  }
  return null;
}