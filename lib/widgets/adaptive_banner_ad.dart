import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Bannière AdMob adaptative, collapsible, avec rechargement automatique
/// à la rotation d'écran et retry en cas d'échec de chargement.
class AdaptiveBannerAd extends StatefulWidget {
  final String adUnitId;
  final String collapsiblePosition; // 'bottom' ou 'top'

  const AdaptiveBannerAd({
    super.key,
    required this.adUnitId,
    this.collapsiblePosition = 'bottom',
  });

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  double? _lastWidth;
  int _retryAttempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeReloadBanner();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeReloadBanner();
    });
  }

  void _maybeReloadBanner() {
    final currentWidth = MediaQuery.of(context).size.width;
    if (_lastWidth != null && (_lastWidth! - currentWidth).abs() < 1) return;
    _lastWidth = currentWidth;
    _retryAttempt = 0;
    _loadAdaptiveBanner(currentWidth);
  }

  Future<void> _loadAdaptiveBanner(double width) async {
    final canRequest = await ConsentInformation.instance.canRequestAds();
    if (!canRequest) return;

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );
    if (size == null) return;

    final oldBanner = _bannerAd;
    if (mounted) setState(() => _isLoaded = false);

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: AdRequest(
        extras: {'collapsible': widget.collapsiblePosition},
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _retryAttempt = 0;
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (identical(_bannerAd, ad)) {
            _bannerAd = null;
          }
          ad.dispose();
          _retryWithBackoff(width);
        },
      ),
    )..load();

    oldBanner?.dispose();
  }

  void _retryWithBackoff(double width) {
    if (_retryAttempt >= 3) return;
    _retryAttempt++;
    final delaySeconds = 2 * _retryAttempt;
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted) _loadAdaptiveBanner(width);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SafeArea(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
