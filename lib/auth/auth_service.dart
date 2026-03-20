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

  /// Begins listening to auth-state changes from Supabase.
  void initialize() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = RentoUser(session.user);
      _jwtToken = session.accessToken;
    }
    _initialized = true;

    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _currentUser = RentoUser(user);
        _jwtToken = data.session!.accessToken;
      } else {
        _currentUser = null;
        _jwtToken = '';
      }
      notifyListeners();
    });
  }

  // ── Email / Password auth ───────────────────────────────

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    return response;
  }

  Future<bool> signInWithGoogle() async {
    try {
      // On web, omit redirectTo so Supabase redirects back to the current
      // site URL (e.g. http://localhost:3000). On mobile, use the custom
      // deep-link scheme registered in AndroidManifest / Info.plist.
      final redirectUrl = kIsWeb ? null : 'io.supabase.rento://login-callback';
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

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _jwtToken = '';
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
    // Requires a server-side function or service-role key.
    // Client-side deletion is not supported by default.
    await signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
