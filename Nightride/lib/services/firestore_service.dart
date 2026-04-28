import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamEvents({String? status}) {
    Query<Map<String, dynamic>> q = _events.orderBy('date', descending: false);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots();
  }

  Future<void> addEvent(Map<String, dynamic> data) async {
    final now = FieldValue.serverTimestamp();
    await _events.add({...data, 'created_at': now, 'updated_at': now});
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _events
        .doc(id)
        .update({...data, 'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> deleteEvent(String id) async {
    await _events.doc(id).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getEvent(String id) =>
      _events.doc(id).get();
}

final firestoreService = FirestoreService();
