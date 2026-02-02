import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'zip_download_controller.dart';
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
            const SizedBox(height: 12),
            if (state.status == AsyncStatus.loading)
              LinearProgressIndicator(value: state.progress)
            else
              const SizedBox.shrink(),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            if (state.status == AsyncStatus.error)
              Text(state.message ?? 'Error', style: const TextStyle(color: Colors.red))
            else if (state.status == AsyncStatus.success)
              Text('Saved: ${state.message}')
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
