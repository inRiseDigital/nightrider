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

  /// Live per-step review state — so the checklist unlocks `gps` the moment
  /// an admin accepts the venue address, or reopens a step with
  /// `needs_info`, without the applicant needing to re-open the screen.
  Stream<Map<String, dynamic>> watchReviewSteps(String uid) =>
      _reviewDoc(uid).snapshots().map((snapshot) {
        final steps = snapshot.data()?['steps'];
        return steps is Map ? Map<String, dynamic>.from(steps) : <String, dynamic>{};
      });

  /// The applicant's own `organizerApplication.steps` claims (`uploaded`
  /// flags) — separate from [watchReviewSteps] because only an admin can ever
  /// write the review document, so "I uploaded something" and "an admin
  /// looked at it" are necessarily two different streams.
  Stream<Map<String, dynamic>> watchApplicationSteps(String uid) =>
      _userDoc(uid).snapshots().map((snapshot) {
        final steps = snapshot.data()?['organizerApplication']?['steps'];
        return steps is Map ? Map<String, dynamic>.from(steps) : <String, dynamic>{};
      });

  /// The applicant's claim that they uploaded evidence for [stepId]. This is
  /// advisory only (see `OrganizerApplication` in FIRESTORE_SCHEMA.md) — the
  /// review UI derives the real object paths from Storage directly. Storage's
  /// own rules are what actually gate the upload this flag merely records.
  ///
  /// `applicationOk()` in firestore.rules requires `submittedAt == request.time`
  /// on *every* write that touches `organizerApplication` at all — not just the
  /// initial submission — so this resubmits `submitted`/`submittedAt` alongside
  /// the step flag rather than patching the step in isolation.
  Future<void> markStepUploaded(String uid, String stepId) {
    return _userDoc(uid).set({
      'organizerApplication': {
        'submitted': true,
        'submittedAt': FieldValue.serverTimestamp(),
        'steps': {
          stepId: {'uploaded': true},
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Records one GPS fix against the current gps attempt. `attempt` must be
  /// the admin-owned `organizerReview.steps.gps.attempt` the caller read just
  /// before capturing — it is not chosen here. Timestamps inside array
  /// elements must be the client clock: Firestore rejects a `serverTimestamp`
  /// sentinel inside an array.
  Future<void> appendGpsObservation(
    String uid, {
    required GeoPoint point,
    required double accuracyM,
    required bool mocked,
    required int attempt,
  }) {
    return _userDoc(uid).set({
      'organizerApplication': {
        'submitted': true,
        'submittedAt': FieldValue.serverTimestamp(),
        'steps': {
          'gps': {
            'attempts': FieldValue.arrayUnion([
              {
                'point': point,
                'accuracyM': accuracyM,
                'mocked': mocked,
                'capturedAt': Timestamp.now(),
                'attempt': attempt,
              },
            ]),
          },
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
