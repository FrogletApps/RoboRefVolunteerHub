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
    expect(find.widgetWithText(AppBar, 'RoboRef Volunteer Hub'), findsOneWidget);
    expect(find.text('UK VEX Events'), findsNothing);

    // Verify "Signed in as..." bar (alias + View My Data button) is removed
    expect(find.textContaining('Signed in as'), findsNothing);
    expect(find.textContaining('Alias:'), findsNothing);
    expect(find.text('View My Data'), findsNothing);

    // Verify profile button and log out button to the right of the profile button
    final profileButton = find.byKey(const Key('profile_button'));
    final logoutButton = find.byKey(const Key('logout_button'));
    expect(profileButton, findsOneWidget);
    expect(logoutButton, findsOneWidget);

    final profileRect = tester.getRect(profileButton);
    final logoutRect = tester.getRect(logoutButton);
    expect(logoutRect.left, greaterThanOrEqualTo(profileRect.right));
    expect((logoutRect.center.dy - profileRect.center.dy).abs(), lessThan(2));

    // Tap profile button to see volunteer profile and personal registrations
    await tester.tap(profileButton);
    await tester.pumpAndSettle();

    // Verify profile screen with Alex's personal volunteer data is visible
    expect(find.text('Volunteer Profile'), findsOneWidget);
    expect(find.text('Alex Turner'), findsWidgets);
    expect(find.text('vol-alex102@volunteer.roboref.app'), findsOneWidget);
    expect(find.text('My Event Signups & Volunteering Data'), findsNothing);

    // Verify all 4 switches in Contact Privacy & Email Forwarding section are off and disabled
    final profileSwitches =
        tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(profileSwitches.length, equals(4));
    for (final tile in profileSwitches) {
      expect(tile.value, isFalse);
      expect(tile.onChanged, isNull);
    }

    // Navigate back to events screen and test logging out from AppBar
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'RoboRef Volunteer Hub'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();
    expect(find.text('Log Out?'), findsOneWidget);

    // Confirm log out
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
    await tester.pumpAndSettle();

    // Verify returned to InviteGateScreen
    expect(find.text('Invite-Only Access'), findsOneWidget);
    expect(find.text('Volunteer Log In'), findsOneWidget);

    // Verify registration screen privacy switches are also off and disabled
    await tester.enterText(find.byKey(const Key('invite_code_input')), 'UKVEX-2026');
    await tester.tap(find.byKey(const Key('verify_invite_button')));
    await tester.pumpAndSettle();

    expect(find.text('Volunteer Registration'), findsOneWidget);
    final signupSwitches =
        tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(signupSwitches.length, equals(3));
    for (final tile in signupSwitches) {
      expect(tile.value, isFalse);
      expect(tile.onChanged, isNull);
    }
  });
}
