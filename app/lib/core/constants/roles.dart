import 'package:flutter/material.dart';

/// Supported volunteer qualifications and roles for VEX competitions
enum VolunteerRole {
  headRef('head_ref', 'Head Referee', 'Chief field referee presiding over matches and rulings', Icons.sports),
  ref('ref', 'Referee', 'Field scorekeeper and rule infraction monitor', Icons.sports_score),
  judgeAdvisor('judge_advisor', 'Judge Advisor', 'Lead volunteer guiding team judging deliberations and awards', Icons.gavel),
  judge('judge', 'Judge', 'Interviews teams and evaluates engineering notebooks', Icons.rate_review),
  other('other', 'Other', 'Queueing, inspection, pit admin, TM operator, field reset', Icons.more_horiz);

  final String id;
  final String label;
  final String description;
  final IconData icon;

  const VolunteerRole(this.id, this.label, this.description, this.icon);

  static VolunteerRole fromId(String id) {
    return VolunteerRole.values.firstWhere(
      (r) => r.id == id,
      orElse: () => VolunteerRole.other,
    );
  }

  Color get color {
    switch (this) {
      case VolunteerRole.headRef:
        return const Color(0xFFD97706); // Amber / Gold
      case VolunteerRole.ref:
        return const Color(0xFF2563EB); // Royal Blue
      case VolunteerRole.judgeAdvisor:
        return const Color(0xFF7C3AED); // Purple
      case VolunteerRole.judge:
        return const Color(0xFF059669); // Emerald Green
      case VolunteerRole.other:
        return const Color(0xFF475569); // Slate Grey
    }
  }
}
