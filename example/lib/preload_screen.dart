import 'package:flutter/material.dart';
import 'package:mexa_ads/mexa_ads.dart';
import 'package:mexa_ads/utils.dart';
import 'package:mexa_ads_example/ad_demo_screen.dart';

class PreloadScreen extends StatefulWidget {
  const PreloadScreen({super.key});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> {
  bool _nativePreloaded = false;
  bool _bannerPreloaded = false;
  bool _collapsiblePreloaded = false;

  bool _nativeLoading = false;
  bool _bannerLoading = false;
  bool _collapsibleLoading = false;

  void _preloadNative() async {
    setState(() => _nativeLoading = true);
    final result = await MexaAds.instance.preloadNative(
      placement: 'native_1',
      size: NativeAdSize.layout1,
      adCTABackgroundColor: [
        const Color(0xffFFA17A),
        const Color(0xffB50AC1),
      ],
      gradientOrientation: GradientOrientation.leftToRight,
    );
    if (mounted) {
      setState(() {
        _nativePreloaded = result;
        _nativeLoading = false;
      });
    }
    logger("Preload native: $result");
  }

  void _preloadBanner() async {
    setState(() => _bannerLoading = true);
    final screenWidth = MediaQuery.of(context).size.width.truncate();
    final result = await MexaAds.instance.preloadBannerAnchor(
      placement: 'banner_1',
      screenWidth: screenWidth,
    );
    if (mounted) {
      setState(() {
        _bannerPreloaded = result;
        _bannerLoading = false;
      });
    }
    logger("Preload banner: $result");
  }

  void _preloadCollapsible() async {
    setState(() => _collapsibleLoading = true);
    final screenWidth = MediaQuery.of(context).size.width.truncate();
    final result = await MexaAds.instance.preloadCollapsible(
      placement: 'collap_1',
      screenWidth: screenWidth,
    );
    if (mounted) {
      setState(() {
        _collapsiblePreloaded = result;
        _collapsibleLoading = false;
      });
    }
    logger("Preload collapsible: $result");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Preload Ads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Preload ads trước khi vào app',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPreloadButton(
              label: 'Preload Native Ad',
              isLoading: _nativeLoading,
              isPreloaded: _nativePreloaded,
              onPressed: _preloadNative,
            ),
            const SizedBox(height: 16),
            _buildPreloadButton(
              label: 'Preload Banner Anchor Ad',
              isLoading: _bannerLoading,
              isPreloaded: _bannerPreloaded,
              onPressed: _preloadBanner,
            ),
            const SizedBox(height: 16),
            _buildPreloadButton(
              label: 'Preload Collapsible Ad',
              isLoading: _collapsibleLoading,
              isPreloaded: _collapsiblePreloaded,
              onPressed: _preloadCollapsible,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdDemoScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Vào App →',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreloadButton({
    required String label,
    required bool isLoading,
    required bool isPreloaded,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading || isPreloaded ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isPreloaded
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.download),
      label: Text(
        isPreloaded ? '$label ✓' : label,
        style: const TextStyle(fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
