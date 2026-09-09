import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_theme.dart';
import '../state/auth_provider.dart';
import 'signup_screen.dart';

class InviteGateScreen extends ConsumerStatefulWidget {
  const InviteGateScreen({super.key});

  @override
  ConsumerState<InviteGateScreen> createState() => _InviteGateScreenState();
}

class _InviteGateScreenState extends ConsumerState<InviteGateScreen> {
  final _codeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter an invite code.');
      return;
    }

    final authService = ref.read(authServiceProvider);
    if (!authService.validateInviteCode(code)) {
      setState(() {
        _errorMessage = 'Invalid invite code. Access is currently invite-only.';
      });
      return;
    }

    setState(() => _errorMessage = null);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignupScreen(inviteCode: code.toUpperCase()),
      ),
    );
  }

  void _useSampleCode(String code) {
    _codeController.text = code;
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandGreen.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'RoboRef Volunteer Hub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UK VEX Robotics Volunteer & Official Management',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 36),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lock_outline, color: AppTheme.brandGreen, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'Invite-Only Access',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Volunteer signup is currently restricted to authorized personnel with an invitation code.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Invitation Code',
                              hintText: 'e.g. UKVEX-2026',
                              prefixIcon: const Icon(Icons.vpn_key_outlined),
                              errorText: _errorMessage,
                            ),
                            onSubmitted: (_) => _verifyCode(),
                          ),
                          const SizedBox(height: 18),

                          ElevatedButton.icon(
                            onPressed: _verifyCode,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text(
                              'Verify Code & Continue',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick test codes helper
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                            SizedBox(width: 6),
                            Text(
                              'Available Admin Invite Codes:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: kAdminInviteCodes.map((c) {
                            final isEp = c == 'UK-EP-VERIFIED';
                            return ActionChip(
                              label: Text(
                                isEp ? '$c (EP Mode)' : c,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () => _useSampleCode(c),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
