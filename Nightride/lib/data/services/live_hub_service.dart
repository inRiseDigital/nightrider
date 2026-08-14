// lib/data/services/live_hub_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nightride/domain/live_hub_models.dart';

/// The Live Hub is a composition of three ordinary collections, not a set of
/// parallel `live_hub_*` feeds. That second event pipeline was the actual defect
/// in the old design: scraped listings are events and belong in `events`, and
/// door status belongs to the venue rather than to a feed keyed by a name
/// string.
///
///   Clubs   — `venues` filtered by country, reading each venue's `live` map
///   Reports — `venueReports` ordered by createdAt desc
///   Social  — `events` where source == 'scraped', ordered by popularityScore
///
/// The domain models are unchanged, so this maps the new documents into the
/// shapes `live_hub_models.dart` already parses.
class LiveHubService {
  static final _db = FirebaseFirestore.instance;

  static const _pageSize = 50;

  // ── Clubs ──────────────────────────────────────────────────────────────────

  /// Venue queries are bounded on purpose: the collection is seeded globally
  /// from OpenStreetMap, so an unfiltered read would pull the whole planet.
  Stream<List<ClubUpdate>> clubsStream({String? country}) {
    Query<Map<String, dynamic>> q = _db.collection('venues');
    if (country != null) {
      q = q.where('countryCode', isEqualTo: country.toUpperCase());
    }
    return q.limit(_pageSize).snapshots().map((snap) => snap.docs
        .where((d) => d.data()['live'] is Map)
        .map((d) => ClubUpdate.fromJson(_clubJson(d)))
        .toList());
  }

  Map<String, dynamic> _clubJson(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final live = Map<String, dynamic>.from(data['live'] as Map);
    final photos = data['photos'];
    return {
      'id': doc.id,
      'clubName': data['name'] ?? '',
      'city': data['city'] ?? '',
      'country': data['countryCode'] ?? '',
      'imageUrl': (photos is List && photos.isNotEmpty) ? photos.first : '',
      'status': live['status'],
      'crowdLevel': live['crowdLevel'],
      'queueStatus': live['queueStatus'],
      'ticketsAvailable': live['ticketsAvailable'] ?? false,
      'tablesAvailable': live['tablesAvailable'] ?? false,
      'tonightDj': live['tonightDj'],
      'offer': live['offer'],
      // Rendered from the timestamp rather than stored as text, so it stays
      // true as time passes instead of being frozen at "Just now".
      'lastUpdated': _relative(live['updatedAt']),
    };
  }

  /// Door status is owned by the venue's approved organizer, or by an admin.
  /// `live.updatedAt` must be the server clock — the rules require it.
  Future<void> updateVenueLive(String venueId, Map<String, dynamic> live) =>
      _db.collection('venues').doc(venueId).update({
        'live': {...live, 'updatedAt': FieldValue.serverTimestamp()},
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── User reports ───────────────────────────────────────────────────────────

  Stream<List<UserReport>> reportsStream({String? country}) {
    Query<Map<String, dynamic>> q = _db.collection('venueReports');
    if (country != null) {
      q = q.where('countryCode', isEqualTo: country.toUpperCase());
    }
    return q
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return UserReport.fromJson({
                'id': d.id,
                'clubName': data['venueName'] ?? '',
                'city': data['city'] ?? '',
                'country': data['countryCode'] ?? '',
                'username': data['username'] ?? '',
                'avatarUrl': data['avatarUrl'] ?? '',
                'tag': data['tag'] ?? '',
                'vibeRating': (data['vibeRating'] as num?)?.round() ?? 0,
                'comment': data['comment'],
                'upvotes': data['upvoteCount'] ?? 0,
                'timeAgo': _relative(data['createdAt']),
              });
            }).toList());
  }

  /// `comment` is always written, defaulting to an empty string. Omitting the
  /// field entirely is what used to make every commentless report fail the
  /// rule that requires a string.
  Future<void> submitReport({
    required String venueId,
    required String venueName,
    required String city,
    required String countryCode,
    required String username,
    required String avatarUrl,
    required String tag,
    required int vibeRating,
    String? comment,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('A report needs a signed-in author.');
    }
    return _db.collection('venueReports').add({
      'venueId': venueId,
      'venueName': venueName,
      'uid': uid,
      'username': username,
      'avatarUrl': avatarUrl,
      'city': city,
      'countryCode': countryCode.toUpperCase(),
      'tag': tag,
      'vibeRating': vibeRating,
      'comment': comment ?? '',
      'upvoteCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// An upvote is two writes in one batch: the voter's marker document and the
  /// counter increment. The order is load-bearing — the rule refuses the
  /// increment once the marker exists, so committing the marker on its own
  /// first would deny the increment permanently.
  Future<void> upvoteReport(String reportId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final report = _db.collection('venueReports').doc(reportId);
    final marker = report.collection('upvotes').doc(uid);
    if ((await marker.get()).exists) return;

    final batch = _db.batch()
      ..set(marker, {'at': FieldValue.serverTimestamp()})
      ..update(report, {'upvoteCount': FieldValue.increment(1)});

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      // Someone else's write landed between the check and the commit; the
      // vote is already counted, which is the outcome the caller wanted.
      if (error.code != 'permission-denied') rethrow;
    }
  }

  // ── Social events ──────────────────────────────────────────────────────────

  /// Scraped listings live in `events` like everything else, distinguished by
  /// `source` rather than by living in their own collection.
  Stream<List<SocialEvent>> eventsStream({String? country}) {
    Query<Map<String, dynamic>> q = _db
        .collection('events')
        .where('status', isEqualTo: 'published')
        .where('source', isEqualTo: 'scraped');
    if (country != null) {
      q = q.where('countryCode', isEqualTo: country.toUpperCase());
    }
    return q
        .orderBy('popularityScore', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final startAt = (data['startAt'] as Timestamp?)?.toDate();
              return SocialEvent.fromJson({
                'id': d.id,
                'title': data['name'] ?? '',
                'clubName': data['venueName'] ?? '',
                'city': data['city'] ?? '',
                'country': data['countryCode'] ?? '',
                'imageUrl': data['coverImage'],
                'djName': _firstPerformer(data['performers']),
                'date': startAt == null ? '' : _isoDate(startAt),
                'time': startAt == null ? '' : _clockTime(startAt),
                'ticketUrl': data['ticketUrl'],
                'source': 'scraped',
                'popularityScore': (data['popularityScore'] as num?)?.round() ?? 0,
                // Trending is decided by the query that orders on the counter,
                // not by a flag stored on the document.
                'isTrending': false,
              });
            }).toList());
  }

  static String? _firstPerformer(Object? performers) {
    if (performers is List && performers.isNotEmpty) {
      final first = performers.first;
      if (first is Map && first['name'] is String) return first['name'] as String;
    }
    return null;
  }

  static String _isoDate(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  static String _clockTime(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  /// A pending server timestamp reads as null on the writer's own snapshot
  /// before the round trip completes, which is the one moment "Just now" is
  /// actually true.
  static String _relative(Object? timestamp) {
    if (timestamp is! Timestamp) return 'Just now';
    final elapsed = DateTime.now().difference(timestamp.toDate());
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }
}
