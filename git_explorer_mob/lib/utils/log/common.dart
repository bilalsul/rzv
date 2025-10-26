import 'dart:io';

import 'package:git_explorer_mob/config/shared_preference_provider.dart';
import 'package:git_explorer_mob/utils/log/string_to_level.dart';
import 'package:git_explorer_mob/utils/get_path/log_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class GitExpLog {
  static final log = Logger('GitExplorerLog');
  static late File? logFile;

  Level level;
  DateTime time;
  String message;

  GitExpLog(this.level, this.time, this.message);

  get color => level == Level.SEVERE
      ? Colors.red
      : level == Level.WARNING
          ? Colors.orange
          : Colors.grey;

  static GitExpLog parse(String log) {
    try {
      final logParts = log.split('^*^');
      final level = stringToLevel(logParts[0]);
      final time = DateTime.parse(logParts[1].trim());
      final message = logParts[2];
      return GitExpLog(level, time, message);
    } catch (e) {
      return GitExpLog(Level.SEVERE, DateTime.now(), 'Parse log error: $e');
    }
  }

  static init() async {
    logFile = await getLogFile();

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        String colorCode = '';
        if (record.level == Level.SEVERE) {
          colorCode = '\x1B[31m';
        } else if (record.level == Level.WARNING) {
          colorCode = '\x1B[33m';
        } else if (record.level == Level.INFO) {
          colorCode = '\x1B[34m';
        }
        print(
            '$colorCode${record.level.name}: ${record.time}: ${record.message} \x1B[0m');
        if (record.error != null) {
          print('$colorCode${record.error} \x1B[0m');
        }
        if (record.stackTrace != null) {
          print('$colorCode${record.stackTrace} \x1B[0m');
        }
      }
      String error = record.error == null ? '' : ' : ${record.error}';
      logFile!.writeAsStringSync(
          '${'${record.level.name}^*^ ${record.time}^*^ [${record.message}]$error,${record.stackTrace}'.replaceAll('\n', ' ')}\n',
          mode: FileMode.append);
    });
    if (Prefs().clearLogWhenStart) {
      clear();
    }
    info('Log file: ${logFile!.path}');
  }

  static void clear() {
    logFile!.writeAsStringSync('');
  }

  static info(String message, [Object? error, StackTrace? stackTrace]) {
    log.info(message, error, stackTrace);
  }

  static warning(String message, [Object? error, StackTrace? stackTrace]) {
    log.warning(message, error, stackTrace);
  }

  static severe(String message, [Object? error, StackTrace? stackTrace]) {
    stackTrace ??= StackTrace.current;
    log.severe(message, error, stackTrace);
  }
}
