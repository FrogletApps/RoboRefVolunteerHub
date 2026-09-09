import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref_volunteer_hub/main.dart';
import 'package:roboref_volunteer_hub/features/auth_invites/state/auth_provider.dart';

void main() {
  testWidgets('App renders InviteGateScreen when no volunteer is signed in',
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

    // Verify that InviteGateScreen is rendered
    expect(find.text('RoboRef Volunteer Hub'), findsOneWidget);
    expect(find.text('Invite-Only Access'), findsOneWidget);
    expect(find.text('Verify Code & Continue'), findsOneWidget);
  });
}
