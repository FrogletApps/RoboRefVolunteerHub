import 'package:flutter/foundation.dart';
import '../../../core/constants/roles.dart';

@immutable
class VolunteerModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> qualifications;
  final bool isEmailPublic;
  final bool isPhonePublic;
  final bool forwardingEnabled;
  final String forwardingAddress;
  final bool isEventPartner;
  final String? certifications;

  const VolunteerModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.qualifications = const [],
    this.isEmailPublic = false,
    this.isPhonePublic = false,
    this.forwardingEnabled = false,
    required this.forwardingAddress,
    this.isEventPartner = false,
    this.certifications,
  });

  /// Returns a copy with all Contact Privacy, Email Forwarding, and EP Mode settings turned off.
  VolunteerModel withDisabledPrivacyAndEpSettings() {
    if (!isEmailPublic &&
        !isPhonePublic &&
        !forwardingEnabled &&
        !isEventPartner) {
      return this;
    }
    return copyWith(
      isEmailPublic: false,
      isPhonePublic: false,
      forwardingEnabled: false,
      isEventPartner: false,
    );
  }

  /// Generate a clean email forwarding alias from volunteer ID
  static String generateForwardingAddress(String id) {
    final cleanId = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final prefix = cleanId.length >= 8 ? cleanId.substring(0, 8) : cleanId.padRight(8, '0');
    return 'vol-$prefix@volunteer.roboref.app';
  }

  bool hasQualification(String roleId) {
    return qualifications.contains(roleId);
  }

  List<VolunteerRole> get qualifiedRoles {
    return qualifications.map((q) => VolunteerRole.fromId(q)).toList();
  }

  VolunteerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? qualifications,
    bool? isEmailPublic,
    bool? isPhonePublic,
    bool? forwardingEnabled,
    String? forwardingAddress,
    bool? isEventPartner,
    String? certifications,
  }) {
    return VolunteerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      qualifications: qualifications ?? this.qualifications,
      isEmailPublic: isEmailPublic ?? this.isEmailPublic,
      isPhonePublic: isPhonePublic ?? this.isPhonePublic,
      forwardingEnabled: forwardingEnabled ?? this.forwardingEnabled,
      forwardingAddress: forwardingAddress ?? this.forwardingAddress,
      isEventPartner: isEventPartner ?? this.isEventPartner,
      certifications: certifications ?? this.certifications,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'qualifications': qualifications,
        'isEmailPublic': isEmailPublic,
        'isPhonePublic': isPhonePublic,
        'forwardingEnabled': forwardingEnabled,
        'forwardingAddress': forwardingAddress,
        'isEventPartner': isEventPartner,
        'certifications': certifications,
      };

  factory VolunteerModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? 'vol-unknown';
    return VolunteerModel(
      id: rawId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      qualifications: (json['qualifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isEmailPublic: false,
      isPhonePublic: false,
      forwardingEnabled: false,
      forwardingAddress: json['forwardingAddress'] as String? ??
          generateForwardingAddress(rawId),
      isEventPartner: false,
      certifications: json['certifications'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolunteerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
