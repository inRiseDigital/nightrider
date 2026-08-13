import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightride/domain/event.dart';

/// Firestore access for `events/{eventId}`, matching the decided schema in
/// docs/FIRESTORE_SCHEMA.md. Every list query below carries a `limit` and is
/// backed by one of the composite indexes committed in
/// nightride-webpanel/firestore.indexes.json — see the doc comment on each
/// method for which one.
class FirestoreService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  static const int defaultListLimit = 60;

  // ── Legacy raw-map API ──────────────────────────────────────────────────
  // Kept only because lib/pages/admin/admin_panel_page.dart and
  // admin_add_event_page.dart (both out of this migration's scope) still call
  // these with the old snake_case shape. They are not schema-compliant and
  // the updated Firestore rules will reject writes made through `addEvent`/
  // `updateEvent` once the admin pages are migrated — that migration is not
  // part of this change. Do not add new callers of these.

  @Deprecated('Writes the pre-migration shape; use createOrganizerEvent/updateOrganizerEvent instead.')
  Stream<QuerySnapshot<Map<String, dynamic>>> streamEvents({String? status}) {
    Query<Map<String, dynamic>> q = _events.orderBy('date', descending: false);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots();
  }

  @Deprecated('Writes the pre-migration shape; use createOrganizerEvent instead.')
  Future<void> addEvent(Map<String, dynamic> data) async {
    final now = FieldValue.serverTimestamp();
    await _events.add({...data, 'created_at': now, 'updated_at': now});
  }

  @Deprecated('Writes the pre-migration shape; use updateOrganizerEvent instead.')
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _events
        .doc(id)
        .update({...data, 'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> deleteEvent(String id) async {
    await _events.doc(id).delete();
  }

  // ── Typed reads ──────────────────────────────────────────────────────────

  Future<Event?> getEvent(String id) async {
    final doc = await _events.doc(id).get();
    if (!doc.exists) return null;
    return Event.fromFirestore(doc);
  }

  /// status == 'published' && startAt >= now, ordered by startAt asc.
  /// Index: events(status ASC, startAt ASC)
  Stream<List<Event>> streamUpcomingEvents({int limit = defaultListLimit}) {
    return _events
        .where('status', isEqualTo: 'published')
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('startAt')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Event.fromFirestore).toList());
  }

  /// status == 'published' && countryCode == X && startAt >= now, ordered by startAt asc.
  /// Index: events(status ASC, countryCode ASC, startAt ASC)
  Stream<List<Event>> streamUpcomingEventsByCountry(
    String countryCode, {
    int limit = defaultListLimit,
  }) {
    return _events
        .where('status', isEqualTo: 'published')
        .where('countryCode', isEqualTo: countryCode)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('startAt')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Event.fromFirestore).toList());
  }

  /// Trending = top N by interestedCount among published events.
  /// Index: events(status ASC, interestedCount DESC)
  Stream<List<Event>> streamTrendingEvents({int limit = 20}) {
    return _events
        .where('status', isEqualTo: 'published')
        .orderBy('interestedCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Event.fromFirestore).toList());
  }

  /// Live Hub "Social" feed: status == 'published' && source == 'scraped',
  /// ordered by popularityScore desc.
  /// Index: events(status ASC, source ASC, popularityScore DESC)
  Stream<List<Event>> streamScrapedSocialFeed({int limit = 50}) {
    return _events
        .where('status', isEqualTo: 'published')
        .where('source', isEqualTo: 'scraped')
        .orderBy('popularityScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Event.fromFirestore).toList());
  }

  /// status == 'published', ordered by name, with a prefix range on name.
  /// Index: events(status ASC, name ASC)
  Stream<List<Event>> streamSearchEvents(String prefix, {int limit = 30}) {
    Query<Map<String, dynamic>> q =
        _events.where('status', isEqualTo: 'published').orderBy('name');
    final trimmed = prefix.trim();
    if (trimmed.isNotEmpty) {
      q = q.startAt([trimmed]).endAt(['$trimmed']);
    }
    return q.limit(limit).snapshots().map(
          (s) => s.docs.map(Event.fromFirestore).toList(),
        );
  }

  /// An organizer's own events, ordered by createdAt desc.
  /// Index: events(organizerUid ASC, createdAt DESC)
  Stream<List<Event>> streamOrganizerEvents(String uid, {int limit = 100}) {
    return _events
        .where('organizerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Event.fromFirestore).toList());
  }

  /// Distinct country codes among published events, for the country filter
  /// chip row. A single equality filter needs no composite index.
  Stream<List<String>> streamPublishedCountryCodes({int limit = 500}) {
    return _events
        .where('status', isEqualTo: 'published')
        .limit(limit)
        .snapshots()
        .map((s) {
      final seen = <String>{};
      for (final doc in s.docs) {
        final code = Event.fromFirestore(doc).countryCode;
        if (code.isNotEmpty) seen.add(code);
      }
      return seen.toList();
    });
  }

  // ── Typed writes ─────────────────────────────────────────────────────────

  /// Creates a new organizer event. `interestedCount`/`popularityScore` are
  /// always forced to 0 and `createdAt`/`updatedAt` to serverTimestamp() by
  /// [Event.toFirestore] — the rules pin both counters, and the client must
  /// never write anything else into them.
  Future<String> createOrganizerEvent(Event event) async {
    final ref = await _events.add(event.toFirestore(forCreate: true));
    return ref.id;
  }

  /// Updates an existing organizer event. The update map omits
  /// `interestedCount`/`popularityScore`/`createdAt` entirely (see
  /// [Event.toFirestore]), so `DocumentReference.update` leaves those fields
  /// untouched on the stored document.
  Future<void> updateOrganizerEvent(String id, Event event) async {
    await _events.doc(id).update(event.toFirestore(forCreate: false));
  }

  /// Narrow field patch (e.g. the publish/unpublish toggle). Refuses to touch
  /// the two pinned counters so a careless call site can't smuggle them in.
  Future<void> patchEventFields(String id, Map<String, dynamic> patch) async {
    assert(
      !patch.containsKey('interestedCount') && !patch.containsKey('popularityScore'),
      'interestedCount/popularityScore are pinned by the rules; never patch them from the client.',
    );
    await _events.doc(id).update({...patch, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ── Interest ─────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _interestedMarker(String eventId, String uid) =>
      _events.doc(eventId).collection('interested').doc(uid);

  Future<bool> isInterested(String eventId, String uid) async {
    final doc = await _interestedMarker(eventId, uid).get();
    return doc.exists;
  }

  /// Registers interest in an event. This is a single atomic
  /// [WriteBatch] that both creates `events/{id}/interested/{uid}` and
  /// increments `interestedCount` by exactly 1 — the two must land together.
  /// Committing the marker on its own first would make the rules deny the
  /// increment forever, because the increment rule requires the marker to be
  /// absent going into the write.
  ///
  /// Idempotent from the caller's point of view: if the marker already
  /// exists this is a no-op, and a permission-denied error from the batch
  /// (a race where the marker was created a moment ago) is swallowed as
  /// "already interested" rather than surfaced as a failure.
  Future<void> registerInterest(String eventId, String uid) async {
    final marker = _interestedMarker(eventId, uid);
    final existing = await marker.get();
    if (existing.exists) return;

    final batch = _db.batch();
    batch.set(marker, {'at': FieldValue.serverTimestamp()});
    batch.update(_events.doc(eventId), {'interestedCount': FieldValue.increment(1)});
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      rethrow;
    }
  }
}

final firestoreService = FirestoreService();
