import 'dart:io';
import 'package:path/path.dart' as p;
import 'app_directories.dart';

class ZipEntry {
  final String filename;
  final int size;
  final DateTime modified;

  ZipEntry({required this.filename, required this.size, required this.modified});
}

class ZipStorageManager {
  ZipStorageManager._();
  static final instance = ZipStorageManager._();

  Future<File> fileForZip(String filename) async {
    final dir = await AppDirectories.zipsDirectory();
    return File(p.join(dir.path, filename));
  }

  Future<List<ZipEntry>> listZips() async {
    final dir = await AppDirectories.zipsDirectory();
    final files = await dir.list().toList();
    final zips = <ZipEntry>[];
    for (final f in files) {
      if (f is File && f.path.endsWith('.zip')) {
        final stat = await f.stat();
        zips.add(ZipEntry(
          filename: p.basename(f.path),
          size: stat.size,
          modified: stat.modified,
        ));
      }
    }
    zips.sort((a, b) => b.modified.compareTo(a.modified));
    return zips;
  }

  Future<void> deleteZip(String filename) async {
    final f = await fileForZip(filename);
    if (await f.exists()) await f.delete();
  }

  Future<void> deleteAllZips() async {
    final dir = await AppDirectories.zipsDirectory();
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.zip')) {
        await entity.delete();
      }
    }
  }
}
