import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/roles.dart';
import '../../../core/utils/crypto_utils.dart';
import '../../profile/models/volunteer_model.dart';
import '../models/user_account.dart';

class AuthService {
  final SharedPreferences _prefs;
  static const String _userKey = 'current_volunteer_profile';
  static const String _inviteClaimedKey = 'claimed_invite_code';
  static const String _accountsKey = 'registered_volunteer_accounts_v1';

  AuthService(this._prefs) {
    _sanitizeStoredUsers();
  }

  static bool _hasEnabledPrivacyOrEpInJson(Map<String, dynamic>? map) {
    if (map == null) return false;
    return map['isEmailPublic'] == true ||
        map['isPhonePublic'] == true ||
        map['forwardingEnabled'] == true ||
        map['isEventPartner'] == true;
  }

  /// Ensures any previously stored session or registered user accounts have
  /// all Contact Privacy, Email Forwarding, and EP Mode settings turned off.
  void _sanitizeStoredUsers() {
    final rawUser = _prefs.getString(_userKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final map = jsonDecode(rawUser) as Map<String, dynamic>;
        final user = VolunteerModel.fromJson(map);
        final sanitized = user.withDisabledPrivacyAndEpSettings();
        if (_hasEnabledPrivacyOrEpInJson(map) || !identical(user, sanitized)) {
          _prefs.setString(_userKey, jsonEncode(sanitized.toJson()));
        }
      } catch (e) {
        debugPrint('Error sanitizing active volunteer profile: $e');
      }
    }

    final rawAccounts = _prefs.getString(_accountsKey);
    if (rawAccounts != null && rawAccounts.isNotEmpty) {
      try {
        final list = jsonDecode(rawAccounts) as List<dynamic>;
        var changed = false;
        final accounts = list.map((e) {
          final accMap = e as Map<String, dynamic>;
          final profileMap = accMap['profile'] as Map<String, dynamic>?;
          final acc = UserAccount.fromJson(accMap);
          final sanitizedProfile = acc.profile.withDisabledPrivacyAndEpSettings();
          if (_hasEnabledPrivacyOrEpInJson(profileMap) ||
              !identical(acc.profile, sanitizedProfile)) {
            changed = true;
            return acc.copyWith(profile: sanitizedProfile);
          }
          return acc;
        }).toList();
        if (changed) {
          _saveAccounts(accounts);
        }
      } catch (e) {
        debugPrint('Error sanitizing stored accounts: $e');
      }
    }
  }

  /// Validates whether an invite code is valid from the static admin list
  bool validateInviteCode(String code) {
    final clean = code.trim().toUpperCase();
    return kAdminInviteCodes.contains(clean);
  }

  /// Check whether the user already has an active volunteer profile session
  VolunteerModel? getCurrentVolunteer() {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final volunteer = VolunteerModel.fromJson(map);
      final sanitized = volunteer.withDisabledPrivacyAndEpSettings();
      if (_hasEnabledPrivacyOrEpInJson(map) || !identical(volunteer, sanitized)) {
        _prefs.setString(_userKey, jsonEncode(sanitized.toJson()));
      }
      return sanitized;
    } catch (e) {
      debugPrint('Error decoding volunteer profile: $e');
      return null;
    }
  }

  /// Load all registered accounts from local storage, seeding demo accounts if empty
  List<UserAccount> _loadAccounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      final initialAccounts = _getPreseededDemoAccounts();
      _saveAccounts(initialAccounts);
      return initialAccounts;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      var changed = false;
      final accounts = list.map((e) {
        final accMap = e as Map<String, dynamic>;
        final profileMap = accMap['profile'] as Map<String, dynamic>?;
        final acc = UserAccount.fromJson(accMap);
        final sanitizedProfile = acc.profile.withDisabledPrivacyAndEpSettings();
        if (_hasEnabledPrivacyOrEpInJson(profileMap) ||
            !identical(acc.profile, sanitizedProfile)) {
          changed = true;
          return acc.copyWith(profile: sanitizedProfile);
        }
        return acc;
      }).toList();
      if (changed) {
        _saveAccounts(accounts);
      }
      return accounts;
    } catch (e) {
      debugPrint('Error decoding accounts: $e');
      return _getPreseededDemoAccounts();
    }
  }

  /// Save accounts list to storage
  Future<void> _saveAccounts(List<UserAccount> accounts) async {
    final raw = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _prefs.setString(_accountsKey, raw);
  }

  /// Find account by normalized email
  UserAccount? findAccountByEmail(String email) {
    final clean = email.trim().toLowerCase();
    final accounts = _loadAccounts();
    try {
      return accounts.firstWhere((a) => a.email == clean);
    } catch (_) {
      return null;
    }
  }

  /// Register a new volunteer with invite code and secure password
  Future<VolunteerModel> signup({
    required String inviteCode,
    required String name,
    required String email,
    required String password,
    String? phone,
    List<String> qualifications = const [],
    bool isEmailPublic = false,
    bool isPhonePublic = false,
    bool forwardingEnabled = false,
  }) async {
    // 1. Enforce invite code access restriction
    if (!validateInviteCode(inviteCode)) {
      throw Exception(
        'Invalid or unrecognised invite code. Access is currently invite-only.',
      );
    }

    // 2. Validate password strength
    final pwValidation = CryptoUtils.validatePassword(password);
    if (pwValidation != null) {
      throw Exception(pwValidation);
    }

    final normalizedEmail = email.trim().toLowerCase();

    // 3. Prevent duplicate accounts with same email
    final accounts = _loadAccounts();
    if (accounts.any((a) => a.email == normalizedEmail)) {
      throw Exception(
        'An account with this email address already exists. Please log in below.',
      );
    }

    // 4. Securely hash password with random salt and PBKDF2
    final passwordHash = CryptoUtils.hashPassword(password);

    final id = const Uuid().v4();

    final volunteer = VolunteerModel(
      id: id,
      name: name.trim(),
      email: normalizedEmail,
      phone: phone?.trim(),
      qualifications: qualifications,
      isEmailPublic: false,
      isPhonePublic: false,
      forwardingEnabled: false,
      forwardingAddress: VolunteerModel.generateForwardingAddress(id),
      isEventPartner: false,
    );

    final account = UserAccount(
      email: normalizedEmail,
      passwordHash: passwordHash,
      profile: volunteer,
      createdAt: DateTime.now(),
    );

    accounts.add(account);
    await _saveAccounts(accounts);

    // Save active session
    await _prefs.setString(_userKey, jsonEncode(volunteer.toJson()));
    await _prefs.setString(_inviteClaimedKey, inviteCode.trim().toUpperCase());
    return volunteer;
  }

  /// Log in with email and password, securely verifying hash in constant time
  Future<VolunteerModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final account = findAccountByEmail(normalizedEmail);

    if (account == null) {
      throw Exception('Invalid email or password.');
    }

    final isValid = CryptoUtils.verifyPassword(password, account.passwordHash);
    if (!isValid) {
      throw Exception('Invalid email or password.');
    }

    // Set active volunteer session
    final sanitizedProfile = account.profile.withDisabledPrivacyAndEpSettings();
    await _prefs.setString(_userKey, jsonEncode(sanitizedProfile.toJson()));
    return sanitizedProfile;
  }

  /// Update the current volunteer's profile and persist to both active session & account registry
  Future<void> updateProfile(VolunteerModel updated) async {
    final sanitized = updated.withDisabledPrivacyAndEpSettings();
    await _prefs.setString(_userKey, jsonEncode(sanitized.toJson()));

    final accounts = _loadAccounts();
    final index = accounts.indexWhere(
      (a) =>
          a.email == sanitized.email.trim().toLowerCase() ||
          a.profile.id == sanitized.id,
    );

    if (index >= 0) {
      accounts[index] = accounts[index].copyWith(profile: sanitized);
      await _saveAccounts(accounts);
    }
  }

  /// Clear the local session (log out)
  Future<void> logout() async {
    await _prefs.remove(_userKey);
  }

  /// Seed realistic demo accounts for instant testing with standard password
  List<UserAccount> _getPreseededDemoAccounts() {
    const demoPassword = 'Password123!';
    final demoHash = CryptoUtils.hashPassword(
      demoPassword,
      salt: '7a9f8b2c4d6e1035',
      iterations: 10000,
    );

    return [
      UserAccount(
        email: 'alex.turner@example.org',
        passwordHash: demoHash,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        profile: const VolunteerModel(
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
      ),
      UserAccount(
        email: 'sarah.j@example.co.uk',
        passwordHash: demoHash,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        profile: const VolunteerModel(
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
      ),
      UserAccount(
        email: 'ep@example.co.uk',
        passwordHash: demoHash,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        profile: const VolunteerModel(
          id: 'vol-ep-lead',
          name: 'Event Partner Lead',
          email: 'ep@example.co.uk',
          qualifications: ['head_ref', 'judge_advisor'],
          isEmailPublic: false,
          isPhonePublic: false,
          forwardingEnabled: false,
          forwardingAddress: 'vol-eplead01@volunteer.roboref.app',
          isEventPartner: false,
        ),
      ),
    ];
  }
}
