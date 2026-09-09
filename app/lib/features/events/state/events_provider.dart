import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/vex_events_service.dart';

final vexEventsServiceProvider = Provider<VexEventsService>((ref) {
  return VexEventsService();
});

final selectedProgramFilterProvider = StateProvider<String>((ref) => 'All');

final eventSearchQueryProvider = StateProvider<String>((ref) => '');

final ukEventsListProvider = FutureProvider<List<EventModel>>((ref) async {
  final service = ref.watch(vexEventsServiceProvider);
  final program = ref.watch(selectedProgramFilterProvider);
  final query = ref.watch(eventSearchQueryProvider);

  return service.searchUkEvents(
    program: program == 'All' ? null : program,
    query: query.isEmpty ? null : query,
  );
});
