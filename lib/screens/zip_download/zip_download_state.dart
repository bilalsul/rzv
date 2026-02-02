import 'package:flutter/foundation.dart';
import '../../services/state/async_status.dart';

class ZipDownloadState {
  final AsyncStatus status;
  final double progress; // 0.0 - 1.0
  final String? message;

  ZipDownloadState({this.status = AsyncStatus.idle, this.progress = 0.0, this.message});

  ZipDownloadState copyWith({AsyncStatus? status, double? progress, String? message}) {
    return ZipDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
    );
  }
}
