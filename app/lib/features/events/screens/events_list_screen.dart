import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sku_utils.dart';
import '../../../core/utils/url_utils.dart';
import '../models/event_model.dart';
import '../state/events_provider.dart';
import '../../volunteering/state/volunteering_provider.dart';
import '../../volunteering/screens/event_roster_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth_invites/state/auth_provider.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  static String formatDateRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final fmt = DateFormat('EEE, d MMM y');
      if (s.year == e.year && s.month == e.month && s.day == e.day) {
        return fmt.format(s);
      }
      return '${DateFormat('d MMM').format(s)} – ${fmt.format(e)}';
    } catch (_) {
      return start;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(ukEventsListProvider);
    final selectedProgram = ref.watch(selectedProgramFilterProvider);
    final currentUser = ref.watch(currentVolunteerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UK VEX Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Volunteer Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search UK tournaments, cities, or SKUs...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: ref.watch(eventSearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                ref.read(eventSearchQueryProvider.notifier).state = '',
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    ref.read(eventSearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: 10),
                // Program Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'V5RC', 'VIQRC', 'VEX U'].map((prog) {
                      final isSelected = selectedProgram == prog;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(prog),
                          selected: isSelected,
                          selectedColor: AppTheme.brandGreen.withValues(alpha: 0.15),
                          checkmarkColor: AppTheme.brandGreen,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.brandGreen : null,
                          ),
                          onSelected: (val) {
                            ref.read(selectedProgramFilterProvider.notifier).state =
                                val ? prog : 'All';
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // User status greeting banner
          if (currentUser != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.brandGreen.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.brandGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Signed in as ${currentUser.name} (${currentUser.qualifiedRoles.map((r) => r.label).join(', ')})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (currentUser.isEventPartner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.epVerifiedGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EP MODE',
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

          // Events List
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading UK events: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(ukEventsListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'No UK events match your filters.',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try resetting filters or searching with another keyword.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(ukEventsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _EventCard(event: event);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signupsAsync = ref.watch(eventSignupsProvider(event.sku));
    final progColor = getProgramColor(event.program);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventRosterScreen(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Program chip, SKU, and VEX Events link
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: progColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.program,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: progColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.sku,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // VEX Events External Link Button
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    tooltip: 'View on VEX Events (events.vex.com)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => UrlUtils.openVexEventsPage(event.sku),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Event Name
              Text(
                event.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Date and Location
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      EventsListScreen.formatDateRange(event.startDate, event.endDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [event.venue, event.city, event.region].whereType<String>().where((s) => s.isNotEmpty).join(', '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Signups summary & Roster CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  signupsAsync.when(
                    data: (signups) {
                      final confirmedCount = signups.where((s) => s.isConfirmed).length;
                      final availableCount = signups.where((s) => s.isAvailable).length;
                      return Row(
                        children: [
                          Icon(Icons.people_outline, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text(
                            '$confirmedCount Confirmed • $availableCount Available',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: confirmedCount > 0 ? AppTheme.statusConfirmed : Colors.grey[700],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Text('Loading volunteers...', style: TextStyle(fontSize: 11)),
                    error: (_, __) => const SizedBox(),
                  ),
                  Row(
                    children: [
                      Text(
                        'View Roster',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.brandGreen),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
