import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'admob_ads_method_channel.dart';

abstract class AdmobAdsPlatform extends PlatformInterface {
  /// Constructs a AdmobAdsPlatform.
  AdmobAdsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdmobAdsPlatform _instance = MethodChannelAdmobAds();
  static AdmobAdsPlatform get instance => _instance;

  static set instance(AdmobAdsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void disposeCollapsibleAdLoad();

  void pauseCollapsibleAdLoad(String placement);

  void resumeCollapsibleAdLoad(String placement);
}
