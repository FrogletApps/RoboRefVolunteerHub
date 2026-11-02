import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../profile/models/volunteer_model.dart';
import 'otp_auth_api_client.dart';

@immutable
class AuthSession {
  final String uid;
  final String email;

  const AuthSession({
    required this.uid,
    required this.email,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => Object.hash(uid, email);
}

/// Abstract backend persistence & identity contract for Firebase Auth + Firestore.
abstract class AuthBackend {
  AuthSession? get currentSession;

  Stream<AuthSession?> authSessionChanges();

  Future<AuthSession> signInWithCustomToken(
    String customToken, {
    String fallbackEmail = '',
  });

  Future<VolunteerModel?> fetchVolunteerProfile(AuthSession session);

  Future<VolunteerModel> saveVolunteerProfile(
    AuthSession session,
    VolunteerModel volunteer,
  );

  Future<void> signOut();
}

/// Production backend backed by `FirebaseAuth` (persistent device session) and
/// `Cloud Firestore` (`volunteers/{uid}` + owner-only `volunteer_private/{uid}`).
class FirebaseAuthBackend implements AuthBackend {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthBackend({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static AuthSession? _userToSession(User? user, {String fallbackEmail = ''}) {
    if (user == null) return null;
    return AuthSession(
      uid: user.uid,
      email: (user.email ?? fallbackEmail).trim().toLowerCase(),
    );
  }

  @override
  AuthSession? get currentSession => _userToSession(_firebaseAuth.currentUser);

  @override
  Stream<AuthSession?> authSessionChanges() {
    return _firebaseAuth.authStateChanges().map(_userToSession);
  }

  @override
  Future<AuthSession> signInWithCustomToken(
    String customToken, {
    String fallbackEmail = '',
  }) async {
    final cred = await _firebaseAuth.signInWithCustomToken(customToken);
    final session = _userToSession(cred.user, fallbackEmail: fallbackEmail);
    if (session == null) {
      throw const AuthApiException(
        code: 'firebase_signin_failed',
        message: 'Unable to establish a device session. Please try again.',
      );
    }
    return session;
  }

  @override
  Future<VolunteerModel?> fetchVolunteerProfile(AuthSession session) async {
    final publicRef = _firestore.collection('volunteers').doc(session.uid);
    final privateRef =
        _firestore.collection('volunteer_private').doc(session.uid);

    final results = await Future.wait([
      publicRef.get(),
      privateRef.get(),
    ]);

    final publicSnap = results[0];
    if (!publicSnap.exists || publicSnap.data() == null) {
      return null;
    }

    final privateSnap = results[1];
    return VolunteerModel.fromFirestoreMaps(
      uid: session.uid,
      publicData: publicSnap.data()!,
      privateData: privateSnap.data(),
      fallbackEmail: session.email,
    ).withDisabledPrivacyAndEpSettings();
  }

  @override
  Future<VolunteerModel> saveVolunteerProfile(
    AuthSession session,
    VolunteerModel volunteer,
  ) async {
    final sanitized = volunteer
        .copyWith(
          id: session.uid,
          email: volunteer.email.trim().isNotEmpty
              ? volunteer.email.trim().toLowerCase()
              : session.email,
          forwardingAddress: volunteer.forwardingAddress.isNotEmpty
              ? volunteer.forwardingAddress
              : VolunteerModel.generateForwardingAddress(session.uid),
        )
        .withDisabledPrivacyAndEpSettings();

    final publicRef = _firestore.collection('volunteers').doc(session.uid);
    final privateRef =
        _firestore.collection('volunteer_private').doc(session.uid);

    final batch = _firestore.batch();
    batch.set(publicRef, sanitized.toPublicFirestoreMap());
    batch.set(privateRef, sanitized.toPrivateFirestoreMap());
    await batch.commit();

    return sanitized;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

/// Deterministic in-memory backend for unit and widget tests (verifies exact
/// separation of `volunteers/{uid}` and `volunteer_private/{uid}` without network).
class InMemoryAuthBackend implements AuthBackend {
  AuthSession? _session;
  final Map<String, Map<String, dynamic>> _publicDocs = {};
  final Map<String, Map<String, dynamic>> _privateDocs = {};
  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();

  InMemoryAuthBackend({
    AuthSession? initialSession,
    VolunteerModel? initialProfile,
  }) : _session = initialSession {
    if (initialSession != null && initialProfile != null) {
      final sanitized = initialProfile.withDisabledPrivacyAndEpSettings();
      _publicDocs[initialSession.uid] =
          sanitized.toPublicFirestoreMap(updatedAtTimestamp: DateTime.now());
      _privateDocs[initialSession.uid] =
          sanitized.toPrivateFirestoreMap(updatedAtTimestamp: DateTime.now());
    }
  }

  Map<String, dynamic>? getStoredPublicDoc(String uid) => _publicDocs[uid];
  Map<String, dynamic>? getStoredPrivateDoc(String uid) => _privateDocs[uid];

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> authSessionChanges() async* {
    yield _session;
    yield* _controller.stream;
  }

  @override
  Future<AuthSession> signInWithCustomToken(
    String customToken, {
    String fallbackEmail = '',
  }) async {
    // Allow test tokens formatted as `custom-token:<uid>:<email>` or plain strings
    var uid = 'vol-${fallbackEmail.hashCode.abs()}';
    var email = fallbackEmail;
    final parts = customToken.split(':');
    if (parts.length >= 3 && parts[0] == 'test-token') {
      uid = parts[1];
      email = parts.sublist(2).join(':');
    }

    final session = AuthSession(uid: uid, email: email.trim().toLowerCase());
    _session = session;
    _controller.add(session);
    return session;
  }

  @override
  Future<VolunteerModel?> fetchVolunteerProfile(AuthSession session) async {
    final pub = _publicDocs[session.uid];
    if (pub == null) return null;
    final priv = _privateDocs[session.uid];
    return VolunteerModel.fromFirestoreMaps(
      uid: session.uid,
      publicData: pub,
      privateData: priv,
      fallbackEmail: session.email,
    ).withDisabledPrivacyAndEpSettings();
  }

  @override
  Future<VolunteerModel> saveVolunteerProfile(
    AuthSession session,
    VolunteerModel volunteer,
  ) async {
    final sanitized = volunteer
        .copyWith(
          id: session.uid,
          email: volunteer.email.trim().isNotEmpty
              ? volunteer.email.trim().toLowerCase()
              : session.email,
          forwardingAddress: volunteer.forwardingAddress.isNotEmpty
              ? volunteer.forwardingAddress
              : VolunteerModel.generateForwardingAddress(session.uid),
        )
        .withDisabledPrivacyAndEpSettings();

    final now = DateTime.now();
    _publicDocs[session.uid] =
        sanitized.toPublicFirestoreMap(updatedAtTimestamp: now);
    _privateDocs[session.uid] =
        sanitized.toPrivateFirestoreMap(updatedAtTimestamp: now);
    return sanitized;
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// High-level authentication & profile orchestration service.
class AuthService {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  final OtpAuthApiClient _apiClient;
  final AuthBackend _backend;

  AuthService({
    required OtpAuthApiClient apiClient,
    required AuthBackend backend,
  })  : _apiClient = apiClient,
        _backend = backend;

  AuthSession? get currentSession => _backend.currentSession;

  Stream<AuthSession?> authSessionChanges() => _backend.authSessionChanges();

  Future<VolunteerModel?> fetchCurrentVolunteerProfile(AuthSession session) {
    return _backend.fetchVolunteerProfile(session);
  }

  static String normalizeAndValidateEmail(String rawEmail) {
    final clean = rawEmail.trim().toLowerCase();
    if (clean.isEmpty || clean.length > 254 || !_emailRegex.hasMatch(clean)) {
      throw const AuthApiException(
        code: 'invalid_email',
        message: 'Please enter a valid email address.',
      );
    }
    return clean;
  }

  /// Step 1a (Returning Volunteer): Request a 6-digit OTP email.
  Future<OtpRequestResult> requestSignInOtp({
    required String email,
    String? turnstileToken,
  }) async {
    final cleanEmail = normalizeAndValidateEmail(email);
    return _apiClient.requestOtp(
      mode: AuthOtpMode.login,
      email: cleanEmail,
      turnstileToken: turnstileToken,
    );
  }

  /// Step 1b (New Volunteer): Verify invite code on the Cloudflare Worker and send a 6-digit OTP email.
  Future<OtpRequestResult> requestInviteOtp({
    required String email,
    required String inviteCode,
    String? turnstileToken,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw const AuthApiException(
        code: 'missing_invite_code',
        message: 'Please enter your invitation code.',
      );
    }
    final cleanEmail = normalizeAndValidateEmail(email);
    return _apiClient.requestOtp(
      mode: AuthOtpMode.join,
      email: cleanEmail,
      inviteCode: cleanCode,
      turnstileToken: turnstileToken,
    );
  }

  /// Step 2: Verify the 6-digit OTP and sign into Firebase Auth (persisting session on device).
  Future<AuthSession> verifyOtpAndSignIn({
    required String email,
    required String code,
  }) async {
    final cleanEmail = normalizeAndValidateEmail(email);
    final cleanCode = code.trim();
    if (!_otpRegex.hasMatch(cleanCode)) {
      throw const AuthApiException(
        code: 'invalid_code_format',
        message: 'Please enter the 6-digit numeric verification code.',
      );
    }

    final verified = await _apiClient.verifyOtp(
      email: cleanEmail,
      code: cleanCode,
    );

    return _backend.signInWithCustomToken(
      verified.customToken,
      fallbackEmail: verified.email,
    );
  }

  /// Step 3 (New Volunteer): Create initial `volunteers/{uid}` and `volunteer_private/{uid}` profile.
  Future<VolunteerModel> completeOnboarding({
    required AuthSession session,
    required String name,
    String? phone,
    required List<String> qualifications,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AuthApiException(
        code: 'invalid_name',
        message: 'Please enter your full name.',
      );
    }
    if (qualifications.isEmpty) {
      throw const AuthApiException(
        code: 'missing_qualifications',
        message: 'Please select at least one qualification.',
      );
    }

    final initialProfile = VolunteerModel(
      id: session.uid,
      name: trimmedName,
      email: session.email,
      phone: phone?.trim(),
      qualifications: qualifications,
      isEmailPublic: false,
      isPhonePublic: false,
      forwardingEnabled: false,
      forwardingAddress: VolunteerModel.generateForwardingAddress(session.uid),
      isEventPartner: false,
    );

    return _backend.saveVolunteerProfile(session, initialProfile);
  }

  /// Update the authenticated volunteer's profile and private contact record.
  Future<VolunteerModel> updateProfile(VolunteerModel updated) async {
    final session = _backend.currentSession;
    if (session == null) {
      throw const AuthApiException(
        code: 'unauthenticated',
        message: 'Your session has expired. Please sign in again.',
      );
    }
    return _backend.saveVolunteerProfile(
      session,
      updated.withDisabledPrivacyAndEpSettings(),
    );
  }

  /// Sign out and clear the remembered device session.
  Future<void> logout() async {
    await _backend.signOut();
  }
}
