import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin-only mutations for the organizer approval pipeline, matching
/// docs/FIRESTORE_SCHEMA.md and the rules in nightride-webpanel/firestore.rules:
///
///   - `users/{uid}` — only `organizerStatus`/`updatedAt` may be touched by an
///     admin (`adminUpdate()`), and only to one of the schema's enum values.
///   - `users/{uid}/private/organizerReview` — admin-only update, capped KYC
///     attempts (`attemptsCapped()`).
///   - `logs/{logId}` — create-only, `actorUid == request.auth.uid` and
///     `at == request.time`, action drawn from the schema's fixed enum.
///
/// Every method here is a single atomic [WriteBatch] so the user document,
/// the verdict document, and the audit log entry land together or not at all.
class AdminActionsService {
  AdminActionsService(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _reviewSteps = ['venueAddress', 'nic', 'selfie', 'video', 'gps'];

  String get _adminUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in admin.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _reviewRef(String uid) =>
      _userRef(uid).collection('private').doc('organizerReview');

  void _appendLog(
    WriteBatch batch, {
    required String action,
    required String targetId,
    required String summary,
  }) {
    batch.set(_db.collection('logs').doc(), {
      'action': action,
      'actorUid': _adminUid,
      'targetType': 'user',
      'targetId': targetId,
      'summary': summary.length > 500 ? summary.substring(0, 500) : summary,
      'at': FieldValue.serverTimestamp(),
    });
  }

  /// Approves an organizer application: unlocks `organizerStatus` and closes
  /// out every KYC review step as accepted in one admin decision. This panel
  /// only offers a single blanket approve/reject, not per-step review.
  Future<void> approveOrganizer(String uid, {String displayName = ''}) async {
    final admin = _adminUid;
    final batch = _db.batch();

    batch.update(_userRef(uid), {
      'organizerStatus': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final reviewPatch = <String, dynamic>{
      'status': 'approved',
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': admin,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    for (final step in _reviewSteps) {
      reviewPatch['steps.$step.status'] = 'accepted';
      reviewPatch['steps.$step.reviewedAt'] = FieldValue.serverTimestamp();
      reviewPatch['steps.$step.reviewedBy'] = admin;
    }
    batch.update(_reviewRef(uid), reviewPatch);

    _appendLog(
      batch,
      action: 'organizer.approve',
      targetId: uid,
      summary: displayName.isEmpty ? 'Organizer approved' : 'Approved $displayName',
    );
    await batch.commit();
  }

  /// Rejects an organizer application with a reason shown to the applicant.
  Future<void> rejectOrganizer(String uid, String reason, {String displayName = ''}) async {
    final admin = _adminUid;
    final batch = _db.batch();

    batch.update(_userRef(uid), {
      'organizerStatus': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_reviewRef(uid), {
      'status': 'rejected',
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': admin,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _appendLog(
      batch,
      action: 'organizer.reject',
      targetId: uid,
      summary: displayName.isEmpty ? 'Organizer rejected' : 'Rejected $displayName',
    );
    await batch.commit();
  }

  /// Revokes a previously-approved organizer's access.
  Future<void> revokeOrganizer(String uid, {String displayName = ''}) async {
    final admin = _adminUid;
    final batch = _db.batch();

    batch.update(_userRef(uid), {
      'organizerStatus': 'revoked',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_reviewRef(uid), {
      'status': 'revoked',
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': admin,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _appendLog(
      batch,
      action: 'organizer.revoke',
      targetId: uid,
      summary: displayName.isEmpty ? 'Organizer revoked' : 'Revoked $displayName',
    );
    await batch.commit();
  }
}

final adminActionsService = AdminActionsService(FirebaseFirestore.instance, FirebaseAuth.instance);
