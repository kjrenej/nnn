import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rento_user.dart';

/// Manages all authentication operations against Supabase.
///
/// Singleton accessed via [AuthService.instance]. Listens to Supabase
/// auth-state changes and exposes the current user reactively.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ── User state ──────────────────────────────────────────────

  RentoUser? _currentUser;
  RentoUser? get currentUser => _currentUser;
  bool get loggedIn => _currentUser != null;
  String get currentUserUid => _currentUser?.uid ?? '';
  String get currentUserEmail => _currentUser?.email ?? '';
  String get currentUserDisplayName => _currentUser?.displayName ?? '';
  String get currentUserPhoto => _currentUser?.photoUrl ?? '';

  StreamSubscription<AuthState>? _authSub;

  /// Prefer accessing the token from the live session so it's always fresh.
  /// Falls back to empty string when no session exists.
  String get jwtToken => _supabase.auth.currentSession?.accessToken ?? '';

  bool _initialized = false;
  bool get initialized => _initialized;

  /// True when a brand-new account was just created.
  /// Reset to false after it has been consumed (read once by the router/page).
  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;
  void consumeNewUser() {
    _isNewUser = false;
    notifyListeners();
  }

  // ── Initialization ──────────────────────────────────────────

  /// Begins listening to auth-state changes from Supabase.
  /// Must be called once during app startup (e.g. in `main()`).
  void initialize() {
    if (_initialized) return; // guard against double-init

    final session = _supabase.auth.currentSession;
    if (session != null) {
      _currentUser = RentoUser(session.user);
    }
    _initialized = true;
    notifyListeners(); // notify so router evaluates initial state

    _authSub = _supabase.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (Object error) {
        debugPrint('[AuthService] auth stream error: $error');
      },
    );
  }

  void _handleAuthStateChange(AuthState data) {
    final event = data.event;
    final user = data.session?.user;

    if (user != null) {
      _currentUser = RentoUser(user);

      // NOTE: Supabase gotrue v2 does NOT emit a `signedUp` event.
      // New-user detection is handled by signUpWithEmail() setting
      // _isNewUser = true directly. The stream only sees signedIn.
      if (event == AuthChangeEvent.userUpdated) {
        // After profile update, the user is no longer "new".
        _isNewUser = false;
      }
      // signedIn fires for both new and returning users.
      // _isNewUser is only set true by signUpWithEmail().
    } else if (event == AuthChangeEvent.signedOut) {
      _currentUser = null;
      _isNewUser = false;
    }
    notifyListeners();
  }

  // ── Email / Password ────────────────────────────────────────

  /// Signs up with email/password.
  ///
  /// Returns `true` if the user object was created (session may or may not
  /// be immediately available depending on email-confirmation settings).
  /// Throws [AuthException] on Supabase errors (duplicate email, weak
  /// password, etc.) — callers should catch and display the message.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );

    if (response.user != null) {
      // Set immediately so the router can redirect before the stream fires.
      _isNewUser = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Signs in with email/password.
  ///
  /// Returns `true` when a valid session is obtained.
  /// Throws [AuthException] on invalid credentials — callers should catch.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response.session != null;
  }

  // ── OAuth ───────────────────────────────────────────────────

  /// Initiates Google OAuth sign-in.
  ///
  /// On web this opens a popup/redirect; on mobile it launches the browser.
  /// Returns `true` if the OAuth flow was initiated without error.
  Future<bool> signInWithGoogle() async {
    final redirectUrl = kIsWeb
        ? '${Uri.base.origin}/'
        : 'io.supabase.rento://login-callback';

    final ok = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
    return ok;
  }

  // ── Session management ──────────────────────────────────────

  /// Signs out the current user and clears local state.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Even if the server call fails (e.g. network), clear local state
      // so the user isn't stuck in a half-signed-out state.
      debugPrint('[AuthService] signOut error (clearing local state): $e');
    }
    _currentUser = null;
    _isNewUser = false;
    notifyListeners();
  }

  // ── Password / Email management ─────────────────────────────

  /// Sends a password-reset email.
  ///
  /// Does NOT throw on unknown emails — Supabase returns 200 regardless,
  /// which prevents email enumeration attacks.
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  /// Updates the current user's password. Requires an active session.
  ///
  /// Throws [AuthException] if the new password is too weak or the
  /// session is invalid.
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sends a confirmation email to [newEmail]. The email is only changed
  /// after the user clicks the confirmation link.
  Future<UserResponse> updateEmail(String newEmail) async {
    return await _supabase.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
    );
  }

  /// Requests account deletion.
  ///
  /// NOTE: Supabase client SDK cannot delete users directly — this must be
  /// done via a server-side function (Edge Function / RPC) with the
  /// service-role key. For now we sign out; wire up the backend call when
  /// the Edge Function is deployed.
  Future<void> deleteUser() async {
    // TODO: Call a Supabase Edge Function that deletes the user row
    // e.g. await _supabase.functions.invoke('delete-user');
    await signOut();
  }

  // ── Helpers ─────────────────────────────────────────────────

  /// Refreshes the current session. Useful before making authenticated
  /// API calls that require a fresh token.
  Future<void> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
    } catch (e) {
      debugPrint('[AuthService] refreshSession error: $e');
    }
  }

  /// Whether the current user signed in via an OAuth provider.
  bool get isOAuthUser {
    final provider = _currentUser?.raw.appMetadata['provider'] as String?;
    return provider != null && provider != 'email';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
