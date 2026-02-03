import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppDirectories {
  static const _appFolder = 'rzv';
  static const _zips = 'zips';
  // static const _extracted = 'extracted';

  /// Returns the application support directory for the app.
  static Future<Directory> applicationSupport() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'ApplicationSupportDirectory', _appFolder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> zipsDirectory() async {
    final base = await applicationSupport();
    final dir = Directory(p.join(base.path, _zips));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> extractedDirectory() async {
    final docsBase = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsBase.path, 'projects'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String extractionFolderNameForZip(String zipFilename) {
    return p.basenameWithoutExtension(zipFilename);
  }
}
