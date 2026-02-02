abstract class AppError implements Exception {
  final String message;
  AppError(this.message);
}

class NetworkError extends AppError {
  NetworkError(String message) : super(message);
}

class InvalidRepoError extends AppError {
  InvalidRepoError(String message) : super(message);
}

class ZipCorruptError extends AppError {
  ZipCorruptError(String message) : super(message);
}

class PermissionError extends AppError {
  PermissionError(String message) : super(message);
}

class ExtractionError extends AppError {
  ExtractionError(String message) : super(message);
}

enum AsyncStatus { idle, loading, success, error }
