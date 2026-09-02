import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Filet de sécurité : si l'initialisation RGPD/AdMob plante ou traîne
  // (ex: premier lancement après installation, réseau lent), l'app ne
  // doit JAMAIS rester bloquée sur un écran blanc. On lui laisse 5
  // secondes max, sinon on démarre quand même — les pubs se chargeront
  // simplement un peu plus tard, une fois l'app affichée.
  try {
    await _initAdsFlow().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Timeout ou erreur inattendue : on continue sans bloquer le démarrage.
  }
  runApp(const MyApp());
}

/// Ordre obligatoire : consentement RGPD (UMP) -> tracking iOS (ATT)
/// -> initialisation AdMob. Ne jamais inverser cet ordre.
Future<void> _initAdsFlow() async {
  final completer = Completer<void>();
  final params = ConsentRequestParameters();

  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
    () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        await _loadAndShowConsentForm();
      }
      await _requestTrackingIfNeeded();
      await _initializeMobileAdsIfAllowed();
      completer.complete();
    },
    (error) async {
      // En cas d'échec de récupération du consentement, on initialise quand
      // même (AdMob affichera des pubs non personnalisées par défaut).
      await _initializeMobileAdsIfAllowed();
      completer.complete();
    },
  );

  return completer.future;
}

Future<void> _loadAndShowConsentForm() {
  final completer = Completer<void>();
  ConsentForm.loadConsentForm(
    (consentForm) async {
      final status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.required) {
        consentForm.show((formError) => completer.complete());
      } else {
        completer.complete();
      }
    },
    (formError) => completer.complete(),
  );
  return completer.future;
}

Future<void> _requestTrackingIfNeeded() async {
  if (!Platform.isIOS) return;
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

Future<void> _initializeMobileAdsIfAllowed() async {
  final canRequest = await ConsentInformation.instance.canRequestAds();
  if (canRequest) {
    await MobileAds.instance.initialize();
    // Décommente et renseigne ton device ID pendant le développement
    // pour recevoir des pubs de test (voir logs console au 1er lancement) :
    // await MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: ['TON_DEVICE_ID_ICI']),
    // );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charge utile camping-car',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
