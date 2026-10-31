import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/signup_model.dart';
import '../../profile/models/volunteer_model.dart';

class VolunteerRepository {
  final SharedPreferences _prefs;
  static const String _storageKey = 'event_volunteer_signups_v1';

  VolunteerRepository(this._prefs) {
    _loadAllSignups();
  }

  static bool _hasEnabledPrivacyOrEpInJson(Map<String, dynamic>? map) {
    if (map == null) return false;
    return map['isEmailPublic'] == true ||
        map['isPhonePublic'] == true ||
        map['forwardingEnabled'] == true ||
        map['isEventPartner'] == true;
  }

  /// Load all saved signups from local storage, ensuring any volunteer privacy/EP
  /// toggles on persisted signups are turned off.
  List<EventSignupModel> _loadAllSignups() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return _getPreseededDemoSignups();
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      var changed = false;
      final signups = list.map((e) {
        final signupMap = e as Map<String, dynamic>;
        final volunteerMap = signupMap['volunteer'] as Map<String, dynamic>?;
        final signup = EventSignupModel.fromJson(signupMap);
        if (signup.volunteer != null) {
          final sanitizedVol =
              signup.volunteer!.withDisabledPrivacyAndEpSettings();
          if (_hasEnabledPrivacyOrEpInJson(volunteerMap) ||
              !identical(signup.volunteer, sanitizedVol)) {
            changed = true;
            return signup.copyWith(volunteer: sanitizedVol);
          }
        }
        return signup;
      }).toList();
      if (changed) {
        _saveAllSignups(signups);
      }
      return signups;
    } catch (e) {
      debugPrint('Error decoding signups: $e');
      return _getPreseededDemoSignups();
    }
  }

  /// Save all signups to local storage
  Future<void> _saveAllSignups(List<EventSignupModel> signups) async {
    final raw = jsonEncode(signups.map((s) => s.toJson()).toList());
    await _prefs.setString(_storageKey, raw);
  }

  /// Get signups for a specific event SKU
  Future<List<EventSignupModel>> getSignupsForEvent(String sku) async {
    final cleanSku = sku.trim().toUpperCase();
    final all = _loadAllSignups();
    return all.where((s) => s.sku.toUpperCase() == cleanSku).toList();
  }

  /// Get current user's signup for an event (if any)
  Future<EventSignupModel?> getUserSignupForEvent({
    required String sku,
    required String volunteerId,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    final all = _loadAllSignups();
    try {
      return all.firstWhere(
        (s) => s.sku.toUpperCase() == cleanSku && s.volunteerId == volunteerId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all event signups for a specific volunteer
  Future<List<EventSignupModel>> getSignupsForVolunteer(String volunteerId) async {
    final all = _loadAllSignups();
    return all.where((s) => s.volunteerId == volunteerId).toList();
  }

  /// Save or update a volunteer signup (Available or Confirmed)
  Future<EventSignupModel> saveSignup({
    required String sku,
    required VolunteerModel volunteer,
    required SignupStatus status,
    required List<String> offeredRoles,
    String? otherRoleDescription,
    String? notes,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    final all = _loadAllSignups();

    final existingIndex = all.indexWhere(
      (s) => s.sku.toUpperCase() == cleanSku && s.volunteerId == volunteer.id,
    );

    final signup = EventSignupModel(
      id: existingIndex >= 0 ? all[existingIndex].id : const Uuid().v4(),
      sku: cleanSku,
      volunteerId: volunteer.id,
      volunteerName: volunteer.name,
      status: status,
      epVerified: existingIndex >= 0 ? all[existingIndex].epVerified : false,
      offeredRoles: offeredRoles,
      otherRoleDescription: otherRoleDescription,
      notes: notes,
      volunteer: volunteer.withDisabledPrivacyAndEpSettings(),
      updatedAt: DateTime.now(),
    );

    if (existingIndex >= 0) {
      all[existingIndex] = signup;
    } else {
      all.add(signup);
    }

    await _saveAllSignups(all);
    return signup;
  }

  /// Volunteer withdraws / pulls out of an event
  Future<bool> withdrawSignup({
    required String sku,
    required String volunteerId,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    final all = _loadAllSignups();
    final initialCount = all.length;

    all.removeWhere(
      (s) => s.sku.toUpperCase() == cleanSku && s.volunteerId == volunteerId,
    );

    if (all.length != initialCount) {
      await _saveAllSignups(all);
      return true;
    }
    return false;
  }

  /// Event Partner toggles the "EP Verified" checkmark lock-in
  Future<EventSignupModel?> toggleEpVerification({
    required String signupId,
  }) async {
    final all = _loadAllSignups();
    final index = all.indexWhere((s) => s.id == signupId);
    if (index >= 0) {
      final updated = all[index].copyWith(
        epVerified: !all[index].epVerified,
        updatedAt: DateTime.now(),
      );
      all[index] = updated;
      await _saveAllSignups(all);
      return updated;
    }
    return null;
  }

  /// Realistic pre-seeded demo signups for UK events showing diverse roles & privacy modes
  List<EventSignupModel> _getPreseededDemoSignups() {
    return [
      // National Championship: RE-V5RC-26-9102
      EventSignupModel(
        id: 'demo-signup-1',
        sku: 'RE-V5RC-26-9102',
        volunteerId: 'vol-alex-turner',
        volunteerName: 'Alex Turner',
        status: SignupStatus.confirmed,
        epVerified: true, // EP Locked in
        offeredRoles: ['head_ref'],
        notes: 'Certified Head Ref 2026-2027. Bringing referee whistle and scoring tablet.',
        volunteer: const VolunteerModel(
          id: 'vol-alex-turner',
          name: 'Alex Turner',
          email: 'alex.turner@example.org',
          phone: '+44 7700 900123',
          qualifications: ['head_ref', 'ref'],
          isEmailPublic: false,
          isPhonePublic: false,
          forwardingEnabled: false,
          forwardingAddress: 'vol-alex102@volunteer.roboref.app',
          isEventPartner: false,
        ),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      EventSignupModel(
        id: 'demo-signup-2',
        sku: 'RE-V5RC-26-9102',
        volunteerId: 'vol-sarah-jenkins',
        volunteerName: 'Sarah Jenkins',
        status: SignupStatus.confirmed,
        epVerified: true,
        offeredRoles: ['judge_advisor'],
        notes: 'Experienced Judge Advisor for UK Midlands and South.',
        volunteer: const VolunteerModel(
          id: 'vol-sarah-jenkins',
          name: 'Sarah Jenkins',
          email: 'sarah.j@example.co.uk',
          qualifications: ['judge_advisor', 'judge'],
          isEmailPublic: false,
          isPhonePublic: false,
          forwardingEnabled: false,
          forwardingAddress: 'vol-sarah91@volunteer.roboref.app',
          isEventPartner: false,
        ),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      EventSignupModel(
        id: 'demo-signup-3',
        sku: 'RE-V5RC-26-9102',
        volunteerId: 'vol-david-clarke',
        volunteerName: 'David Clarke',
        status: SignupStatus.available,
        epVerified: false,
        offeredRoles: ['ref', 'judge'],
        notes: 'Free from 8:30am to 4pm. Can referee or review engineering notebooks.',
        volunteer: const VolunteerModel(
          id: 'vol-david-clarke',
          name: 'David Clarke',
          email: 'david.c@example.org',
          qualifications: ['ref', 'judge'],
          isEmailPublic: false,
          isPhonePublic: false,
          forwardingEnabled: false,
          forwardingAddress: 'vol-david44@volunteer.roboref.app',
          isEventPartner: false,
        ),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      EventSignupModel(
        id: 'demo-signup-4',
        sku: 'RE-V5RC-26-9102',
        volunteerId: 'vol-emma-watson',
        volunteerName: 'Emma Watson',
        status: SignupStatus.available,
        epVerified: false,
        offeredRoles: ['other'],
        otherRoleDescription: 'Tournament Manager Operator',
        notes: 'Experience running TM display & field control raspberry pis.',
        volunteer: const VolunteerModel(
          id: 'vol-emma-watson',
          name: 'Emma Watson',
          email: 'emma.w@example.com',
          phone: '+44 7700 900555',
          qualifications: ['other'],
          isEmailPublic: false,
          isPhonePublic: false,
          forwardingEnabled: false,
          forwardingAddress: 'vol-emma88@volunteer.roboref.app',
          isEventPartner: false,
        ),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),

      // London South VIQRC: RE-VIQRC-26-8821
      EventSignupModel(
        id: 'demo-signup-5',
        sku: 'RE-VIQRC-26-8821',
        volunteerId: 'vol-oliver-brown',
        volunteerName: 'Oliver Brown',
        status: SignupStatus.confirmed,
        epVerified: true,
        offeredRoles: ['head_ref'],
        volunteer: const VolunteerModel(
          id: 'vol-oliver-brown',
          name: 'Oliver Brown',
          email: 'oliver.b@example.co.uk',
          qualifications: ['head_ref', 'ref'],
          isEmailPublic: false,
          isPhonePublic: false,
          forwardingEnabled: false,
          forwardingAddress: 'vol-oliver3@volunteer.roboref.app',
          isEventPartner: false,
        ),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      EventSignupModel(
        id: 'demo-signup-6',
        sku: 'RE-VIQRC-26-8821',
        volunteerId: 'vol-hannah-smith',
        volunteerName: 'Hannah Smith',
        status: SignupStatus.available,
        epVerified: false,
        offeredRoles: ['ref', 'other'],
        otherRoleDescription: 'Field Queuing',
        volunteer: const VolunteerModel(
          id: 'vol-hannah-smith',
          name: 'Hannah Smith',
          email: 'hannah.s@example.org',
          phone: '+44 7700 900999',
          qualifications: ['ref', 'other'],
          isEmailPublic: false,
          isPhonePublic: false,
          forwardingEnabled: false,
          forwardingAddress: 'vol-hannah7@volunteer.roboref.app',
          isEventPartner: false,
        ),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
