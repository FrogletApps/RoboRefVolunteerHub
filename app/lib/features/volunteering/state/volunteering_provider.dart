import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/signup_model.dart';
import '../services/volunteer_repository.dart';
import '../../auth_invites/state/auth_provider.dart';

final volunteerRepositoryProvider = Provider<VolunteerRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VolunteerRepository(prefs);
});

final eventSignupsProvider =
    FutureProvider.family<List<EventSignupModel>, String>((ref, sku) async {
  final repo = ref.watch(volunteerRepositoryProvider);
  return repo.getSignupsForEvent(sku);
});

final userEventSignupProvider =
    FutureProvider.family<EventSignupModel?, String>((ref, sku) async {
  final repo = ref.watch(volunteerRepositoryProvider);
  final user = ref.watch(currentVolunteerProvider);
  if (user == null) return null;
  return repo.getUserSignupForEvent(sku: sku, volunteerId: user.id);
});

final myVolunteerSignupsProvider =
    FutureProvider<List<EventSignupModel>>((ref) async {
  final repo = ref.watch(volunteerRepositoryProvider);
  final user = ref.watch(currentVolunteerProvider);
  if (user == null) return [];
  return repo.getSignupsForVolunteer(user.id);
});
