import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../profile/models/volunteer_model.dart';
import '../services/auth_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

class CurrentVolunteerNotifier extends StateNotifier<VolunteerModel?> {
  final AuthService _authService;

  CurrentVolunteerNotifier(this._authService) : super(_authService.getCurrentVolunteer());

  Future<VolunteerModel> login({
    required String email,
    required String password,
  }) async {
    final volunteer = await _authService.login(
      email: email,
      password: password,
    );
    state = volunteer;
    return volunteer;
  }

  Future<VolunteerModel> signup({
    required String inviteCode,
    required String name,
    required String email,
    required String password,
    String? phone,
    List<String> qualifications = const [],
    bool isEmailPublic = false,
    bool isPhonePublic = false,
    bool forwardingEnabled = true,
  }) async {
    final volunteer = await _authService.signup(
      inviteCode: inviteCode,
      name: name,
      email: email,
      password: password,
      phone: phone,
      qualifications: qualifications,
      isEmailPublic: isEmailPublic,
      isPhonePublic: isPhonePublic,
      forwardingEnabled: forwardingEnabled,
    );
    state = volunteer;
    return volunteer;
  }

  Future<void> updateProfile(VolunteerModel updated) async {
    await _authService.updateProfile(updated);
    state = updated;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }

  void refresh() {
    state = _authService.getCurrentVolunteer();
  }
}

final currentVolunteerProvider =
    StateNotifierProvider<CurrentVolunteerNotifier, VolunteerModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CurrentVolunteerNotifier(authService);
});

/// Toggle to test Event Partner actions (verification lock-in)
final isEpModeProvider = StateProvider<bool>((ref) {
  final volunteer = ref.watch(currentVolunteerProvider);
  return volunteer?.isEventPartner ?? false;
});
