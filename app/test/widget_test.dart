import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref_volunteer_hub/main.dart';
import 'package:roboref_volunteer_hub/features/auth_invites/state/auth_provider.dart';

void main() {
  testWidgets('App renders InviteGateScreen with both invite section and login section',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RoboRefVolunteerHubApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('RoboRef Volunteer Hub'), findsOneWidget);

    // Verify Invite-Only Access section
    expect(find.text('Invite-Only Access'), findsOneWidget);
    expect(find.byKey(const Key('invite_code_input')), findsOneWidget);
    expect(find.byKey(const Key('verify_invite_button')), findsOneWidget);

    // Verify Login section below invite code
    expect(find.text('Volunteer Log In'), findsOneWidget);
    expect(find.byKey(const Key('login_email_input')), findsOneWidget);
    expect(find.byKey(const Key('login_password_input')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });

  testWidgets('Logging in with email and password grants entry and displays user data',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RoboRefVolunteerHubApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to login inputs if needed and enter pre-seeded demo user credentials
    await tester.ensureVisible(find.byKey(const Key('login_email_input')));
    await tester.enterText(
      find.byKey(const Key('login_email_input')),
      'alex.turner@example.org',
    );
    await tester.ensureVisible(find.byKey(const Key('login_password_input')));
    await tester.enterText(
      find.byKey(const Key('login_password_input')),
      'Password123!',
    );

    // Ensure button is visible and tap Log In button
    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    // Verify user is now inside the authenticated events screen
    expect(find.text('UK VEX Events'), findsOneWidget);
    expect(find.textContaining('Signed in as Alex Turner'), findsOneWidget);
    expect(find.text('View My Data'), findsOneWidget);

    // Tap View My Data to see volunteer profile and personal registrations
    await tester.tap(find.text('View My Data'));
    await tester.pumpAndSettle();

    // Verify profile screen with Alex's personal volunteer data is visible
    expect(find.text('Volunteer Profile'), findsOneWidget);
    expect(find.text('Alex Turner'), findsWidgets);
    expect(find.text('vol-alex102@volunteer.roboref.app'), findsOneWidget);
    expect(find.text('My Event Signups & Volunteering Data'), findsOneWidget);
  });
}
