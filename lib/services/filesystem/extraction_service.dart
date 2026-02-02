import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../state/side_effect_handler.dart';
import 'app_directories.dart';
import '../state/async_status.dart';

typedef ExtractionProgress = void Function(int extractedBytes, int totalBytes);

class ExtractionService {
  ExtractionService._();
  static final instance = ExtractionService._();

  /// Extract a zip file into a managed extraction folder.
  /// Extraction is atomic: files are extracted into a temp folder and
  /// renamed on success.
  Future<void> extractZipFile(File zipFile, {required CancellationToken token, ExtractionProgress? onProgress}) async {
    final totalBytes = await zipFile.length();
    final basename = p.basename(zipFile.path);
    final tempRoot = await AppDirectories.extractedDirectory();
    final tmpDir = Directory(p.join(tempRoot.path, basename + '.tmp'));
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    await tmpDir.create(recursive: true);

    final destDir = Directory(p.join(tempRoot.path, AppDirectories.extractionFolderNameForZip(basename)));

    try {
      final input = InputFileStream(zipFile.path);
      final decoder = ZipDecoder();
      final archive = decoder.decodeBuffer(input);

      int extracted = 0;
      int total = archive.files.fold<int>(0, (s, f) => s + (f.size ?? 0));

      for (final file in archive.files) {
        token.throwIfCanceled();

        final name = file.name;
        // Prevent zip-slip: normalize and ensure it stays inside tmpDir
        final outPath = p.normalize(p.join(tmpDir.path, name));
        if (!p.isWithin(tmpDir.path, outPath)) {
          throw ExtractionError('Invalid entry path in zip: $name');
        }

        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          final bytes = file.content as List<int>;
          await outFile.writeAsBytes(bytes, flush: true);
          extracted += file.size ?? bytes.length;
        } else {
          await Directory(outPath).create(recursive: true);
        }

        if (onProgress != null) onProgress(extracted, total);
      }

      // Rename temp dir to final dest atomically (if exists delete then rename)
      if (await destDir.exists()) {
        await destDir.delete(recursive: true);
      }
      await tmpDir.rename(destDir.path);
    } on OperationCanceledException {
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      rethrow;
    } catch (e) {
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      throw ExtractionError('Failed to extract zip: $e');
    }
  }
}
