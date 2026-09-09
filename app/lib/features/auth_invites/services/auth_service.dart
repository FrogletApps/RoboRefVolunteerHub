import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/roles.dart';
import '../../profile/models/volunteer_model.dart';

class AuthService {
  final SharedPreferences _prefs;
  static const String _userKey = 'current_volunteer_profile';
  static const String _inviteClaimedKey = 'claimed_invite_code';

  AuthService(this._prefs);

  /// Validates whether an invite code is valid from the static admin list
  bool validateInviteCode(String code) {
    final clean = code.trim().toUpperCase();
    return kAdminInviteCodes.contains(clean);
  }

  /// Check whether the user already has an active volunteer profile
  VolunteerModel? getCurrentVolunteer() {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return VolunteerModel.fromJson(map);
    } catch (e) {
      debugPrint('Error decoding volunteer profile: $e');
      return null;
    }
  }

  /// Register a new volunteer with invite code
  Future<VolunteerModel> signup({
    required String inviteCode,
    required String name,
    required String email,
    String? phone,
    List<String> qualifications = const [],
    bool isEmailPublic = false,
    bool isPhonePublic = false,
    bool forwardingEnabled = true,
  }) async {
    if (!validateInviteCode(inviteCode)) {
      throw Exception('Invalid or unrecognised invite code. Please check with an administrator.');
    }

    final id = const Uuid().v4();
    final isEp = inviteCode.trim().toUpperCase() == 'UK-EP-VERIFIED';

    final volunteer = VolunteerModel(
      id: id,
      name: name.trim(),
      email: email.trim(),
      phone: phone?.trim(),
      qualifications: qualifications,
      isEmailPublic: isEmailPublic,
      isPhonePublic: isPhonePublic,
      forwardingEnabled: forwardingEnabled,
      forwardingAddress: VolunteerModel.generateForwardingAddress(id),
      isEventPartner: isEp,
    );

    await _prefs.setString(_userKey, jsonEncode(volunteer.toJson()));
    await _prefs.setString(_inviteClaimedKey, inviteCode.trim().toUpperCase());
    return volunteer;
  }

  /// Update the current volunteer's profile, qualifications, or privacy settings
  Future<void> updateProfile(VolunteerModel updated) async {
    await _prefs.setString(_userKey, jsonEncode(updated.toJson()));
  }

  /// Clear the local session (log out)
  Future<void> logout() async {
    await _prefs.remove(_userKey);
  }
}
