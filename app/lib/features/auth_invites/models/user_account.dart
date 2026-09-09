import 'package:flutter/foundation.dart';
import '../../profile/models/volunteer_model.dart';

/// Stored account representation containing salted password hash and volunteer profile.
@immutable
class UserAccount {
  final String email;
  final String passwordHash; // Salted PBKDF2 hash (pbkdf2_sha256$...)
  final VolunteerModel profile;
  final DateTime createdAt;

  const UserAccount({
    required this.email,
    required this.passwordHash,
    required this.profile,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'email': email.toLowerCase().trim(),
        'passwordHash': passwordHash,
        'profile': profile.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      email: (json['email'] as String? ?? '').toLowerCase().trim(),
      passwordHash: json['passwordHash'] as String? ?? '',
      profile: VolunteerModel.fromJson(json['profile'] as Map<String, dynamic>),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserAccount copyWith({
    String? email,
    String? passwordHash,
    VolunteerModel? profile,
    DateTime? createdAt,
  }) {
    return UserAccount(
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
