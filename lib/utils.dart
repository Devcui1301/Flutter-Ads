import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';

void logger(String message) {
  if (kDebugMode) log(message);
}

String colorToHexString(Color? color, {bool leadingHashSign = true}) =>
    color == null
        ? ''
        : '${leadingHashSign ? '#' : ''}'
            '${color.alpha.toRadixString(16).padLeft(2, '0')}'
            '${color.red.toRadixString(16).padLeft(2, '0')}'
            '${color.green.toRadixString(16).padLeft(2, '0')}'
            '${color.blue.toRadixString(16).padLeft(2, '0')}';
