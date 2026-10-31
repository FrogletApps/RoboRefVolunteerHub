import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth_invites/state/auth_provider.dart';
import '../../volunteering/state/volunteering_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late Set<String> _qualifications;
  late bool _isPhonePublic;
  late bool _isEmailPublic;
  late bool _forwardingEnabled;
  late bool _isEventPartner;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentVolunteerProvider);
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _qualifications = Set<String>.from(user?.qualifications ?? []);
    _isPhonePublic = user?.isPhonePublic ?? false;
    _isEmailPublic = user?.isEmailPublic ?? false;
    _forwardingEnabled = user?.forwardingEnabled ?? true;
    _isEventPartner = user?.isEventPartner ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(currentVolunteerProvider);
    if (user == null) return;

    final updated = user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      qualifications: _qualifications.toList(),
      isPhonePublic: _isPhonePublic,
      isEmailPublic: _isEmailPublic,
      forwardingEnabled: _forwardingEnabled,
      isEventPartner: _isEventPartner,
    );

    await ref.read(currentVolunteerProvider.notifier).updateProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile and privacy settings saved successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentVolunteerProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No active volunteer session')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out?'),
                  content: const Text('Are you sure you want to log out of RoboRef Volunteer Hub?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(currentVolunteerProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Avatar Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.brandGreen,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'V',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _isEventPartner
                                          ? AppTheme.epVerifiedGold.withValues(alpha: 0.15)
                                          : AppTheme.brandGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _isEventPartner ? '★ Event Partner (EP)' : 'Official Volunteer',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _isEventPartner
                                            ? AppTheme.epVerifiedGold
                                            : AppTheme.brandGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Info Card
                const Text(
                  'Account Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email Address'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Qualifications
                const Text(
                  'Qualifications & Certified Roles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...VolunteerRole.values.map((role) {
                  final isSelected = _qualifications.contains(role.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? role.color : const Color(0xFFE2E8F0),
                        ),
                      ),
                      secondary: Icon(role.icon, color: role.color),
                      title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(role.description, style: const TextStyle(fontSize: 11)),
                      value: isSelected,
                      activeColor: role.color,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _qualifications.add(role.id);
                          } else {
                            _qualifications.remove(role.id);
                          }
                        });
                      },
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Privacy & Forwarding Settings
                const Text(
                  'Contact Privacy & Email Forwarding',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose whether to display your raw contact details or use your anonymized forwarding relay address.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Colors.blue, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Anonymized Forwarding Alias:',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      user.forwardingAddress,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Use Email Forwarding Alias', style: TextStyle(fontSize: 14)),
                          subtitle: const Text(
                            'Displays your relay alias instead of your personal inbox',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _forwardingEnabled,
                          onChanged: (val) => setState(() => _forwardingEnabled = val),
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Make Phone Number Public', style: TextStyle(fontSize: 14)),
                          subtitle: const Text(
                            'Display phone directly on event rosters',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isPhonePublic,
                          onChanged: (val) => setState(() => _isPhonePublic = val),
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Make Email Address Public', style: TextStyle(fontSize: 14)),
                          subtitle: const Text(
                            'Display raw email directly on event rosters',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isEmailPublic,
                          onChanged: (val) => setState(() => _isEmailPublic = val),
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Event Partner (EP) Mode', style: TextStyle(fontSize: 14)),
                          subtitle: const Text(
                            'Enables verification checkmark and volunteer locking tools for event organizers',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isEventPartner,
                          onChanged: (val) => setState(() => _isEventPartner = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // My Event Signups & Volunteering Data
                const Text(
                  'My Event Signups & Volunteering Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Overview of tournaments where you have volunteered and your attendance status.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),

                Consumer(
                  builder: (context, ref, _) {
                    final mySignupsAsync = ref.watch(myVolunteerSignupsProvider);
                    return mySignupsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => Text('Error loading signups: $err'),
                      data: (signups) {
                        if (signups.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.event_available_outlined,
                                      size: 38, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No event signups yet',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select tournaments from the UK Events tab to register as Available or Confirmed.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: signups.map((s) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          s.sku,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: s.isConfirmed
                                                ? AppTheme.statusConfirmed
                                                    .withValues(alpha: 0.15)
                                                : AppTheme.statusAvailable
                                                    .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            s.isConfirmed
                                                ? 'Confirmed'
                                                : 'Available',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: s.isConfirmed
                                                  ? AppTheme.statusConfirmed
                                                  : AppTheme.statusAvailable,
                                            ),
                                          ),
                                        ),
                                        if (s.epVerified) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.epVerifiedGold
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.verified,
                                                    size: 13,
                                                    color:
                                                        AppTheme.epVerifiedGold),
                                                SizedBox(width: 3),
                                                Text(
                                                  'EP Verified',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.epVerifiedGold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: s.roleEnums.map((r) {
                                        return Chip(
                                          visualDensity: VisualDensity.compact,
                                          avatar: Icon(r.icon,
                                              size: 14, color: r.color),
                                          label: Text(
                                            r.label,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          backgroundColor:
                                              r.color.withValues(alpha: 0.08),
                                          side: BorderSide(
                                              color: r.color
                                                  .withValues(alpha: 0.3)),
                                        );
                                      }).toList(),
                                    ),
                                    if (s.notes != null && s.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Note: ${s.notes}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[700]),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Withdraw from Event?'),
                                                content: Text(
                                                    'Withdraw your registration for tournament ${s.sku}?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: const Text(
                                                        'Withdraw'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await ref
                                                  .read(
                                                      volunteerRepositoryProvider)
                                                  .withdrawSignup(
                                                    sku: s.sku,
                                                    volunteerId: user.id,
                                                  );
                                              ref.invalidate(
                                                  myVolunteerSignupsProvider);
                                              ref.invalidate(
                                                  eventSignupsProvider(s.sku));
                                              ref.invalidate(
                                                  userEventSignupProvider(
                                                      s.sku));
                                            }
                                          },
                                          icon: const Icon(Icons.cancel_outlined,
                                              size: 16, color: Colors.red),
                                          label: const Text(
                                            'Withdraw',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Profile & Settings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
