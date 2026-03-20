import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for the Rento app.
///
/// **IMPORTANT**: For production, replace these with values from
/// `--dart-define` or a secure secrets manager. Never ship hardcoded keys.
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://mrxnzarmxhlmokfpygux.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // ── Razorpay ──────────────────────────────────────────────
  static String get razorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_SOT9U2YOPczkGy';

  // ── Google Maps ───────────────────────────────────────────
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_KEY'] ?? '';

  // ── Google Gemini AI ──────────────────────────────────────
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ── Storage bucket ────────────────────────────────────────
  static const String storageBucket = 'property-images';
}
