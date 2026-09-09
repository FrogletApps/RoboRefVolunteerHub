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

  AuthService(this._prefs);

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
      return VolunteerModel.fromJson(map);
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
      return list
          .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
          .toList();
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
    bool forwardingEnabled = true,
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
    final isEp = inviteCode.trim().toUpperCase() == 'UK-EP-VERIFIED';

    final volunteer = VolunteerModel(
      id: id,
      name: name.trim(),
      email: normalizedEmail,
      phone: phone?.trim(),
      qualifications: qualifications,
      isEmailPublic: isEmailPublic,
      isPhonePublic: isPhonePublic,
      forwardingEnabled: forwardingEnabled,
      forwardingAddress: VolunteerModel.generateForwardingAddress(id),
      isEventPartner: isEp,
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
    await _prefs.setString(_userKey, jsonEncode(account.profile.toJson()));
    return account.profile;
  }

  /// Update the current volunteer's profile and persist to both active session & account registry
  Future<void> updateProfile(VolunteerModel updated) async {
    await _prefs.setString(_userKey, jsonEncode(updated.toJson()));

    final accounts = _loadAccounts();
    final index = accounts.indexWhere(
      (a) =>
          a.email == updated.email.trim().toLowerCase() ||
          a.profile.id == updated.id,
    );

    if (index >= 0) {
      accounts[index] = accounts[index].copyWith(profile: updated);
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
          isEmailPublic: true,
          isPhonePublic: true,
          forwardingAddress: 'vol-alex102@volunteer.roboref.app',
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
          forwardingEnabled: true,
          forwardingAddress: 'vol-sarah91@volunteer.roboref.app',
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
          forwardingAddress: 'vol-eplead01@volunteer.roboref.app',
          isEventPartner: true,
        ),
      ),
    ];
  }
}
