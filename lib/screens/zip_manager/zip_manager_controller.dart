import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/filesystem/zip_storage_manager.dart';
import '../../services/filesystem/app_directories.dart';
import '../../services/filesystem/extraction_service.dart';
import '../../services/state/side_effect_handler.dart';
import '../../services/state/async_status.dart';

class ZipManagerController extends ChangeNotifier {
  List<ZipEntry> entries = [];
  AsyncStatus status = AsyncStatus.idle;
  String? message;

  final CancellationToken _token = CancellationToken();

  Future<void> refresh() async {
    status = AsyncStatus.loading;
    notifyListeners();
    try {
      entries = await ZipStorageManager.instance.listZips();
      status = AsyncStatus.success;
    } catch (e) {
      status = AsyncStatus.error;
      message = e.toString();
    }
    notifyListeners();
  }

  Future<bool> isExtracted(String filename) async {
    final extractedRoot = await AppDirectories.extractedDirectory();
    final folder = Directory('${extractedRoot.path}/${AppDirectories.extractionFolderNameForZip(filename)}');
    return await folder.exists();
  }

  Future<void> extract(String filename, {void Function(int,int)? onProgress}) async {
    status = AsyncStatus.loading;
    notifyListeners();
    try {
      final file = await ZipStorageManager.instance.fileForZip(filename);
      await ExtractionService.instance.extractZipFile(file, token: _token, onProgress: (a,b){ if(onProgress!=null) onProgress(a,b);});
      status = AsyncStatus.success;
    } catch (e) {
      status = AsyncStatus.error;
      message = e.toString();
    }
    notifyListeners();
  }

  Future<void> deleteZip(String filename) async {
    await ZipStorageManager.instance.deleteZip(filename);
    await refresh();
  }

  Future<void> deleteExtraction(String filename) async {
    final extractedRoot = await AppDirectories.extractedDirectory();
    final folder = Directory('${extractedRoot.path}/${AppDirectories.extractionFolderNameForZip(filename)}');
    if (await folder.exists()) await folder.delete(recursive: true);
    await refresh();
  }

  Future<void> reExtract(String filename) async {
    await deleteExtraction(filename);
    await extract(filename);
  }

  Future<void> deleteAllZips() async {
    await ZipStorageManager.instance.deleteAllZips();
    await refresh();
  }

  void cancel() {
    _token.cancel();
  }
}

final zipManagerControllerProvider = ChangeNotifierProvider.autoDispose<ZipManagerController>((ref) {
  final c = ZipManagerController();
  ref.onDispose(() => c.cancel());
  return c;
});
