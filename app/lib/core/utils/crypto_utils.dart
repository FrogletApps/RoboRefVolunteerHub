import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic utilities for password hashing, verification, and timing attack resistance.
class CryptoUtils {
  static const int defaultIterations = 10000;
  static const int defaultKeyLength = 32; // 256 bits

  /// Generates a cryptographically secure random salt in hex string format
  static String generateSalt([int length = 16]) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a password using PBKDF2-HMAC-SHA256
  /// Produces format: `pbkdf2_sha256$<iterations>$<saltHex>$<derivedKeyHex>`
  static String hashPassword(
    String password, {
    String? salt,
    int iterations = defaultIterations,
  }) {
    final effectiveSalt = salt ?? generateSalt();
    final saltBytes = utf8.encode(effectiveSalt);
    final passwordBytes = utf8.encode(password);

    final derivedBytes = _pbkdf2HmacSha256(
      password: passwordBytes,
      salt: saltBytes,
      iterations: iterations,
      keyLength: defaultKeyLength,
    );

    final hashHex =
        derivedBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'pbkdf2_sha256\$$iterations\$$effectiveSalt\$$hashHex';
  }

  /// Verifies a password against a stored PBKDF2 hash using constant-time comparison
  static bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split('\$');
    if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') {
      return false;
    }
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    final salt = parts[2];
    final expectedHashHex = parts[3];

    final computedHash =
        hashPassword(password, salt: salt, iterations: iterations);
    final computedParts = computedHash.split('\$');
    if (computedParts.length != 4) return false;

    return fixedTimeEquals(computedParts[3], expectedHashHex);
  }

  /// Constant-time comparison of two strings to prevent timing attacks
  static bool fixedTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Standard PBKDF2 implementation using HMAC-SHA256 as PRF
  static List<int> _pbkdf2HmacSha256({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    final hmac = Hmac(sha256, password);
    const hLen = 32; // SHA-256 output length in bytes
    final l = (keyLength / hLen).ceil();
    final r = keyLength - (l - 1) * hLen;

    final derivedKey = BytesBuilder();

    for (var i = 1; i <= l; i++) {
      // U_1 = PRF(P, S || INT_32_BE(i))
      final saltAndIndex = Uint8List(salt.length + 4);
      saltAndIndex.setRange(0, salt.length, salt);
      final bdata = ByteData.sublistView(saltAndIndex, salt.length);
      bdata.setUint32(0, i, Endian.big);

      var u = hmac.convert(saltAndIndex).bytes;
      final t = Uint8List.fromList(u);

      for (var j = 1; j < iterations; j++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < hLen; k++) {
          t[k] ^= u[k];
        }
      }

      if (i == l) {
        derivedKey.add(t.sublist(0, r));
      } else {
        derivedKey.add(t);
      }
    }

    return derivedKey.toBytes();
  }

  /// Password validation enforcing security standards (minimum 8 characters)
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter a password.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    return null;
  }
}
