import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref_volunteer_hub/features/profile/models/volunteer_model.dart';
import 'package:roboref_volunteer_hub/features/volunteering/models/signup_model.dart';
import 'package:roboref_volunteer_hub/features/volunteering/services/volunteer_repository.dart';

void main() {
  group('My Volunteer Data & Signups Tests', () {
    late VolunteerRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = VolunteerRepository(prefs);
    });

    test('getSignupsForVolunteer returns preseeded signups for demo user', () async {
      // Alex Turner is pre-seeded in VolunteerRepository
      final alexSignups =
          await repository.getSignupsForVolunteer('vol-alex-turner');

      expect(alexSignups, isNotEmpty);
      expect(alexSignups.first.sku, equals('RE-V5RC-26-9102'));
      expect(alexSignups.first.status, equals(SignupStatus.confirmed));
      expect(alexSignups.first.epVerified, isTrue);
      expect(alexSignups.first.offeredRoles, contains('head_ref'));
    });

    test('Saving new signup for volunteer updates their personal signups list',
        () async {
      const volunteer = VolunteerModel(
        id: 'vol-user-123',
        name: 'Test Volunteer',
        email: 'test@example.co.uk',
        qualifications: ['ref', 'judge'],
        forwardingAddress: 'vol-test1234@volunteer.roboref.app',
      );

      var userSignups =
          await repository.getSignupsForVolunteer(volunteer.id);
      expect(userSignups, isEmpty);

      // Sign up for an event
      await repository.saveSignup(
        sku: 'RE-VIQRC-26-8821',
        volunteer: volunteer,
        status: SignupStatus.confirmed,
        offeredRoles: ['ref'],
        notes: 'Available for morning matches',
      );

      userSignups = await repository.getSignupsForVolunteer(volunteer.id);
      expect(userSignups.length, equals(1));
      expect(userSignups.first.sku, equals('RE-VIQRC-26-8821'));
      expect(userSignups.first.status, equals(SignupStatus.confirmed));
      expect(userSignups.first.notes, equals('Available for morning matches'));

      // Withdraw from event
      final withdrawn = await repository.withdrawSignup(
        sku: 'RE-VIQRC-26-8821',
        volunteerId: volunteer.id,
      );
      expect(withdrawn, isTrue);

      userSignups = await repository.getSignupsForVolunteer(volunteer.id);
      expect(userSignups, isEmpty);
    });
  });
}
