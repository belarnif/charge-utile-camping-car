// ⚠️ EXTRAIT À FUSIONNER — ne remplace pas ton fichier généré par `flutter create`.
// Depuis Flutter 3.29, les nouveaux projets utilisent build.gradle.kts (Kotlin DSL)
// par défaut. Si ton projet utilise encore l'ancien build.gradle (Groovy),
// adapte la syntaxe (minSdkVersion 21 au lieu de minSdk = 21, etc.) —
// ne mélange jamais les deux syntaxes dans le même fichier.
//
// Repère le bloc `defaultConfig` existant dans ton android/app/build.gradle.kts
// et assure-toi qu'il contient bien :

android {
    defaultConfig {
        applicationId = "com.tondomaine.chargeutile"
        minSdk = 21   // requis par google_mobile_ads — flutter.minSdkVersion peut être inférieur
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
