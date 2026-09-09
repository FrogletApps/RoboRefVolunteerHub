import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../state/auth_provider.dart';
import 'signup_screen.dart';

class InviteGateScreen extends ConsumerStatefulWidget {
  const InviteGateScreen({super.key});

  @override
  ConsumerState<InviteGateScreen> createState() => _InviteGateScreenState();
}

class _InviteGateScreenState extends ConsumerState<InviteGateScreen> {
  // Invite code registration controllers
  final _codeController = TextEditingController();
  String? _inviteErrorMessage;

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  String? _loginErrorMessage;
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _codeController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _inviteErrorMessage = 'Please enter an invite code.');
      return;
    }

    final authService = ref.read(authServiceProvider);
    if (!authService.validateInviteCode(code)) {
      setState(() {
        _inviteErrorMessage =
            'Invalid invite code. Access is currently invite-only.';
      });
      return;
    }

    setState(() => _inviteErrorMessage = null);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignupScreen(inviteCode: code.toUpperCase()),
      ),
    );
  }

  Future<void> _login() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loginErrorMessage = 'Please enter both your email and password.';
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginErrorMessage = null;
    });

    try {
      await ref.read(currentVolunteerProvider.notifier).login(
            email: email,
            password: password,
          );
      // Navigation will automatically update to the home screen because main.dart
      // watches currentVolunteerProvider.
    } catch (e) {
      setState(() {
        final message = e.toString().replaceAll('Exception: ', '');
        _loginErrorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  void _fillDemoCredentials(String email, String password) {
    setState(() {
      _loginEmailController.text = email;
      _loginPasswordController.text = password;
      _loginErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
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
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'RoboRef Volunteer Hub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UK VEX Robotics Competition Volunteer Management',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  // 1. INVITATION CODE CARD (For new volunteers)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.vpn_key_outlined,
                                  color: AppTheme.brandGreen, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'Invite-Only Access',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'New volunteer signup is strictly limited to invitation codes. Enter your code to set up your login.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            key: const Key('invite_code_input'),
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Invitation Code',
                              hintText: 'e.g. UKVEX-2026',
                              prefixIcon: const Icon(Icons.pin_outlined),
                              errorText: _inviteErrorMessage,
                            ),
                            onSubmitted: (_) => _verifyCode(),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            key: const Key('verify_invite_button'),
                            onPressed: _verifyCode,
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text(
                              'Verify Code & Set Up Login',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider between Invite and Login
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ALREADY REGISTERED?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                  ),

                  // 2. EMAIL & PASSWORD LOGIN SECTION
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppTheme.brandGreen.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.login_rounded,
                                  color: AppTheme.brandGreen, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'Volunteer Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your email and secure password to view your volunteer schedule and data.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 18),

                          // Login Error Banner
                          if (_loginErrorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade700, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _loginErrorMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email Field
                          TextField(
                            key: const Key('login_email_input'),
                            controller: _loginEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'name@example.co.uk',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password Field with Masking
                          TextField(
                            key: const Key('login_password_input'),
                            controller: _loginPasswordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 18),

                          // Log In Button
                          ElevatedButton.icon(
                            key: const Key('login_submit_button'),
                            onPressed: _isLoggingIn ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _isLoggingIn
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward_rounded,
                                    size: 18),
                            label: Text(
                              _isLoggingIn
                                  ? 'Signing In...'
                                  : 'Log In & View My Data',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Demo Account Quick Fill Helper
                          Center(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Demo Quick Fill:',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                                ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: const Text('Alex Turner',
                                      style: TextStyle(fontSize: 11)),
                                  onPressed: () => _fillDemoCredentials(
                                    'alex.turner@example.org',
                                    'Password123!',
                                  ),
                                ),
                                ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: const Text('Sarah Jenkins',
                                      style: TextStyle(fontSize: 11)),
                                  onPressed: () => _fillDemoCredentials(
                                    'sarah.j@example.co.uk',
                                    'Password123!',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
