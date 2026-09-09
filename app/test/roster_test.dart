import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref_volunteer_hub/features/profile/models/volunteer_model.dart';
import 'package:roboref_volunteer_hub/features/volunteering/models/signup_model.dart';
import 'package:roboref_volunteer_hub/features/volunteering/services/volunteer_repository.dart';

void main() {
  group('Volunteer Repository & Roster Tests', () {
    late VolunteerRepository repo;

    final testVolunteer = VolunteerModel(
      id: 'vol-test-1',
      name: 'Sam Ref',
      email: 'sam@example.com',
      qualifications: ['head_ref', 'ref'],
      forwardingAddress: 'vol-test1@volunteer.roboref.app',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = VolunteerRepository(prefs);
    });

    test('Volunteer can sign up as Available and then Confirmed', () async {
      const sku = 'RE-V5RC-26-9102';

      // 1. Mark as Available
      final signupAvailable = await repo.saveSignup(
        sku: sku,
        volunteer: testVolunteer,
        status: SignupStatus.available,
        offeredRoles: ['head_ref', 'ref'],
        notes: 'Can referee all day',
      );

      expect(signupAvailable.status, equals(SignupStatus.available));
      expect(signupAvailable.epVerified, isFalse);

      final userSignup = await repo.getUserSignupForEvent(sku: sku, volunteerId: testVolunteer.id);
      expect(userSignup, isNotNull);
      expect(userSignup!.status, equals(SignupStatus.available));

      // 2. Update to Confirmed
      final signupConfirmed = await repo.saveSignup(
        sku: sku,
        volunteer: testVolunteer,
        status: SignupStatus.confirmed,
        offeredRoles: ['head_ref'],
      );

      expect(signupConfirmed.status, equals(SignupStatus.confirmed));

      final updatedUserSignup = await repo.getUserSignupForEvent(sku: sku, volunteerId: testVolunteer.id);
      expect(updatedUserSignup!.status, equals(SignupStatus.confirmed));
    });

    test('Event Partner can toggle EP Verified checkmark lock-in', () async {
      const sku = 'RE-V5RC-26-9102';

      final signup = await repo.saveSignup(
        sku: sku,
        volunteer: testVolunteer,
        status: SignupStatus.confirmed,
        offeredRoles: ['head_ref'],
      );

      expect(signup.epVerified, isFalse);

      // EP verifies / locks in
      final verifiedSignup = await repo.toggleEpVerification(signupId: signup.id);
      expect(verifiedSignup, isNotNull);
      expect(verifiedSignup!.epVerified, isTrue);

      // EP un-verifies
      final unlockedSignup = await repo.toggleEpVerification(signupId: signup.id);
      expect(unlockedSignup!.epVerified, isFalse);
    });

    test('Volunteer can pull out / withdraw from an event at any time', () async {
      const sku = 'RE-V5RC-26-9102';

      await repo.saveSignup(
        sku: sku,
        volunteer: testVolunteer,
        status: SignupStatus.available,
        offeredRoles: ['ref'],
      );

      var userSignup = await repo.getUserSignupForEvent(sku: sku, volunteerId: testVolunteer.id);
      expect(userSignup, isNotNull);

      // Pull out / withdraw
      final withdrawn = await repo.withdrawSignup(sku: sku, volunteerId: testVolunteer.id);
      expect(withdrawn, isTrue);

      userSignup = await repo.getUserSignupForEvent(sku: sku, volunteerId: testVolunteer.id);
      expect(userSignup, isNull);
    });
  });
}
