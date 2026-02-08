import '../../services/state/async_status.dart';

class ZipDownloadState {
  final AsyncStatus status;
  final double progress; // 0.0 - 1.0
  final int downloadedBytes;
  final int? totalBytes;
  final String? message;
  final String? savedPath;

  const ZipDownloadState({
    this.status = AsyncStatus.idle,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes,
    this.message,
    this.savedPath,
  });

  ZipDownloadState copyWith({AsyncStatus? status, double? progress, int? downloadedBytes, int? totalBytes, String? message, String? savedPath}) {
    return ZipDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      message: message ?? this.message,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}
