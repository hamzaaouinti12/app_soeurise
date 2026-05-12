# Guide de Déploiement et Test - Soeurise

## Configuration Requise

### Pour le Développement
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio + Android SDK (pour Android)
- Xcode (pour iOS)
- VS Code ou Android Studio comme IDE

### Pour la Production
- Backend Node.js/Express configuré et déployé
- Base de données MongoDB accessible
- Certificats SSL/HTTPS pour l'API
- Compte Stripe (pour les paiements)
- Service de stockage cloud (AWS S3, Firebase Storage, etc.)

## Installation Locale

### 1. Configuration de l'Environnement Flutter

```bash
# Vérifier l'installation
flutter doctor

# Résoudre les problèmes identifiés
flutter doctor -v
```

### 2. Cloner et Configurer le Projet

```bash
# Naviguer jusqu'au répertoire du projet
cd path/to/soeurise

# Récupérer les dépendances
flutter pub get

# Générer les fichiers de build
flutter pub upgrade
```

## Exécution Locale

### Sur Émulateur Android

```bash
# Démarrer l'émulateur
emulator -avd Pixel_4_API_30

# Exécuter l'application
flutter run

# Exécuter avec logs
flutter run -v
```

### Sur Émulateur iOS

```bash
# Démarrer l'émulateur
open -a Simulator

# Exécuter l'application
flutter run -d sim

# Exécuter sur un device spécifique
flutter run -d "iPhone 14"
```

### Sur Appareil Physique

```bash
# Lister les appareils connectés
flutter devices

# Exécuter sur un appareil spécifique
flutter run -d <device_id>
```

## Tests

### Tests Unitaires

```dart
// test/services_test.dart
import 'package:test/test.dart';
import 'package:soeurise/services.dart';

void main() {
  group('ValidationService', () {
    test('validateEmail with valid email', () {
      final result = ValidationService.validateEmail('user@example.com');
      expect(result, null);
    });

    test('validateEmail with invalid email', () {
      final result = ValidationService.validateEmail('invalid-email');
      expect(result, isNotNull);
    });

    test('validatePassword with weak password', () {
      final result = ValidationService.validatePassword('weak');
      expect(result, isNotNull);
    });

    test('validatePassword with strong password', () {
      final result = ValidationService.validatePassword('StrongPassword123');
      expect(result, null);
    });
  });
}
```

Exécution des tests:
```bash
flutter test
flutter test --coverage
```

### Tests de Widget

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soeurise/main.dart';

void main() {
  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    expect(find.text('Soeurise'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Navigation works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Login
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    
    // Vérifier que le MainApp s'affiche
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
```

## Configuration Backend

### Variables d'Environnement

Créer un fichier `.env` à la racine du projet:

```
BACKEND_URL=http://localhost:3000
API_BASE_URL=http://localhost:3000/api
WORDPRESS_API=https://example.com/wp-json
STRIPE_PUBLIC_KEY=pk_test_...
DEBUG_MODE=true
```

Charger dans main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

// Accéder:
String backendUrl = dotenv.env['BACKEND_URL'] ?? '';
```

### Configuration API

Mettre à jour `constants.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.100:3000/api';
  static const String wpApiUrl = 'https://api.soeurise.com/wp-json';
  static const String stripePublicKey = 'pk_test_xxx';
}
```

## Déploiement

### Build APK (Android)

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK (multi-architecture)
flutter build apk --split-per-abi
```

Fichiers générés: `build/app/outputs/flutter-apk/`

### Build IPA (iOS)

```bash
# Release build
flutter build ios --release

# Générer IPA
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -config Release -derivedDataPath build -archivePath build/Runner.xcarchive
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/ipa
```

### Build Web

```bash
flutter build web --release
```

Héberger dans: `build/web/`

## Déploiement Firebase

### Configuration

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter à Firebase
firebase login

# Initialiser le projet
firebase init hosting
```

### Déploiement App Android

```bash
# Via Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --release-notes "Version 1.0" \
  --testers "dev@example.com"
```

### Déploiement Site Web

```bash
flutter build web --release
firebase deploy --only hosting
```

## Monitoring et Analytics

### Firebase Analytics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logPostCreation() async {
    await _analytics.logEvent(name: 'post_created');
  }

  static Future<void> logEventRegistration(String eventId) async {
    await _analytics.logEvent(
      name: 'event_registered',
      parameters: {'event_id': eventId},
    );
  }
}
```

### Crash Reporting

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
  };
}
```

## Performance Optimization

### Code Optimization
```bash
# Analyser la performance
flutter analyze

# Build optimisé
flutter build apk --split-per-abi --release
```

### Image Optimization
```dart
// Utiliser des images optimisées
Image.network(
  url,
  cacheHeight: 200,
  cacheWidth: 200,
  fit: BoxFit.cover,
)
```

### Lazy Loading
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return PostCard(post: items[index]);
  },
)
```

## CI/CD Pipeline

### GitHub Actions

Créer `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
      
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v2
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### Problèmes Courants

1. **"Flutter command not found"**
   ```bash
   export PATH="$PATH:~/flutter/bin"
   ```

2. **"CocoaPods error" sur iOS**
   ```bash
   cd ios
   pod install --repo-update
   cd ..
   ```

3. **"Android Studio SDK not found"**
   ```bash
   flutter config --android-sdk /path/to/android/sdk
   ```

4. **"Gradle sync failed"**
   ```bash
   rm -rf android/.gradle
   flutter clean
   flutter pub get
   ```

## Support et Documentation

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Setup](https://firebase.google.com/docs/flutter/setup)
- [PlayStore Publishing](https://developer.android.com/distribute/console)
- [App Store Publishing](https://developer.apple.com/app-store/)
