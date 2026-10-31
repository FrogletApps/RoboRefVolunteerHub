import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref_volunteer_hub/features/auth_invites/state/auth_provider.dart';
import 'package:roboref_volunteer_hub/features/events/models/event_model.dart';
import 'package:roboref_volunteer_hub/features/profile/models/volunteer_model.dart';
import 'package:roboref_volunteer_hub/features/volunteering/models/signup_model.dart';
import 'package:roboref_volunteer_hub/features/volunteering/screens/event_roster_screen.dart';
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

    testWidgets(
        'Volunteer Roster hides all contact details (phone, email, and relay) for all users',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const event = EventModel(
        id: 1,
        sku: 'RE-V5RC-26-9102',
        name: 'UK VEX V5RC National Championship 2026-2027',
        program: 'V5RC',
        season: '2026-2027',
        startDate: '2026-11-14',
        endDate: '2026-11-15',
        venue: 'Telford International Centre',
        city: 'Telford',
        region: 'Midlands',
        country: 'United Kingdom',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: EventRosterScreen(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Volunteer names are visible on the roster
      expect(find.text('Alex Turner'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Emma Watson'), findsOneWidget);

      // No phone numbers, email addresses, relay buttons, or Private Contact labels are shown
      expect(find.text('+44 7700 900123'), findsNothing);
      expect(find.text('alex.turner@example.org'), findsNothing);
      expect(find.text('emma.w@example.com'), findsNothing);
      expect(find.text('Email via Relay'), findsNothing);
      expect(find.text('Private Contact'), findsNothing);
      expect(find.byIcon(Icons.phone), findsNothing);
      expect(find.byIcon(Icons.email), findsNothing);
    });
  });
}
