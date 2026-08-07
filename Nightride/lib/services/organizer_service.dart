import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a signed-in account stands in the organizer pipeline.
enum OrganizerAccess {
  /// Approved by an admin — the organizer dashboard is unlocked.
  approved,

  /// An application exists and is still being reviewed.
  pending,

  /// An application was reviewed and turned down.
  rejected,

  /// A normal account that has never applied.
  none,
}

final organizerServiceProvider = Provider<OrganizerService>(
  (ref) => OrganizerService(FirebaseFirestore.instance),
);

/// Reads organizer state for a uid.
///
/// Three systems write this data and none of them agree on a single field, so
/// all three are checked in priority order:
///   1. `users/{uid}.isOrganizer` — set by the in-app admin panel on approval.
///   2. `users/{uid}.role == 'organizer'` — what the main sign-in flow routes on.
///   3. `users/{uid}.organizerApplication` — the webpanel's application
///      (nightride-webpanel/lib/organizer/application-service.ts).
///   4. `organizer_requests/{uid}` — the legacy in-app application form.
class OrganizerService {
  const OrganizerService(this._db);

  final FirebaseFirestore _db;

  Future<OrganizerAccess> accessFor(String uid) async {
    final profile = (await _db.collection('users').doc(uid).get()).data();

    if (profile?['isOrganizer'] == true || profile?['role'] == 'organizer') {
      return OrganizerAccess.approved;
    }

    final application = profile?['organizerApplication'];
    if (application is Map) {
      return application['rejected'] == true
          ? OrganizerAccess.rejected
          : OrganizerAccess.pending;
    }

    // `organizer_requests` has no match in firestore.rules, so this read is
    // denied outright on a locked-down project. A failure here means "we can't
    // see a legacy application", not "something went wrong" — fall through to
    // `none` so the applicant is offered the form rather than an error.
    try {
      final request =
          (await _db.collection('organizer_requests').doc(uid).get()).data();
      switch (request?['status'] as String?) {
        case 'approved':
          return OrganizerAccess.approved;
        case 'rejected':
          return OrganizerAccess.rejected;
        case 'pending':
          return OrganizerAccess.pending;
      }
    } catch (_) {}

    return OrganizerAccess.none;
  }

  /// The admin's note explaining a rejection, when the webpanel recorded one.
  Future<String> rejectionReasonFor(String uid) async {
    final profile = (await _db.collection('users').doc(uid).get()).data();
    final application = profile?['organizerApplication'];
    if (application is Map) {
      final reason = application['rejectionReason'];
      if (reason is String && reason.trim().isNotEmpty) return reason.trim();
    }
    return '';
  }
}
