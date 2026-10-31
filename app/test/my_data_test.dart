import 'dart:convert';
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

    test('Previously persisted signup volunteer profiles have privacy & EP settings reset to off',
        () async {
      SharedPreferences.setMockInitialValues({
        'event_volunteer_signups_v1': jsonEncode([
          {
            'id': 'legacy-signup-1',
            'sku': 'RE-V5RC-26-9102',
            'volunteerId': 'vol-legacy',
            'volunteerName': 'Legacy Volunteer',
            'status': 'confirmed',
            'epVerified': false,
            'offeredRoles': ['ref'],
            'updatedAt': '2026-09-01T00:00:00.000Z',
            'volunteer': {
              'id': 'vol-legacy',
              'name': 'Legacy Volunteer',
              'email': 'legacy@example.org',
              'qualifications': ['ref'],
              'isEmailPublic': true,
              'isPhonePublic': true,
              'forwardingEnabled': true,
              'forwardingAddress': 'vol-legacy01@volunteer.roboref.app',
              'isEventPartner': true,
            },
          },
        ]),
      });

      final legacyPrefs = await SharedPreferences.getInstance();
      final legacyRepo = VolunteerRepository(legacyPrefs);

      final signups = await legacyRepo.getSignupsForEvent('RE-V5RC-26-9102');
      expect(signups.length, equals(1));
      final vol = signups.first.volunteer!;
      expect(vol.isEmailPublic, isFalse);
      expect(vol.isPhonePublic, isFalse);
      expect(vol.forwardingEnabled, isFalse);
      expect(vol.isEventPartner, isFalse);
    });
  });
}
