import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global application state (singleton ChangeNotifier).
/// Persists role flags in shared preferences (web-compatible).
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  late final SharedPreferences _prefs;

  // ── Persisted fields ─────────────────────────────────────

  bool _isRentee = false;
  bool get isRentee => _isRentee;
  set isRentee(bool v) {
    _isRentee = v;
    _prefs.setBool('rentee', v);
    notifyListeners();
  }

  bool _isLandlord = false;
  bool get isLandlord => _isLandlord;
  set isLandlord(bool v) {
    _isLandlord = v;
    _prefs.setBool('landlord', v);
    notifyListeners();
  }

  // ── Transient fields ─────────────────────────────────────

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  set isDarkMode(bool v) {
    _isDarkMode = v;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  String _searchFilter = '';
  String get searchFilter => _searchFilter;
  set searchFilter(String v) {
    _searchFilter = v;
    notifyListeners();
  }

  String _selectedLocale = 'en';
  String get selectedLocale => _selectedLocale;
  set selectedLocale(String v) {
    _selectedLocale = v;
    notifyListeners();
  }

  void setLocale(String code) {
    _selectedLocale = code;
    notifyListeners();
  }

  // ── Initializer ──────────────────────────────────────────

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isRentee = _prefs.getBool('rentee') ?? false;
    _isLandlord = _prefs.getBool('landlord') ?? false;
    notifyListeners();
  }

  /// Resets state (called on sign-out).
  /// FIX: Only removes app-specific keys instead of clearing ALL preferences.
  /// Previously called _prefs.clear() which deleted data from other packages
  /// that also use SharedPreferences (e.g., recent search history).
  Future<void> reset() async {
    _isRentee = false;
    _isLandlord = false;
    _searchFilter = '';
    await _prefs.remove('rentee');
    await _prefs.remove('landlord');
    notifyListeners();
  }
}