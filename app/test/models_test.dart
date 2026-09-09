import 'package:flutter_test/flutter_test.dart';
import 'package:roboref_volunteer_hub/core/constants/roles.dart';
import 'package:roboref_volunteer_hub/features/profile/models/volunteer_model.dart';
import 'package:roboref_volunteer_hub/features/volunteering/models/signup_model.dart';
import 'package:roboref_volunteer_hub/features/events/models/event_model.dart';

void main() {
  group('Models & Privacy Tests', () {
    test('VolunteerModel serialization & forwarding address generation', () {
      const id = '12345678-abcd-ef01-2345-6789abcdef01';
      final forwarding = VolunteerModel.generateForwardingAddress(id);
      expect(forwarding, equals('vol-12345678@volunteer.roboref.app'));

      final volunteer = VolunteerModel(
        id: id,
        name: 'James Volunteer',
        email: 'james@example.org',
        phone: '+44 7700 900000',
        qualifications: ['head_ref', 'ref'],
        isEmailPublic: false,
        isPhonePublic: false,
        forwardingEnabled: true,
        forwardingAddress: forwarding,
        isEventPartner: true,
      );

      expect(volunteer.hasQualification('head_ref'), isTrue);
      expect(volunteer.hasQualification('judge'), isFalse);
      expect(volunteer.qualifiedRoles.length, equals(2));
      expect(volunteer.qualifiedRoles[0], equals(VolunteerRole.headRef));

      final json = volunteer.toJson();
      final restored = VolunteerModel.fromJson(json);

      expect(restored.id, equals(volunteer.id));
      expect(restored.name, equals(volunteer.name));
      expect(restored.forwardingAddress, equals(volunteer.forwardingAddress));
      expect(restored.isEventPartner, isTrue);
    });

    test('EventSignupModel serialization & EP verified checkmark', () {
      final signup = EventSignupModel(
        id: 'signup-101',
        sku: 'RE-V5RC-26-9102',
        volunteerId: 'vol-1',
        volunteerName: 'Alex Turner',
        status: SignupStatus.confirmed,
        epVerified: true,
        offeredRoles: ['head_ref', 'other'],
        otherRoleDescription: 'TM Operator',
        notes: 'Arriving at 8am',
        updatedAt: DateTime(2026, 9, 10),
      );

      expect(signup.isConfirmed, isTrue);
      expect(signup.isAvailable, isFalse);
      expect(signup.epVerified, isTrue);

      final json = signup.toJson();
      final restored = EventSignupModel.fromJson(json);

      expect(restored.id, equals('signup-101'));
      expect(restored.epVerified, isTrue);
      expect(restored.status, equals(SignupStatus.confirmed));
      expect(restored.offeredRoles, contains('head_ref'));
      expect(restored.otherRoleDescription, equals('TM Operator'));
    });

    test('EventModel JSON parsing with VEX Events structure', () {
      final json = {
        'id': 54101,
        'sku': 'RE-V5RC-26-9102',
        'name': 'UK VEX National Championship',
        'program': {'code': 'V5RC'},
        'season': {'name': '2026-2027'},
        'start': '2026-10-15T09:00:00Z',
        'end': '2026-10-16T17:00:00Z',
        'location': {
          'venue': 'Telford International Centre',
          'city': 'Telford',
          'region': 'Midlands',
          'country': 'United Kingdom',
        },
      };

      final event = EventModel.fromJson(json);
      expect(event.sku, equals('RE-V5RC-26-9102'));
      expect(event.program, equals('V5RC'));
      expect(event.country, equals('United Kingdom'));
      expect(event.city, equals('Telford'));
      expect(event.venue, equals('Telford International Centre'));
    });
  });
}
