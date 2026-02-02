import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'zip_download_controller.dart';
import 'zip_download_state.dart';
import '../../services/state/async_status.dart';

class ZipDownloadScreen extends ConsumerStatefulWidget {
  const ZipDownloadScreen({super.key});

  @override
  ConsumerState<ZipDownloadScreen> createState() => _ZipDownloadScreenState();
}

class _ZipDownloadScreenState extends ConsumerState<ZipDownloadScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(zipDownloadControllerProvider);
    final state = ctrl.state;

    return Scaffold(
      appBar: AppBar(title: Text('Download ZIP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'owner/repo'),
            ),
            const SizedBox(height: 16),
            // Enhanced progress display
            _ProgressDisplay(state: state, onOpen: (path) {
              if (path != null) OpenFilex.open(path);
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: state.status == AsyncStatus.loading
                        ? null
                        : () {
                            final input = _controller.text.trim();
                            ctrl.download(input);
                          },
                    child: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: state.status == AsyncStatus.loading ? () => ctrl.cancel() : null,
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.status == AsyncStatus.error)
              Text(state.message ?? 'Error', style: const TextStyle(color: Colors.red))
            else if (state.status == AsyncStatus.success)
              Row(
                children: [
                  Expanded(child: Text('Saved: ${state.message}')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: state.message != null ? () => OpenFilex.open(state.message!) : null,
                    child: const Text('Open'),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _ProgressDisplay extends StatelessWidget {
  final ZipDownloadState state;
  final void Function(String?) onOpen;

  const _ProgressDisplay({required this.state, required this.onOpen});

  String _human(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double b = bytes.toDouble();
    while (b >= 1024 && i < suffixes.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(b < 10 ? 2 : 1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    if (state.status == AsyncStatus.loading) {
      final pct = (state.progress * 100).clamp(0.0, 100.0);
      final downloaded = state.downloadedBytes;
      final total = state.totalBytes;
      final cs = Theme.of(context).colorScheme;

      // Determinate when total is known, otherwise show indeterminate bar
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 12,
              color: Colors.grey.shade300,
              child: total != null && total > 0
                  ? LayoutBuilder(builder: (context, constraints) {
                      final width = constraints.maxWidth * state.progress.clamp(0.0, 1.0);
                      return Stack(children: [
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            width: width,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ]);
                    })
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: LinearProgressIndicator(),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (total != null && total > 0) Text('${pct.toStringAsFixed(1)}%') else const Text('Downloading'),
              Text(total != null ? '${_human(downloaded ?? 0)} / ${_human(total)}' : _human(downloaded ?? 0)),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

