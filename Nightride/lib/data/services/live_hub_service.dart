// lib/data/services/live_hub_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightride/domain/live_hub_models.dart';

class LiveHubService {
  static final _db = FirebaseFirestore.instance;

  // ── Clubs ────────────────────────────────────────────────────────────────────

  Stream<List<ClubUpdate>> clubsStream({String? country}) {
    Query<Map<String, dynamic>> q = _db.collection('live_hub_clubs');
    if (country != null) {
      q = q.where('country', isEqualTo: country);
    }
    return q.snapshots().map((snap) => snap.docs
        .map((d) => ClubUpdate.fromJson({...d.data(), 'id': d.id}))
        .toList());
  }

  Future<void> updateClubStatus(String id, Map<String, dynamic> fields) =>
      _db.collection('live_hub_clubs').doc(id).update({
        ...fields,
        'lastUpdated': 'Just now',
      });

  // ── User reports ─────────────────────────────────────────────────────────────

  Stream<List<UserReport>> reportsStream({String? country}) {
    Query<Map<String, dynamic>> q;
    if (country != null) {
      q = _db
          .collection('live_hub_reports')
          .where('country', isEqualTo: country)
          .orderBy('createdAt', descending: true)
          .limit(50);
    } else {
      q = _db
          .collection('live_hub_reports')
          .orderBy('createdAt', descending: true)
          .limit(50);
    }
    return q.snapshots().map((snap) => snap.docs
        .map((d) => UserReport.fromJson({...d.data(), 'id': d.id}))
        .toList());
  }

  Future<void> submitReport({
    required String clubName,
    required String city,
    required String country,
    required String username,
    required String avatarUrl,
    required String tag,
    required int vibeRating,
    String? comment,
  }) =>
      _db.collection('live_hub_reports').add({
        'clubName': clubName,
        'city': city,
        'country': country,
        'username': username,
        'avatarUrl': avatarUrl,
        'tag': tag,
        'vibeRating': vibeRating,
        if (comment != null) 'comment': comment,
        'upvotes': 0,
        'timeAgo': 'Just now',
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> upvoteReport(String id) =>
      _db.collection('live_hub_reports').doc(id).update({
        'upvotes': FieldValue.increment(1),
      });

  // ── Social events ────────────────────────────────────────────────────────────

  Stream<List<SocialEvent>> eventsStream({String? country}) {
    Query<Map<String, dynamic>> q;
    if (country != null) {
      q = _db
          .collection('live_hub_social')
          .where('country', isEqualTo: country)
          .orderBy('popularityScore', descending: true)
          .limit(50);
    } else {
      q = _db
          .collection('live_hub_social')
          .orderBy('popularityScore', descending: true)
          .limit(50);
    }
    return q.snapshots().map((snap) => snap.docs
        .map((d) => SocialEvent.fromJson({...d.data(), 'id': d.id}))
        .toList());
  }
}
