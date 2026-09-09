import 'package:flutter/foundation.dart';

/// Secure credential transfer object for authenticating users.
/// Enforces secure handling policies (masked toString, https protocol requirements).
@immutable
class AuthCredentials {
  final String email;
  final String password;

  const AuthCredentials({
    required this.email,
    required this.password,
  });

  /// Normalized lowercase trimmed email
  String get normalizedEmail => email.trim().toLowerCase();

  /// Enforces secure transmission over HTTPS/TLS endpoints.
  /// Refuses cleartext HTTP transmission to protect credentials in transit.
  static void assertSecureTransmission(Uri endpoint) {
    if (!kReleaseMode && (endpoint.isScheme('http') && endpoint.host == 'localhost' || endpoint.host == '127.0.0.1')) {
      // Local dev exception for local test servers
      return;
    }
    if (!endpoint.isScheme('https')) {
      throw StateError(
        'Insecure transmission rejected: credentials must be transmitted over encrypted HTTPS/TLS. Received: ${endpoint.scheme}',
      );
    }
  }

  @override
  String toString() {
    // Redact password to prevent accidental leak in logs or crash reporting
    return 'AuthCredentials(email: $email, password: [REDACTED])';
  }
}
