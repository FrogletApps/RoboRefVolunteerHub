import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth_invites/state/auth_provider.dart';
import 'features/auth_invites/screens/invite_gate_screen.dart';
import 'features/events/screens/events_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const RoboRefVolunteerHubApp(),
    ),
  );
}

class RoboRefVolunteerHubApp extends ConsumerWidget {
  const RoboRefVolunteerHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVolunteer = ref.watch(currentVolunteerProvider);

    return MaterialApp(
      title: 'RoboRef Volunteer Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Invite-only gate: If no volunteer profile is loaded, enforce InviteGateScreen
      home: currentVolunteer == null
          ? const InviteGateScreen()
          : const EventsListScreen(),
    );
  }
}
