import 'package:flutter/foundation.dart';
import '../../profile/models/volunteer_model.dart';
import '../../../core/constants/roles.dart';

enum SignupStatus {
  available('available', 'Available'),
  confirmed('confirmed', 'Confirmed');

  final String id;
  final String label;

  const SignupStatus(this.id, this.label);

  static SignupStatus fromId(String id) {
    return SignupStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => SignupStatus.available,
    );
  }
}

@immutable
class EventSignupModel {
  final String id;
  final String sku;
  final String volunteerId;
  final String volunteerName;
  final SignupStatus status;
  final bool epVerified;
  final List<String> offeredRoles;
  final String? otherRoleDescription;
  final String? notes;
  final VolunteerModel? volunteer;
  final DateTime updatedAt;

  const EventSignupModel({
    required this.id,
    required this.sku,
    required this.volunteerId,
    required this.volunteerName,
    required this.status,
    this.epVerified = false,
    this.offeredRoles = const [],
    this.otherRoleDescription,
    this.notes,
    this.volunteer,
    required this.updatedAt,
  });

  bool get isConfirmed => status == SignupStatus.confirmed;
  bool get isAvailable => status == SignupStatus.available;

  List<VolunteerRole> get roleEnums {
    return offeredRoles.map((r) => VolunteerRole.fromId(r)).toList();
  }

  EventSignupModel copyWith({
    String? id,
    String? sku,
    String? volunteerId,
    String? volunteerName,
    SignupStatus? status,
    bool? epVerified,
    List<String>? offeredRoles,
    String? otherRoleDescription,
    String? notes,
    VolunteerModel? volunteer,
    DateTime? updatedAt,
  }) {
    return EventSignupModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      status: status ?? this.status,
      epVerified: epVerified ?? this.epVerified,
      offeredRoles: offeredRoles ?? this.offeredRoles,
      otherRoleDescription: otherRoleDescription ?? this.otherRoleDescription,
      notes: notes ?? this.notes,
      volunteer: volunteer ?? this.volunteer,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'status': status.id,
        'epVerified': epVerified,
        'offeredRoles': offeredRoles,
        'otherRoleDescription': otherRoleDescription,
        'notes': notes,
        'volunteer': volunteer?.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EventSignupModel.fromJson(Map<String, dynamic> json) {
    return EventSignupModel(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      volunteerId: json['volunteerId'] as String? ?? '',
      volunteerName: json['volunteerName'] as String? ?? 'Volunteer',
      status: SignupStatus.fromId(json['status'] as String? ?? 'available'),
      epVerified: json['epVerified'] as bool? ?? false,
      offeredRoles: (json['offeredRoles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      otherRoleDescription: json['otherRoleDescription'] as String?,
      notes: json['notes'] as String?,
      volunteer: json['volunteer'] != null
          ? VolunteerModel.fromJson(json['volunteer'] as Map<String, dynamic>)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventSignupModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
