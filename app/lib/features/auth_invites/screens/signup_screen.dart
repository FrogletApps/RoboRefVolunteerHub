import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_theme.dart';
import '../state/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const SignupScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final Set<String> _selectedQualifications = {'head_ref', 'ref'};
  bool _isPhonePublic = false;
  bool _isEmailPublic = false;
  bool _forwardingEnabled = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQualifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one qualification.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(currentVolunteerProvider.notifier).signup(
            inviteCode: widget.inviteCode,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
            qualifications: _selectedQualifications.toList(),
            isEmailPublic: _isEmailPublic,
            isPhonePublic: _isPhonePublic,
            forwardingEnabled: _forwardingEnabled,
          );

      if (mounted) {
        // Pop back to root - main.dart will reactively switch to the authenticated screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEpInvite = widget.inviteCode == 'UK-EP-VERIFIED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Verified Invite Code Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: AppTheme.brandGreen, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite Code: ${widget.inviteCode}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.brandGreen,
                                  ),
                                ),
                                if (isEpInvite)
                                  const Text(
                                    'Event Partner (EP) Verified Privileges Enabled',
                                    style: TextStyle(fontSize: 12, color: AppTheme.brandGreenDark),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information
                    const Text(
                      'Personal Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter your email';
                        if (!val.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        hintText: '+44 7700 900000',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Qualifications Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Qualifications',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Select all that apply',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...VolunteerRole.values.map((role) {
                      final isSelected = _selectedQualifications.contains(role.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedQualifications.remove(role.id);
                              } else {
                                _selectedQualifications.add(role.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? role.color.withValues(alpha: 0.08)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? role.color : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(role.icon, color: role.color, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected ? role.color : null,
                                        ),
                                      ),
                                      Text(
                                        role.description,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: isSelected,
                                  activeColor: role.color,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedQualifications.add(role.id);
                                      } else {
                                        _selectedQualifications.remove(role.id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 28),

                    // Privacy & Contact Preferences
                    const Text(
                      'Contact Privacy Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Decide how event organizers and fellow volunteers can contact you on event rosters.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Public Phone Number', style: TextStyle(fontSize: 14)),
                            subtitle: const Text(
                              'Display phone number directly on rosters for calling/SMS',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _isPhonePublic,
                            onChanged: (val) => setState(() => _isPhonePublic = val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Public Email Address', style: TextStyle(fontSize: 14)),
                            subtitle: const Text(
                              'Display raw email address openly on rosters',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _isEmailPublic,
                            onChanged: (val) => setState(() => _isEmailPublic = val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Email Forwarding Address', style: TextStyle(fontSize: 14)),
                            subtitle: const Text(
                              'Generates a privacy alias (vol-xxxx@volunteer.roboref.app) that routes messages to your inbox without disclosing your personal address',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _forwardingEnabled,
                            onChanged: (val) => setState(() => _forwardingEnabled = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Complete Registration & Get Started',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
