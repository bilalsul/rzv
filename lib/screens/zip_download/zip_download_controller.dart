import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rzv/services/network/github_zip_service.dart';
import 'package:rzv/services/state/async_status.dart';
import 'package:rzv/services/state/side_effect_handler.dart';
import 'zip_download_state.dart';

class ZipDownloadController extends ChangeNotifier {
  ZipDownloadState _state = ZipDownloadState();
  ZipDownloadState get state => _state;

  final CancellationToken _token = CancellationToken();

  void _setState(ZipDownloadState s) {
    _state = s;
    notifyListeners();
  }

  void disposeController() {
    _token.cancel();
    super.dispose();
  }

  Future<void> download(String ownerRepo) async {
    _setState(_state.copyWith(status: AsyncStatus.loading, progress: 0.0, message: null));
    try {
      final file = await GitHubZipService.instance.downloadRepoZip(ownerRepo, token: _token, onProgress: (dl, total) {
        if (total != null && total > 0) {
          final p = dl / total;
          _setState(_state.copyWith(progress: p));
        }
      });

      // success
      _setState(_state.copyWith(status: AsyncStatus.success, progress: 1.0, message: file.path));
    } on OperationCanceledException {
      _setState(_state.copyWith(status: AsyncStatus.idle, progress: 0.0, message: 'Cancelled'));
    } catch (e) {
      final msg = e is Exception ? e.toString() : 'Unknown error';
      _setState(_state.copyWith(status: AsyncStatus.error, message: msg));
    }
  }

  void cancel() {
    _token.cancel();
  }
}

final zipDownloadControllerProvider = ChangeNotifierProvider.autoDispose<ZipDownloadController>((ref) {
  final c = ZipDownloadController();
  ref.onDispose(() => c.disposeController());
  return c;
});
