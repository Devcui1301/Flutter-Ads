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

enum NativeAdSize {
  layout1,
  layout2,
  layout3,
  layout4,
  fullScreen,
  noMedia,
  noMedia2,
  custom1,
  custom2,
}

enum AdType {
  banner,
  bannerCollapsible,
  native,
  rewarded,
  interstitial,
  appOpen,
}

extension AdTypeExt on AdType {
  String get value {
    switch (this) {
      case AdType.banner:
        return "Banner";
      case AdType.bannerCollapsible:
        return "BannerCollapsible";
      case AdType.native:
        return "Native";
      case AdType.rewarded:
        return "Rewarded";
      case AdType.interstitial:
        return "Interstitial";
      case AdType.appOpen:
        return "AppOpen";
    }
  }
}

const String debugInterId = "ca-app-pub-3940256099942544/1033173712";
const String debugNativeId = "/6499/example/native";
const String debugAOAId = "ca-app-pub-3940256099942544/9257395921";
const String debugBannerId = "ca-app-pub-3940256099942544/6300978111";
const String debugRewardId = "ca-app-pub-3940256099942544/5224354917";
const String debugBannerCollapsibleId =
    "ca-app-pub-3940256099942544/2014213617";

String getTestAdUnitId(AdType type) {
  switch (type) {
    case AdType.interstitial:
      return debugInterId;
    case AdType.native:
      return debugNativeId;
    case AdType.appOpen:
      return debugAOAId;
    case AdType.banner:
      return debugBannerId;
    case AdType.rewarded:
      return debugRewardId;
    case AdType.bannerCollapsible:
      return debugBannerCollapsibleId;
  }
}
