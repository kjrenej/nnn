import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the authenticated user in the app.
class RentoUser {
  final User _supabaseUser;

  RentoUser(this._supabaseUser);

  String get uid => _supabaseUser.id;
  String get email => _supabaseUser.email ?? '';
  String get displayName =>
      _supabaseUser.userMetadata?['display_name'] as String? ?? '';
  String get photoUrl =>
      _supabaseUser.userMetadata?['photo_url'] as String? ?? '';
  String get phoneNumber => _supabaseUser.phone ?? '';
  bool get emailVerified => _supabaseUser.emailConfirmedAt != null;
  bool get loggedIn => true;

  User get raw => _supabaseUser;
}
