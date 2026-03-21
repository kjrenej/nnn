import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for the Rento app.
///
/// For production builds, provide secrets via --dart-define or CI environment:
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// SECURITY: Do NOT hardcode production keys in this file.
/// SECURITY: Do NOT include .env in flutter assets for production builds.
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────

  static String get supabaseUrl {
    // Prefer --dart-define over .env for production security
    const defineUrl = String.fromEnvironment('SUPABASE_URL');
    if (defineUrl.isNotEmpty) return defineUrl;

    final envUrl = dotenv.env['SUPABASE_URL'] ?? '';
    // FIX: Removed hardcoded Supabase URL fallback.
    // If the env var is missing, fail fast with a clear error instead of
    // silently using a hardcoded URL that may be from a different project.
    assert(
      envUrl.isNotEmpty,
      'SUPABASE_URL is not set. Add it to .env or pass via --dart-define.',
    );
    return envUrl;
  }

  static String get supabaseAnonKey {
    const defineKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (defineKey.isNotEmpty) return defineKey;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // ── Razorpay ──────────────────────────────────────────────

  static String get razorpayKeyId {
    const defineKey = String.fromEnvironment('RAZORPAY_KEY_ID');
    if (defineKey.isNotEmpty) return defineKey;

    final envKey = dotenv.env['RAZORPAY_KEY_ID'] ?? '';
    // FIX: Removed hardcoded Razorpay test key.
    // Ship the real production key via CI --dart-define, NOT in .env or source.
    if (kDebugMode && envKey.isEmpty) {
      debugPrint(
        '[AppConfig] WARNING: RAZORPAY_KEY_ID not set. '
        'Payments will not work.',
      );
    }
    return envKey;
  }

  // ── Google Maps ───────────────────────────────────────────

  static String get googleMapsApiKey {
    const defineKey = String.fromEnvironment('GOOGLE_MAPS_KEY');
    if (defineKey.isNotEmpty) return defineKey;
    return dotenv.env['GOOGLE_MAPS_KEY'] ?? '';
  }

  // ── Google Gemini AI ──────────────────────────────────────

  static String get geminiApiKey {
    const defineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (defineKey.isNotEmpty) return defineKey;
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  // ── Storage bucket ────────────────────────────────────────

  static const String storageBucket = 'property-images';
}