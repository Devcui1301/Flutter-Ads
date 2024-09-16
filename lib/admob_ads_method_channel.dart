import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'admob_ads_platform_interface.dart';

/// An implementation of [AdmobAdsPlatform] that uses method channels.
class MethodChannelAdmobAds extends AdmobAdsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('admob_ads');

  @override
  void disposeCollapsibleAdLoad() {
    methodChannel.invokeMethod<String>('disposeCollapsibleAdLoad');
  }

  @override
  void pauseCollapsibleAdLoad(String placement) {
    methodChannel.invokeMethod<String>(
      'pauseCollapsibleAdLoad',
      {
        'placement': placement,
      },
    );
  }

  @override
  void resumeCollapsibleAdLoad(String placement) {
    methodChannel.invokeMethod<String>(
      'resumeCollapsibleAdLoad',
      {
        'placement': placement,
      },
    );
  }
}
