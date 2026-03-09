import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum MexaAdsLogLevel { none, debug, all }

MexaAdsLogLevel _currentLogLevel = MexaAdsLogLevel.debug;

void setMexaAdsLogLevel(MexaAdsLogLevel level) {
  _currentLogLevel = level;
}

void logger(String message) {
  switch (_currentLogLevel) {
    case MexaAdsLogLevel.none:
      break;
    case MexaAdsLogLevel.debug:
      if (kDebugMode) log(message);
      break;
    case MexaAdsLogLevel.all:
      if (kDebugMode) {
        log(message);
      } else {
        // In release mode, use print to ensure logs appear in Logcat
        print(message);
      }
      break;
  }
}

String colorToHexString(Color? color, {bool leadingHashSign = true}) => color ==
        null
    ? ''
    : '${leadingHashSign ? '#' : ''}'
        '${(color.a * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${(color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${(color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${(color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
List<String> convertColorsToHex(List<Color>? colors) {
  if (colors == null) return [];
  return colors.map((color) => colorToHexString(color)).toList();
}

enum GradientOrientation {
  leftToRight,
  topToBottom,
  rightToLeft,
  bottomToTop,
  bottomLeftToTopRight,
  bottomRightToTopLeft,
  topLeftToBottomRight,
  topRightToBottomLeft,
}

// Hàm để chuyển enum thành giá trị String
String gradientOrientationToString(GradientOrientation orientation) {
  switch (orientation) {
    case GradientOrientation.leftToRight:
      return "LEFT_RIGHT";
    case GradientOrientation.topToBottom:
      return "TOP_BOTTOM";
    case GradientOrientation.rightToLeft:
      return "RIGHT_LEFT";
    case GradientOrientation.bottomToTop:
      return "BOTTOM_TOP";
    case GradientOrientation.bottomLeftToTopRight:
      return "BL_TR";
    case GradientOrientation.bottomRightToTopLeft:
      return "BR_TL";
    case GradientOrientation.topLeftToBottomRight:
      return "TL_BR";
    case GradientOrientation.topRightToBottomLeft:
      return "TR_BL";
  }
}
