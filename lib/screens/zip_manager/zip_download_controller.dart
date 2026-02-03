import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rzv/services/network/github_zip_service.dart';
import 'package:rzv/services/network/gitlab_zip_service.dart';
import 'package:rzv/services/network/bitbucket_zip_service.dart';
import 'package:rzv/services/state/async_status.dart';
import 'package:rzv/services/state/side_effect_handler.dart';
import 'zip_download_state.dart';
import 'package:rzv/utils/toast/common.dart';

enum ZipProvider { github, gitlab, bitbucket }

class ZipDownloadController extends ChangeNotifier {
  ZipDownloadState _state = ZipDownloadState();
  ZipDownloadState get state => _state;

  CancellationToken? _token;
  bool _disposed = false;

  void _setState(ZipDownloadState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  void disposeController() {
    _disposed = true;
    _token?.cancel();
    super.dispose();
  }

  Future<void> download(String ownerRepo, {ZipProvider provider = ZipProvider.github}) async {
    if (_state.status == AsyncStatus.loading) return;
    // create a fresh token for this run
    _token?.cancel();
    _token = CancellationToken();

    _setState(_state.copyWith(status: AsyncStatus.loading, progress: 0.0, downloadedBytes: 0, totalBytes: null, message: null));
    try {
      final token = _token!;
      late final File file;
      // Route to the selected provider's service
        if( provider == ZipProvider.github) {
          file = await GitHubZipService.instance.downloadRepoZip(ownerRepo, token: token, onProgress: (dl, total) {
            if (token.isCanceled) return;
            final p = (total != null && total > 0) ? (dl / total) : 0.0;
            _setState(_state.copyWith(progress: p.clamp(0.0, 1.0), downloadedBytes: dl, totalBytes: total));
          });
        }
        if(provider == ZipProvider.gitlab) {
          file = await GitLabZipService.instance.downloadRepoZip(ownerRepo, token: token, onProgress: (dl, total) {
            if (token.isCanceled) return;
            final p = (total != null && total > 0) ? (dl / total) : 0.0;
            _setState(_state.copyWith(progress: p.clamp(0.0, 1.0), downloadedBytes: dl, totalBytes: total));
          });
        }
        if( provider == ZipProvider.bitbucket) {
          
          file = await BitbucketZipService.instance.downloadRepoZip(ownerRepo, token: token, onProgress: (dl, total) {
            if (token.isCanceled) return;
            final p = (total != null && total > 0) ? (dl / total) : 0.0;
            _setState(_state.copyWith(progress: p.clamp(0.0, 1.0), downloadedBytes: dl, totalBytes: total));
          });
        }
      if (token.isCanceled) throw OperationCanceledException();

      final fileSize = await file.length();
      // save path separately and show an ephemeral owner/repo success message
      _setState(_state.copyWith(status: AsyncStatus.success, progress: 1.0, downloadedBytes: fileSize, totalBytes: fileSize, message: ownerRepo, savedPath: file.path));

      // show toast and then clear ephemeral message after a short delay
      GzipToast.show('Downloaded $ownerRepo', duration: 2500);
      Future.delayed(const Duration(seconds: 3), () {
        // only clear ephemeral message if still success and savedPath unchanged
        if (_disposed) return;
        _setState(_state.copyWith(message: null));
      });
    } on OperationCanceledException {
      _setState(_state.copyWith(status: AsyncStatus.idle, progress: 0.0, downloadedBytes: 0, totalBytes: null, message: 'Cancelled'));
    } catch (e) {
      final msg = e is Exception ? e.toString() : 'Unknown error';
      _setState(_state.copyWith(status: AsyncStatus.error, message: msg));
    } finally {
      _token = null;
    }
  }

  void cancel() {
    _token?.cancel();
  }
}

final zipDownloadControllerProvider = ChangeNotifierProvider.autoDispose<ZipDownloadController>((ref) {
  final c = ZipDownloadController();
  ref.onDispose(() => c.disposeController());
  return c;
});
