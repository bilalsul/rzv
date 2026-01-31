import 'dart:ui';

import 'package:rzv/utils/log/common.dart';
import 'package:flutter/material.dart';

class GitExpError {
  static Future<void> init() async {
    GitExpLog.info('GitExp init');
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      GitExpLog.severe(details.exceptionAsString(), details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      GitExpLog.severe(error.toString(), stack);
      return false;
    };
  }
}
