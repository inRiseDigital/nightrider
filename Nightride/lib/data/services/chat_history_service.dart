import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

class ChatHistoryService {
  static const _maxSessions = 30;

  CollectionReference<Map<String, dynamic>>? _col() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chat_sessions');
  }

  /// Live stream of sessions, newest first.
  Stream<List<ChatSession>> sessionsStream() {
    final col = _col();
    if (col == null) return const Stream.empty();
    return col
        .orderBy('updatedAt', descending: true)
        .limit(_maxSessions)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatSession.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  Future<void> saveSession(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;
    final col = _col();
    if (col == null) return;
    final now = DateTime.now();
    final id = const Uuid().v4();
    final session = ChatSession(
      id: id,
      title: _makeTitle(messages),
      messages: List.from(messages),
      createdAt: now,
      updatedAt: now,
    );
    await col.doc(id).set(session.toJson());
  }

  Future<void> deleteSession(String id) async {
    await _col()?.doc(id).delete();
  }

  Future<void> clearAll() async {
    final col = _col();
    if (col == null) return;
    final snap = await col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _makeTitle(List<ChatMessage> messages) {
    final first = messages.firstWhere((m) => m.role == 'user',
        orElse: () => messages.first);
    final text = first.content.trim().replaceAll('\n', ' ');
    return text.length > 45 ? '${text.substring(0, 45)}…' : text;
  }
}
