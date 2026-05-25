import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/data/models/chat_session.dart';
import 'package:nightride/data/services/chat_history_service.dart';
import 'package:nightride/data/services/privacy_service.dart';

// ── Chat History ──────────────────────────────────────────────────────────────

final chatHistoryServiceProvider = Provider<ChatHistoryService>(
  (_) => ChatHistoryService(),
);

final chatSessionsProvider = StreamProvider<List<ChatSession>>((ref) {
  return ref.watch(chatHistoryServiceProvider).sessionsStream();
});

// ── Privacy Settings ──────────────────────────────────────────────────────────

final privacyServiceProvider = Provider<PrivacyService>(
  (_) => PrivacyService(),
);

final privacySettingsProvider = StreamProvider<PrivacySettings>((ref) {
  return ref.watch(privacyServiceProvider).stream();
});

// ── Role checks ───────────────────────────────────────────────────────────────
// Read the user's Firestore profile and surface boolean role flags.
// Both default to false if the field is absent or the user is not logged in.

StreamProvider<bool> _userRoleProvider(String field) => StreamProvider<bool>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()?[field] as bool? ?? false);
});

final isAdminProvider = _userRoleProvider('isAdmin');
final isOrganizerProvider = _userRoleProvider('isOrganizer');

// ── Organizer request ─────────────────────────────────────────────────────────
// Streams the status of the current user's organizer application:
// null = no request, 'pending' | 'approved' | 'rejected'

final organizerRequestStatusProvider = StreamProvider<String?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('organizer_requests')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? (snap.data()?['status'] as String?) : null);
});
