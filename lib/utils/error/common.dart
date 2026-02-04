import 'dart:ui';

import 'package:rzv/utils/log/common.dart';
import 'package:flutter/material.dart';

class RZVError {
  static Future<void> init() async {
    RZVLog.info('RZV Error init');
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      RZVLog.severe(details.exceptionAsString(), details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      RZVLog.severe(error.toString(), stack);
      return false;
    };
  }
}
