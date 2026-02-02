import 'dart:async';

/// Lightweight cancellation token.
class CancellationToken {
  bool _isCanceled = false;
  final _controller = StreamController<void>.broadcast();

  bool get isCanceled => _isCanceled;

  Stream<void> get onCancel => _controller.stream;

  void cancel() {
    if (!_isCanceled) {
      _isCanceled = true;
      _controller.add(null);
      _controller.close();
    }
  }

  void throwIfCanceled() {
    if (_isCanceled) throw OperationCanceledException();
  }
}

class OperationCanceledException implements Exception {}

/// A small helper to run async work that can be cancelled.
class SideEffectHandler {
  SideEffectHandler();

  /// For long-running tasks, pass in a callback that listens to [token]
  /// and cooperatively checks cancellation.
  Future<T> runCancellable<T>(Future<T> Function(CancellationToken token) work, CancellationToken token) async {
    return work(token);
  }
}
