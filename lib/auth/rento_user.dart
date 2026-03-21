import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the authenticated user in the app.
///
/// Wraps the Supabase [User] object and provides convenient getters
/// for commonly accessed fields. Metadata keys follow the Supabase
/// convention (`display_name`, `full_name`, `avatar_url`, `photo_url`).
class RentoUser {
  final User _supabaseUser;

  const RentoUser(this._supabaseUser);

  /// The unique Supabase user ID.
  String get uid => _supabaseUser.id;

  /// The user's email address (empty string if not set).
  String get email => _supabaseUser.email ?? '';

  /// Display name — tries `display_name` first, then `full_name`
  /// (Google OAuth stores the name under `full_name`).
  String get displayName {
    final meta = _supabaseUser.userMetadata;
    if (meta == null) return '';
    return (meta['display_name'] as String?)?.trim().isNotEmpty == true
        ? meta['display_name'] as String
        : (meta['full_name'] as String? ?? '');
  }

  /// Profile photo URL — tries `photo_url` first, then `avatar_url`
  /// (Google OAuth stores the avatar under `avatar_url`).
  String get photoUrl {
    final meta = _supabaseUser.userMetadata;
    if (meta == null) return '';
    return (meta['photo_url'] as String?)?.isNotEmpty == true
        ? meta['photo_url'] as String
        : (meta['avatar_url'] as String? ?? '');
  }

  /// The user's phone number (empty string if not set).
  String get phoneNumber => _supabaseUser.phone ?? '';

  /// Whether the user's email has been confirmed.
  bool get emailVerified => _supabaseUser.emailConfirmedAt != null;

  /// The authentication provider (e.g. `email`, `google`, `apple`).
  String get provider =>
      _supabaseUser.appMetadata['provider'] as String? ?? 'email';

  /// Whether this user signed in via an OAuth provider (not email/password).
  bool get isOAuth => provider != 'email';

  /// The raw Supabase [User] object for advanced use cases.
  User get raw => _supabaseUser;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentoUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'RentoUser(uid: $uid, email: $email)';
}
