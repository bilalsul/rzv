import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:archive/archive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_Project> _projects = [];
  final Random _random = Random();
  _Project? _openedProject;
  List<String> _pathStack = <String>[];
  String? _selectedFileContent;

  @override
  void initState() {
    super.initState();
    // Add some temporary sample data so the screen isn't empty on first run.
    _projects.addAll(List.generate(3, (i) => _makeSampleProject(i + 1)));
  }

  _Project _makeSampleProject(int i) {
    // create a small in-memory file system for demo purposes
    final hasReadme = i % 2 == 1;
    final fs = <String, dynamic>{
      'src': {
        'main.dart': "void main() { print('Hello from project $i'); }",
        'lib': {
          'widget.dart': '// widget file',
        },
      },
      'assets': {
        'icon.png': 'binary-placeholder',
      },
      'LICENSE': 'MIT License',
    };
    if (hasReadme) {
      fs['README.md'] = '# Sample Project $i\n\nThis is a temporary README for Sample Project $i.\n\n- Example file\n- Demo project';
    } else {
      // create README in a nested folder for variety
      fs['docs'] = {
        'README.md': '# Docs for Project $i\n\nDocumentation lives here.'
      };
    }

    return _Project(
      id: 'proj_${i}_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Sample Project $i',
      fileCount: _random.nextInt(200),
      lastModified: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      type: i % 2 == 0 ? 'Flutter' : 'Dart',
      fs: fs,
    );
  }

  void _addProject() {
    setState(() {
      final next = _makeSampleProject(_projects.length + 1);
      _projects.insert(0, next);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project created (temp)')));
  }

  void _importProject() {
    setState(() {
      final imported = _makeSampleProject(_projects.length + 100);
      // simulate an import by adding at the end
      _projects.add(imported);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project imported (temp)')));
  }

  Future<void> _createProjectWithDetails() async {
    final nameTc = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(L10n.of(context).homeCreateProject),
      content: TextField(controller: nameTc, decoration: InputDecoration(hintText: L10n.of(context).homeAddProjectName)),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(L10n.of(context).homeCancel)), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(L10n.of(context).homeCreateProject))],
    ));
    if (confirmed != true) return;
    final name = nameTc.text.trim();
    if (name.isEmpty) return;
    setState(() {
      final p = _Project(id: 'proj_${_projects.length + 1}_${DateTime.now().millisecondsSinceEpoch}', name: name, fileCount: 0, lastModified: DateTime.now(), type: 'Custom', fs: {});
      _projects.insert(0, p);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeCreatedNewProject)));
  }

  Future<void> _importZipProject() async {
    final tc = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(L10n.of(context).homeImportZipProject),
      content: TextField(controller: tc, decoration: const InputDecoration(hintText: '/absolute/path/to/project.zip')),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(L10n.of(context).homeCancel)), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(L10n.of(context).homeImportProject))],
    ));
    if (confirmed != true) return;
    final path = tc.text.trim();
    if (path.isEmpty) return;
    final f = File(path);
    if (!await f.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).homeImportedZipNotFound)));
      return;
    }
    try {
      final bytes = await f.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final fs = <String, dynamic>{};
      for (final file in archive) {
        final name = file.name;
        if (file.isFile) {
          String content = '';
          try {
            content = utf8.decode(file.content as List<int>);
          } catch (_) {
            content = '(binary content)';
          }
          _insertIntoFsMap(fs, name.split('/'), content);
        } else {
          _insertIntoFsMap(fs, name.split('/'), <String, dynamic>{});
        }
      }
      final proj = _Project(id: 'import_${DateTime.now().millisecondsSinceEpoch}', name: 'Imported ${f.uri.pathSegments.last}', fileCount: archive.length, lastModified: DateTime.now(), type: 'Imported', fs: fs);
      setState(() {
        _projects.insert(0, proj);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported zip as project')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample zip created and imported')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sample import failed: $e')));
    }
  }

  void _openProject(_Project p) {
    // Open project inside HomeScreen: set as opened project and reset navigation stack
    setState(() {
      _openedProject = p;
      _pathStack = <String>[];
      _selectedFileContent = null;
      // Try load README at root
      final node = _getNodeAtPath(p, _pathStack);
      final readme = _findReadmeInNode(node);
      if (readme != null) _selectedFileContent = readme;
    });
    // Persist current project to Prefs so AppDrawer shows it
    try {
      final prefs = Prefs();
      prefs.saveCurrentProject(id: p.id, name: p.name ?? p.id, path: p.id);
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
                      _selectedFileContent = _findReadmeInNode(_getNodeAtPath(_openedProject!, _pathStack));
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
              if (_projects.isEmpty) return _EmptyState(onCreate: _addProject, onImport: _importProject);

              // If a project is opened, show ProjectBrowser inside HomeScreen
              if (_openedProject != null) {
                return _ProjectBrowser(
                  project: _openedProject!,
                  pathStack: _pathStack,
                  selectedFileContent: _selectedFileContent,
                  onEnterDirectory: (name) {
                    setState(() {
                      _pathStack.add(name);
                      _selectedFileContent = _findReadmeInNode(_getNodeAtPath(_openedProject!, _pathStack));
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
                  const Text('Something went wrong while rendering the Home screen.'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
                ]),
              );
            }
          }),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'import',
            onPressed: _importZipProject,
            tooltip: 'Import project (temp)',
            child: const Icon(Icons.file_upload),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'create_details',
            onPressed: _createProjectWithDetails,
            tooltip: 'Create project (details)',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'sample_zip',
            onPressed: _createSampleZipAndImport,
            tooltip: 'Create & import sample zip',
            child: const Icon(Icons.archive),
          ),
        ],
      ),
    );
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project removed')));
        },
      );
    } catch (_) {
      // If building the card fails for some reason, return a minimal placeholder so the list/grid stays stable.
      return Card(
        child: ListTile(
          leading: const Icon(Icons.folder),
          title: Text(p.name ?? 'Unnamed'),
          subtitle: const Text('Unable to display details'),
          onTap: () => _openProject(p),
        ),
      );
    }
  }
}

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
                Text(project.lastModified != null ? 'Modified ${project.lastModified!.toLocal().toString().split('.').first}' : 'No modification info', style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'open') onOpen?.call();
                else if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'open', child: Text('Open')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
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
      return Center(child: Text('File preview not available. Open in editor later.'));
    }

    // Expecting a directory map here
    final Map<String, dynamic> dir = (node is Map<String, dynamic>) ? node : <String, dynamic>{};
    final dirs = dir.entries.where((e) => e.value is Map<String, dynamic>).map((e) => e.key).toList()..sort();
    final files = dir.entries.where((e) => e.value is String).map((e) => e.key).toList()..sort();

    if (dirs.isEmpty && files.isEmpty) {
      return Center(child: Text('Empty directory'));
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
        final content = dir[fileName] as String?;
        final isMarkdown = fileName.toLowerCase().endsWith('.md') || fileName.toLowerCase().endsWith('.markdown');
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(fileName),
          subtitle: isMarkdown ? const Text('Markdown file') : null,
          onTap: () async {
            if (content == null) return;
            if (isMarkdown) {
              onOpenFile(content);
            } else {
              // Persist current file to Prefs and navigate to Editor screen
              final fullPathSegments = List<String>.from(pathStack)..add(fileName);
              final path = fullPathSegments.join('/');
              await Prefs().saveCurrentOpenFile(project.id, path, content);
              final lang = Prefs().detectLanguageFromFilename(fileName);
              await Prefs().saveCurrentOpenFileLanguage(lang);
              await Prefs().saveLastKnownRoute('editor');
            }
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