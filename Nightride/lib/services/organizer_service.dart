import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a signed-in account stands in the organizer pipeline.
enum OrganizerAccess {
  /// Approved by an admin — the organizer dashboard is unlocked.
  approved,

  /// An application has been submitted and is waiting on, or in front of, an
  /// admin. `organizerStatus` alone cannot tell those two apart, which is the
  /// point: only an admin can move the field, so an untriaged application sits
  /// at 'none' with `organizerApplication.submitted` true.
  pending,

  /// An application was reviewed and turned down.
  rejected,

  /// Approval was withdrawn after the fact.
  revoked,

  /// A normal account that has never applied.
  none,
}

final organizerServiceProvider = Provider<OrganizerService>(
  (ref) => OrganizerService(FirebaseFirestore.instance),
);

/// Reads organizer state for a uid.
///
/// There is exactly one source of truth now: `users/{uid}.organizerStatus`,
/// which only an admin can write. `isOrganizer`, `role` and the
/// `organizer_requests` collection are all gone — the last of those is denied
/// by firestore.rules, so the old fallback chain could only ever have thrown.
///
/// The reviewer's notes live in `users/{uid}/private/organizerReview`, readable
/// by the owner and by admins and writable by neither the applicant nor this
/// app.
class OrganizerService {
  const OrganizerService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _reviewDoc(String uid) =>
      _userDoc(uid).collection('private').doc('organizerReview');

  Future<OrganizerAccess> accessFor(String uid) async {
    final profile = (await _userDoc(uid).get()).data();
    if (profile == null) return OrganizerAccess.none;

    switch (profile['organizerStatus'] as String?) {
      case 'approved':
        return OrganizerAccess.approved;
      case 'rejected':
        return OrganizerAccess.rejected;
      case 'revoked':
        return OrganizerAccess.revoked;
      case 'pending':
        return OrganizerAccess.pending;
    }

    // 'none' with a submitted application means nobody has picked it up yet,
    // which reads as pending to the applicant even though no admin has it.
    final application = profile['organizerApplication'];
    if (application is Map && application['submitted'] == true) {
      return OrganizerAccess.pending;
    }

    return OrganizerAccess.none;
  }

  /// Live access state, so the dashboard unlocks the moment an admin approves
  /// rather than on the next cold start.
  Stream<OrganizerAccess> watchAccess(String uid) =>
      _userDoc(uid).snapshots().map((snapshot) {
        final profile = snapshot.data();
        if (profile == null) return OrganizerAccess.none;

        switch (profile['organizerStatus'] as String?) {
          case 'approved':
            return OrganizerAccess.approved;
          case 'rejected':
            return OrganizerAccess.rejected;
          case 'revoked':
            return OrganizerAccess.revoked;
          case 'pending':
            return OrganizerAccess.pending;
        }

        final application = profile['organizerApplication'];
        if (application is Map && application['submitted'] == true) {
          return OrganizerAccess.pending;
        }
        return OrganizerAccess.none;
      });

  /// The admin's note explaining a rejection.
  Future<String> rejectionReasonFor(String uid) async {
    final review = (await _reviewDoc(uid).get()).data();
    final reason = review?['rejectionReason'];
    return reason is String ? reason.trim() : '';
  }

  /// Per-step review state, for showing the applicant what an admin asked for.
  /// Returns an empty map when no application has been started.
  Future<Map<String, dynamic>> reviewStepsFor(String uid) async {
    final review = (await _reviewDoc(uid).get()).data();
    final steps = review?['steps'];
    return steps is Map ? Map<String, dynamic>.from(steps) : <String, dynamic>{};
  }
}
