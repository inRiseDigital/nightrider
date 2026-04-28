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
