import 'package:flutter/material.dart';

// ─── App Colors – Soft Pink & Beige Premium Palette ───
class AppColors {
  // Primary pinks
  static const Color primary = Color(0xFFE8758F);      // Warm rose
  static const Color primaryLight = Color(0xFFF4A0B5);  // Soft pink
  static const Color primaryDark = Color(0xFFD4536E);   // Deep rose

  // Beige & neutrals
  static const Color beige = Color(0xFFF5E6D3);         // Warm beige
  static const Color beigeLight = Color(0xFFFFF5EB);     // Light cream
  static const Color beigeDark = Color(0xFFE8D5C0);      // Darker beige
  static const Color cream = Color(0xFFFFFCF9);          // Off-white cream

  // Background
  static const Color background = Color(0xFFFFF8F2);     // Warm white
  static const Color surface = Color(0xFFFFFAF6);        // Card background
  static const Color surfaceGlass = Color(0x40FFFFFF);   // Glass card bg

  // Text
  static const Color textPrimary = Color(0xFF3D2C2C);    // Dark warm brown
  static const Color textSecondary = Color(0xFF8B7070);  // Muted brown
  static const Color textLight = Color(0xFFB89A9A);      // Light brown

  // Functional
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF81C784);
  static const Color warningColor = Color(0xFFFFB74D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8758F), Color(0xFFF4A0B5)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5EB), Color(0xFFFFF0E8), Color(0xFFFFF8F2)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x60FFFFFF), Color(0x30FFFFFF)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8758F), Color(0xFFD4536E)],
  );
}

// ─── Glassmorphism Tokens ───
class GlassTokens {
  static const double blurAmount = 20.0;
  static const double cardOpacity = 0.25;
  static const double borderOpacity = 0.2;
  static const double borderWidth = 1.0;
  static const Color borderColor = Color(0x33FFFFFF);
}

// ─── App Text Styles ───
class AppTextStyles {
  static const String fontFamily = 'Poppins';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );
}

// ─── App Spacing ───
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// ─── App Border Radius ───
class AppBorderRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double pill = 100;
}

// ─── Animation Durations ───
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Duration splash = Duration(milliseconds: 2500);
  static const Duration stagger = Duration(milliseconds: 80);
}

// ─── API Configuration ───
class ApiConfig {
  // For web: localhost:4000, for Android emulator: 10.0.2.2:4000
  static const String baseUrl = 'http://localhost:4000/api';
  static const String serverUrl = 'http://localhost:4000';
  static const String wpApiUrl = 'https://example.com/wp-json';

  /// Converts a relative upload path (e.g. /uploads/avatars/img.png) to a full URL.
  static String uploadsUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    return '$serverUrl$relativePath';
  }
}

// ─── Feature Flags ───
class FeatureFlags {
  static const bool enableOTP = true;
  static const bool enableSelfieVerification = true;
  static const bool enableStripeIntegration = false;
  static const bool enableModeration = true;
}

// ─── Routes ───
class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String communities = '/communities';
  static const String masterclass = '/masterclass';
  static const String events = '/events';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String postCreation = '/post-creation';
}

// ─── Messages ───
class AppMessages {
  static const String loginSuccess = 'Connexion réussie';
  static const String loginError =
      'Erreur de connexion. Vérifiez vos identifiants.';
  static const String registrationSuccess = 'Inscription réussie';
  static const String registrationError = 'Erreur lors de l\'inscription';
  static const String logoutSuccess = 'Déconnexion réussie';
  static const String networkError = 'Erreur réseau. Vérifiez votre connexion.';
  static const String serverError =
      'Erreur serveur. Veuillez réessayer plus tard.';
  static const String postPublished = 'Publication créée avec succès';
  static const String postFailed =
      'Erreur lors de la création de la publication';
}
