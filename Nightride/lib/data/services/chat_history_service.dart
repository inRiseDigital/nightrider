import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

/// Chat history for the AI companion.
///
/// Messages are a subcollection of the session, not an array on the session
/// document. An inline array grows without bound against Firestore's 1 MiB
/// document limit and rewrites the entire document on every turn, so a long
/// conversation would eventually fail to save at all — silently, mid-chat.
///
/// Timestamps are real `Timestamp` values rather than ISO strings, so the
/// session list can be ordered by the server's clock instead of by string
/// comparison over whatever the device thought the time was.
class ChatHistoryService {
  static const _maxSessions = 30;
  static const _maxMessagesPerSession = 500;

  /// How many messages of each session are already in Firestore, so a save
  /// appends the new turn rather than rewriting the whole conversation.
  final Map<String, int> _persistedCounts = {};

  CollectionReference<Map<String, dynamic>>? _col() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_sessions');
  }

  /// Live stream of sessions, newest first. Messages are not loaded here — the
  /// list only needs a title and a timestamp, and fetching every message of
  /// thirty sessions to render thirty rows would be the array problem again,
  /// paid in reads instead of document size.
  Stream<List<ChatSession>> sessionsStream() {
    final col = _col();
    if (col == null) return const Stream.empty();
    return col
        .orderBy('createdAt', descending: true)
        .limit(_maxSessions)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return ChatSession(
                id: d.id,
                title: data['title'] as String? ?? '',
                messages: const [],
                createdAt: _toDate(data['createdAt']),
                updatedAt: _toDate(data['updatedAt']),
              );
            }).toList());
  }

  /// Loads one session's messages, in order.
  Future<List<ChatMessage>> messagesFor(String sessionId) async {
    final col = _col();
    if (col == null) return const [];
    final snap = await col
        .doc(sessionId)
        .collection('messages')
        .orderBy('at')
        .limit(_maxMessagesPerSession)
        .get();
    _persistedCounts[sessionId] = snap.docs.length;
    return snap.docs.map((d) {
      final data = d.data();
      return ChatMessage(
        content: data['text'] as String? ?? '',
        role: data['role'] as String? ?? 'user',
        timestamp: _toDate(data['at']),
      );
    }).toList();
  }

  /// Creates a session or appends to it. Returns the session id.
  ///
  /// Message documents are keyed by their position in the conversation, so a
  /// retry after a failed save overwrites the same document instead of
  /// appending a duplicate turn.
  Future<String> upsertSession(String? sessionId, List<ChatMessage> messages) async {
    if (messages.isEmpty) return sessionId ?? '';
    final col = _col();
    if (col == null) return sessionId ?? '';

    final id = sessionId ?? const Uuid().v4();
    final session = col.doc(id);
    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      session,
      {
        'title': _makeTitle(messages),
        'updatedAt': FieldValue.serverTimestamp(),
        if (sessionId == null) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Without a known count — a session resumed in a later app run — every
    // message is rewritten, which the deterministic ids make harmless.
    final alreadySaved = _persistedCounts[id] ?? 0;
    for (var i = alreadySaved; i < messages.length; i++) {
      final message = messages[i];
      batch.set(
        session.collection('messages').doc(_messageId(i)),
        {
          'role': message.role,
          'text': message.content,
          'at': Timestamp.fromDate(message.timestamp),
        },
      );
    }

    await batch.commit();
    _persistedCounts[id] = messages.length;
    return id;
  }

  Future<void> deleteSession(String id) async {
    final col = _col();
    if (col == null) return;

    // Firestore does not delete subcollections with their parent, and there is
    // no Cloud Function to sweep up after this, so the messages are removed
    // explicitly. Skipping it would orphan them permanently.
    final messages = await col.doc(id).collection('messages').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(col.doc(id));
    await batch.commit();
    _persistedCounts.remove(id);
  }

  Future<void> clearAll() async {
    final col = _col();
    if (col == null) return;
    final snap = await col.get();
    for (final doc in snap.docs) {
      await deleteSession(doc.id);
    }
    _persistedCounts.clear();
  }

  /// Zero-padded so lexical document order matches conversation order.
  static String _messageId(int index) => 'm${index.toString().padLeft(5, '0')}';

  static DateTime _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    // Sessions written before the subcollection change stored ISO strings, and
    // a pending server timestamp reads as null on the writer's own snapshot.
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  String _makeTitle(List<ChatMessage> messages) {
    final first = messages.firstWhere((m) => m.role == 'user',
        orElse: () => messages.first);
    final text = first.content.trim().replaceAll('\n', ' ');
    return text.length > 45 ? '${text.substring(0, 45)}…' : text;
  }
}
