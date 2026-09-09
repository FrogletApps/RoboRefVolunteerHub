import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref_volunteer_hub/features/auth_invites/services/auth_service.dart';

void main() {
  group('Invite Code & Auth Tests', () {
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
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

    test('Successful signup stores volunteer profile in SharedPreferences', () async {
      final volunteer = await authService.signup(
        inviteCode: 'UKVEX-2026',
        name: 'Jane Doe',
        email: 'jane@example.co.uk',
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
    });

    test('Signup with UK-EP-VERIFIED assigns isEventPartner = true', () async {
      final volunteer = await authService.signup(
        inviteCode: 'UK-EP-VERIFIED',
        name: 'Event Partner Lead',
        email: 'ep@example.co.uk',
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
        ),
        throwsException,
      );
    });
  });
}
