import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/services/auth_service.dart';
import 'notification_service.dart';

class FavouritesService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('favourites');

  Stream<List<Map<String, dynamic>>> stream(String uid) =>
      _col(uid).orderBy('saved_at', descending: true).snapshots().map(
            (s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );

  Future<bool> isFavourite(String uid, String eventId) async {
    final doc = await _col(uid).doc(eventId).get();
    return doc.exists;
  }

  Future<void> add(String uid, Map<String, dynamic> event) async {
    final eventId = event['id'] as String? ?? '';
    if (eventId.isEmpty) return;
    try {
      final docRef = _col(uid).doc(eventId);
      final existing = await docRef.get();
      // Only award points for a genuinely new save, not a re-save of an event
      // the user removed and re-added (prevents rank farming).
      final isNew = !existing.exists;

      await docRef.set({
        ...event,
        'saved_at': FieldValue.serverTimestamp(),
      });

      if (isNew) {
        _db.collection('users').doc(uid).set(
          {'rank': FieldValue.increment(5)},
          SetOptions(merge: true),
        );
      }

      final dateStr = event['date'] as String?;
      final title = event['name'] as String? ?? event['title'] as String? ?? 'Event';
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          await NotificationService.scheduleEventReminders(
            eventId: eventId,
            eventTitle: title,
            dateStr: dateStr,
          );
        } catch (_) {}
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> remove(String uid, String eventId) async {
    if (eventId.isEmpty) return;
    try {
      await _col(uid).doc(eventId).delete();
      try {
        await NotificationService.cancelEventReminders(eventId);
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }
}

final favouritesServiceProvider = Provider<FavouritesService>((_) => FavouritesService());

final favouritesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(favouritesServiceProvider).stream(uid);
});

final isFavouriteProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return false;
  return ref.read(favouritesServiceProvider).isFavourite(uid, eventId);
});
