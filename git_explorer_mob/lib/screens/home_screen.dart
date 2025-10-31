import 'dart:math';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_Project> _projects = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Add some temporary sample data so the screen isn't empty on first run.
    _projects.addAll(List.generate(3, (i) => _makeSampleProject(i + 1)));
  }

  _Project _makeSampleProject(int i) {
    return _Project(
      id: 'proj_${i}_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Sample Project $i',
      fileCount: _random.nextInt(200),
      lastModified: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      type: i % 2 == 0 ? 'Flutter' : 'Dart',
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

  void _openProject(_Project p) {
    // For now we just show a bottom sheet with details. This avoids needing the editor screen.
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name ?? 'Unnamed project', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Type: ${p.type ?? 'Unknown'}'),
          Text('Files: ${p.fileCount ?? 0}'),
          Text('Modified: ${p.lastModified?.toLocal().toString() ?? '—'}'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Builder(builder: (context) {
            try {
              if (_projects.isEmpty) return _EmptyState(onCreate: _addProject, onImport: _importProject);

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
            onPressed: _importProject,
            tooltip: 'Import project (temp)',
            child: const Icon(Icons.file_upload),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _addProject,
            tooltip: 'Create project (temp)',
            child: const Icon(Icons.add),
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

  _Project({required this.id, this.name, this.fileCount, this.lastModified, this.type});
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
                if (v == 'delete') {
                  // confirm quick delete
                  showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('Delete project?'),
                        content: Text('Delete "${project.name ?? 'Untitled'}"? This action is temporary (in-memory).'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                          TextButton(onPressed: () {
                            Navigator.of(ctx).pop();
                            onDelete?.call();
                          }, child: const Text('Delete'))
                        ],
                      ));
                } else if (v == 'open') {
                  onOpen?.call();
                }
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
        const Text('No projects yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Create or import a project to get started', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create')),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.file_upload), label: const Text('Import')),
        ])
      ]),
    );
  }
}