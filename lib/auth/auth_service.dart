import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rento_user.dart';

/// Manages all authentication operations against Supabase.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _supabase = Supabase.instance.client;

  RentoUser? _currentUser;
  RentoUser? get currentUser => _currentUser;
  bool get loggedIn => _currentUser != null;
  String get currentUserUid => _currentUser?.uid ?? '';
  String get currentUserEmail => _currentUser?.email ?? '';
  String get currentUserDisplayName => _currentUser?.displayName ?? '';
  String get currentUserPhoto => _currentUser?.photoUrl ?? '';

  StreamSubscription<AuthState>? _authSub;
  String _jwtToken = '';
  String get jwtToken => _jwtToken;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// True when a brand-new account was just created (sign-up or first Google login).
  /// Reset to false after it has been consumed (read once by the router/page).
  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;
  void consumeNewUser() {
    _isNewUser = false;
  }

  /// Begins listening to auth-state changes from Supabase.
  void initialize() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = RentoUser(session.user);
      _jwtToken = session.accessToken;
    }
    _initialized = true;

    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;

      if (user != null) {
        _currentUser = RentoUser(user);
        _jwtToken = data.session!.accessToken;

        // Mark as new user on first sign-up or first OAuth login
        if (event == AuthChangeEvent.signedIn) {
          final createdAt = user.createdAt;
          final now = DateTime.now();
          // Consider "new" if account was created within the last 30 seconds
          if (createdAt != null) {
            final diff = now.difference(DateTime.parse(createdAt)).abs();
            _isNewUser = diff.inSeconds < 30;
          }
        } else if (event == AuthChangeEvent.userUpdated) {
          _isNewUser = false;
        }
      } else {
        _currentUser = null;
        _jwtToken = '';
        _isNewUser = false;
      }
      notifyListeners();
    });
  }

  /// Signs up with email/password. Returns true if user was created.
  /// If email confirmation is OFF in Supabase, session is immediately
  /// available and isNewUser will be true.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.session != null) {
      _isNewUser = true;
    }
    return response.user != null;
  }

  /// Signs in with email/password. Returns true on success.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  /// Initiates Google OAuth.
  /// Navigation after auth is handled reactively by the router
  /// via AuthService.isNewUser.
 Future<bool> signInWithGoogle() async {
    try {
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/'
          : 'io.supabase.rento://login-callback';
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      return true;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _jwtToken = '';
    _isNewUser = false;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<UserResponse> updateEmail(String newEmail) async {
    return await _supabase.auth.updateUser(UserAttributes(email: newEmail));
  }

  Future<void> deleteUser() async {
    await signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}