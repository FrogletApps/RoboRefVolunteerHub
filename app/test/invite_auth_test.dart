import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref_volunteer_hub/core/utils/crypto_utils.dart';
import 'package:roboref_volunteer_hub/core/utils/auth_payload.dart';
import 'package:roboref_volunteer_hub/features/auth_invites/services/auth_service.dart';

void main() {
  group('Invite Code & Auth Tests', () {
    late AuthService authService;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      authService = AuthService(prefs);
    });

    test('Validates static administrator invite codes', () {
      expect(authService.validateInviteCode('UKVEX-2026'), isTrue);
      expect(authService.validateInviteCode('ukvex-2026'), isTrue); // Case-insensitive
      expect(authService.validateInviteCode('VEX-REF-UK'), isTrue);
      expect(authService.validateInviteCode('UK-EP-VERIFIED'), isTrue);
      expect(authService.validateInviteCode('INVALID-CODE'), isFalse);
      expect(authService.validateInviteCode(''), isFalse);
    });

    test('Successful signup stores volunteer profile and hashed password', () async {
      final volunteer = await authService.signup(
        inviteCode: 'UKVEX-2026',
        name: 'Jane Doe',
        email: 'jane@example.co.uk',
        password: 'Password123!',
        phone: '+44 7700 900888',
        qualifications: ['head_ref', 'ref', 'judge_advisor'],
        isEmailPublic: false,
        isPhonePublic: false,
        forwardingEnabled: true,
      );

      expect(volunteer.name, equals('Jane Doe'));
      expect(volunteer.qualifications, contains('head_ref'));
      expect(volunteer.forwardingAddress, startsWith('vol-'));
      expect(volunteer.isEventPartner, isFalse);

      final current = authService.getCurrentVolunteer();
      expect(current, isNotNull);
      expect(current!.email, equals('jane@example.co.uk'));

      // Verify password is NOT stored in plain text anywhere
      final storedAccountsRaw = prefs.getString('registered_volunteer_accounts_v1');
      expect(storedAccountsRaw, isNotNull);
      expect(storedAccountsRaw!.contains('Password123!'), isFalse);
      expect(storedAccountsRaw.contains('pbkdf2_sha256\$10000\$'), isTrue);
    });

    test('Signup with UK-EP-VERIFIED assigns isEventPartner = true', () async {
      final volunteer = await authService.signup(
        inviteCode: 'UK-EP-VERIFIED',
        name: 'Test EP Lead',
        email: 'ep-test@example.co.uk',
        password: 'SecurePassword123!',
        qualifications: ['head_ref', 'judge_advisor'],
      );

      expect(volunteer.isEventPartner, isTrue);
    });

    test('Signup with invalid invite code throws exception', () async {
      expect(
        () => authService.signup(
          inviteCode: 'BAD-CODE-999',
          name: 'Hacker',
          email: 'bad@example.com',
          password: 'Password123!',
        ),
        throwsException,
      );
    });

    test('Signup with weak password (< 8 chars) throws exception', () async {
      expect(
        () => authService.signup(
          inviteCode: 'UKVEX-2026',
          name: 'Short PW User',
          email: 'short@example.com',
          password: '123',
        ),
        throwsException,
      );
    });

    test('Signup with duplicate email throws exception', () async {
      await authService.signup(
        inviteCode: 'UKVEX-2026',
        name: 'User One',
        email: 'duplicate@example.com',
        password: 'Password123!',
      );

      expect(
        () => authService.signup(
          inviteCode: 'UKVEX-2026',
          name: 'User Two',
          email: 'duplicate@example.com',
          password: 'Password123!',
        ),
        throwsException,
      );
    });

    test('Login with valid email and password succeeds and sets session', () async {
      await authService.signup(
        inviteCode: 'UKVEX-2026',
        name: 'Bob Smith',
        email: 'bob.smith@example.co.uk',
        password: 'MySecretPassword123!',
      );

      // Clear session to simulate fresh login
      await authService.logout();
      expect(authService.getCurrentVolunteer(), isNull);

      // Perform login
      final loggedIn = await authService.login(
        email: 'bob.smith@example.co.uk',
        password: 'MySecretPassword123!',
      );

      expect(loggedIn.email, equals('bob.smith@example.co.uk'));
      expect(loggedIn.name, equals('Bob Smith'));
      expect(authService.getCurrentVolunteer(), isNotNull);
    });

    test('Login is case-insensitive for email', () async {
      await authService.signup(
        inviteCode: 'UKVEX-2026',
        name: 'Case Test',
        email: 'case@example.com',
        password: 'Password123!',
      );

      final loggedIn = await authService.login(
        email: 'CASE@EXAMPLE.COM',
        password: 'Password123!',
      );
      expect(loggedIn.email, equals('case@example.com'));
    });

    test('Login with incorrect password throws exception', () async {
      await authService.signup(
        inviteCode: 'UKVEX-2026',
        name: 'Auth Target',
        email: 'target@example.com',
        password: 'RealPassword123!',
      );

      expect(
        () => authService.login(
          email: 'target@example.com',
          password: 'WrongPassword!',
        ),
        throwsException,
      );
    });

    test('Login with non-existent email throws exception', () async {
      expect(
        () => authService.login(
          email: 'ghost@example.com',
          password: 'Password123!',
        ),
        throwsException,
      );
    });

    test('Preseeded demo account (alex.turner@example.org) can log in out of the box', () async {
      final user = await authService.login(
        email: 'alex.turner@example.org',
        password: 'Password123!',
      );

      expect(user.id, equals('vol-alex-turner'));
      expect(user.name, equals('Alex Turner'));
      expect(user.qualifications, contains('head_ref'));
    });
  });

  group('Crypto & Secure Transmission Tests', () {
    test('CryptoUtils hashes with PBKDF2-HMAC-SHA256 and verifies correctly', () {
      const password = 'SuperSecretPassword2026!';
      final hash = CryptoUtils.hashPassword(password);

      expect(hash, startsWith('pbkdf2_sha256\$10000\$'));
      expect(CryptoUtils.verifyPassword(password, hash), isTrue);
      expect(CryptoUtils.verifyPassword('WrongPassword!', hash), isFalse);
    });

    test('CryptoUtils generates unique salts', () {
      final salt1 = CryptoUtils.generateSalt();
      final salt2 = CryptoUtils.generateSalt();
      expect(salt1, isNot(equals(salt2)));
      expect(salt1.length, equals(32)); // 16 bytes in hex = 32 chars
    });

    test('CryptoUtils fixedTimeEquals prevents timing discrepancies', () {
      expect(CryptoUtils.fixedTimeEquals('abc', 'abc'), isTrue);
      expect(CryptoUtils.fixedTimeEquals('abc', 'abd'), isFalse);
      expect(CryptoUtils.fixedTimeEquals('abc', 'abcd'), isFalse);
    });

    test('AuthCredentials asserts HTTPS transmission security', () {
      expect(
        () => AuthCredentials.assertSecureTransmission(
          Uri.parse('http://insecure-api.roboref.app/auth'),
        ),
        throwsStateError,
      );

      expect(
        () => AuthCredentials.assertSecureTransmission(
          Uri.parse('https://secure-api.roboref.app/auth'),
        ),
        returnsNormally,
      );
    });

    test('AuthCredentials redacts password in toString', () {
      const creds = AuthCredentials(email: 'test@example.com', password: 'Secret123!');
      expect(creds.toString().contains('Secret123!'), isFalse);
      expect(creds.toString(), contains('[REDACTED]'));
    });
  });
}
