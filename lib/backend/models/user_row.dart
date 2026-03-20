/// Typed model for the `users` table in Supabase.
class UserRow {
  final String id;
  final DateTime createdAt;
  String? displayName;
  String? phoneNumber;
  String? email;
  String? profilePic;
  String? role;
  String? address;
  String? city;
  String? state;
  String? emergencyNumber;
  String? govProofId;
  int? onboardingStep;

  UserRow({
    required this.id,
    DateTime? createdAt,
    this.displayName,
    this.phoneNumber,
    this.email,
    this.profilePic,
    this.role,
    this.address,
    this.city,
    this.state,
    this.emergencyNumber,
    this.govProofId,
    this.onboardingStep,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserRow.fromJson(Map<String, dynamic> json) {
    return UserRow(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      displayName: json['display_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      profilePic: json['profile_pic'] as String?,
      role: json['role'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      emergencyNumber: json['emergency_number'] as String?,
      govProofId: json['gov_proof_id'] as String?,
      onboardingStep: (json['onboarding_step'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      if (displayName != null) 'display_name': displayName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
      if (profilePic != null) 'profile_pic': profilePic,
      if (role != null) 'role': role,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (emergencyNumber != null) 'emergency_number': emergencyNumber,
      if (govProofId != null) 'gov_proof_id': govProofId,
      if (onboardingStep != null) 'onboarding_step': onboardingStep,
    };
  }

  UserRow copyWith({
    String? displayName,
    String? phoneNumber,
    String? email,
    String? profilePic,
    String? role,
    String? address,
    String? city,
    String? state,
    String? emergencyNumber,
    String? govProofId,
    int? onboardingStep,
  }) {
    return UserRow(
      id: id,
      createdAt: createdAt,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      govProofId: govProofId ?? this.govProofId,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }
}
