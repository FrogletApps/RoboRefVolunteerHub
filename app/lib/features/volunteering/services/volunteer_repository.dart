import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/signup_model.dart';
import '../../profile/models/volunteer_model.dart';

/// Storage abstraction for volunteer event signups (`event_signups/{sku}_{uid}`).
abstract class SignupStore {
  Future<List<EventSignupModel>> getSignupsForEvent(String cleanSku);

  Future<EventSignupModel?> getUserSignupForEvent({
    required String cleanSku,
    required String volunteerId,
  });

  Future<List<EventSignupModel>> getSignupsForVolunteer(String volunteerId);

  Future<EventSignupModel> upsertSignup(EventSignupModel signup);

  Future<bool> deleteSignup({
    required String cleanSku,
    required String volunteerId,
  });
}

/// Production Firestore store backed by `event_signups/{sku}_{uid}`.
/// Never stores volunteer PII (`email`, `phone`) on signup documents.
class FirestoreSignupStore implements SignupStore {
  final FirebaseFirestore _firestore;

  FirestoreSignupStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _signupsRef =>
      _firestore.collection('event_signups');

  @override
  Future<List<EventSignupModel>> getSignupsForEvent(String cleanSku) async {
    final snap = await _signupsRef.where('sku', isEqualTo: cleanSku).get();
    final items = snap.docs
        .map((doc) => EventSignupModel.fromFirestoreMap(doc.id, doc.data()))
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<EventSignupModel?> getUserSignupForEvent({
    required String cleanSku,
    required String volunteerId,
  }) async {
    final docId = EventSignupModel.buildCompositeId(cleanSku, volunteerId);
    final doc = await _signupsRef.doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return EventSignupModel.fromFirestoreMap(doc.id, doc.data()!);
  }

  @override
  Future<List<EventSignupModel>> getSignupsForVolunteer(
    String volunteerId,
  ) async {
    final snap =
        await _signupsRef.where('volunteerId', isEqualTo: volunteerId).get();
    final items = snap.docs
        .map((doc) => EventSignupModel.fromFirestoreMap(doc.id, doc.data()))
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<EventSignupModel> upsertSignup(EventSignupModel signup) async {
    final docId =
        EventSignupModel.buildCompositeId(signup.sku, signup.volunteerId);
    final normalized = signup.copyWith(
      id: docId,
      sku: signup.sku.trim().toUpperCase(),
      epVerified: false,
      volunteer: null,
    );
    await _signupsRef.doc(docId).set(normalized.toFirestoreMap());
    return normalized;
  }

  @override
  Future<bool> deleteSignup({
    required String cleanSku,
    required String volunteerId,
  }) async {
    final docId = EventSignupModel.buildCompositeId(cleanSku, volunteerId);
    final docRef = _signupsRef.doc(docId);
    final existing = await docRef.get();
    if (!existing.exists) return false;
    await docRef.delete();
    return true;
  }
}

/// Deterministic in-memory store for fast unit and widget tests (no demo seed data).
class InMemorySignupStore implements SignupStore {
  final Map<String, Map<String, dynamic>> _docs = {};

  InMemorySignupStore({List<EventSignupModel> initialSignups = const []}) {
    for (final s in initialSignups) {
      final docId = EventSignupModel.buildCompositeId(s.sku, s.volunteerId);
      _docs[docId] =
          s.copyWith(id: docId, epVerified: false).toFirestoreMap(
                updatedAtTimestamp: s.updatedAt.toIso8601String(),
              );
    }
  }

  Map<String, dynamic>? getRawDoc(String docId) => _docs[docId];

  @override
  Future<List<EventSignupModel>> getSignupsForEvent(String cleanSku) async {
    final items = _docs.entries
        .where((e) => e.value['sku'] == cleanSku)
        .map((e) => EventSignupModel.fromFirestoreMap(e.key, e.value))
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<EventSignupModel?> getUserSignupForEvent({
    required String cleanSku,
    required String volunteerId,
  }) async {
    final docId = EventSignupModel.buildCompositeId(cleanSku, volunteerId);
    final raw = _docs[docId];
    if (raw == null) return null;
    return EventSignupModel.fromFirestoreMap(docId, raw);
  }

  @override
  Future<List<EventSignupModel>> getSignupsForVolunteer(
    String volunteerId,
  ) async {
    final items = _docs.entries
        .where((e) => e.value['volunteerId'] == volunteerId)
        .map((e) => EventSignupModel.fromFirestoreMap(e.key, e.value))
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<EventSignupModel> upsertSignup(EventSignupModel signup) async {
    final docId =
        EventSignupModel.buildCompositeId(signup.sku, signup.volunteerId);
    final normalized = signup.copyWith(
      id: docId,
      sku: signup.sku.trim().toUpperCase(),
      epVerified: false,
      volunteer: null,
    );
    _docs[docId] = normalized.toFirestoreMap(
      updatedAtTimestamp: normalized.updatedAt.toIso8601String(),
    );
    return normalized;
  }

  @override
  Future<bool> deleteSignup({
    required String cleanSku,
    required String volunteerId,
  }) async {
    final docId = EventSignupModel.buildCompositeId(cleanSku, volunteerId);
    return _docs.remove(docId) != null;
  }
}

class VolunteerRepository {
  final SignupStore _store;

  VolunteerRepository(this._store);

  /// Get signups for a specific event SKU
  Future<List<EventSignupModel>> getSignupsForEvent(String sku) {
    final cleanSku = sku.trim().toUpperCase();
    return _store.getSignupsForEvent(cleanSku);
  }

  /// Get current user's signup for an event (if any)
  Future<EventSignupModel?> getUserSignupForEvent({
    required String sku,
    required String volunteerId,
  }) {
    final cleanSku = sku.trim().toUpperCase();
    return _store.getUserSignupForEvent(
      cleanSku: cleanSku,
      volunteerId: volunteerId,
    );
  }

  /// Get all event signups for a specific volunteer
  Future<List<EventSignupModel>> getSignupsForVolunteer(String volunteerId) {
    return _store.getSignupsForVolunteer(volunteerId);
  }

  /// Save or update a volunteer signup (Available or Confirmed) without embedding PII
  Future<EventSignupModel> saveSignup({
    required String sku,
    required VolunteerModel volunteer,
    required SignupStatus status,
    required List<String> offeredRoles,
    String? otherRoleDescription,
    String? notes,
  }) {
    final cleanSku = sku.trim().toUpperCase();
    final docId = EventSignupModel.buildCompositeId(cleanSku, volunteer.id);

    final signup = EventSignupModel(
      id: docId,
      sku: cleanSku,
      volunteerId: volunteer.id,
      volunteerName: volunteer.name.trim(),
      status: status,
      epVerified: false,
      offeredRoles: offeredRoles,
      otherRoleDescription: otherRoleDescription,
      notes: notes,
      updatedAt: DateTime.now(),
    );

    return _store.upsertSignup(signup);
  }

  /// Volunteer withdraws / pulls out of an event
  Future<bool> withdrawSignup({
    required String sku,
    required String volunteerId,
  }) {
    final cleanSku = sku.trim().toUpperCase();
    return _store.deleteSignup(cleanSku: cleanSku, volunteerId: volunteerId);
  }

  /// Disabled in v1 while all users are volunteers (`epVerified` locked to `false` in Firestore rules).
  Future<EventSignupModel?> toggleEpVerification({
    required String signupId,
  }) async {
    throw UnsupportedError(
      'Event Partner verification is disabled in v1 while all accounts are volunteer-scoped.',
    );
  }
}
