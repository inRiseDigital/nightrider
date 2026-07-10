import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// Handle returned by [ChatService.streamMessage].
/// Call [cancel] to abort the in-flight request.
class ChatStreamHandle {
  final Stream<Map<String, dynamic>> events;
  final http.Client _client;

  ChatStreamHandle(this.events, this._client);

  void cancel() => _client.close();
}

class ChatService {
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://5r5cqck5-8010.asse.devtunnels.ms',
  );

  static const String _apiKey = String.fromEnvironment('APP_API_KEY');

  ChatStreamHandle streamMessage(
    String message,
    List<ChatMessage> history, {
    double? latitude,
    double? longitude,
    String? userId,
    String? threadId,
  }) {
    final client = http.Client();
    final stream = _streamImpl(
      client,
      message,
      latitude: latitude,
      longitude: longitude,
      userId: userId,
      threadId: threadId,
    );
    return ChatStreamHandle(stream, client);
  }

  Stream<Map<String, dynamic>> _streamImpl(
    http.Client client,
    String message, {
    double? latitude,
    double? longitude,
    String? userId,
    String? threadId,
  }) async* {
    try {
      final body = <String, dynamic>{
        'message': message,
        'user_id': userId ?? 'anonymous',
        if (threadId != null) 'thread_id': threadId,
        'history': [],
        if (latitude != null && longitude != null) 'latitude': latitude,
        if (latitude != null && longitude != null) 'longitude': longitude,
      };

      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/stream'));
      request.headers['Content-Type'] = 'application/json';
      if (_apiKey.isNotEmpty) request.headers['X-API-Key'] = _apiKey;
      request.body = jsonEncode(body);

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        yield {'type': 'error', 'text': 'Server error: ${streamedResponse.statusCode}'};
        return;
      }

      // Parse SSE: each event is separated by \n\n, lines start with "data: "
      String leftover = '';
      await for (final bytes in streamedResponse.stream) {
        final chunk = leftover + utf8.decode(bytes);
        final parts = chunk.split('\n\n');
        leftover = parts.removeLast(); // may be an incomplete event
        for (final part in parts) {
          for (final line in part.split('\n')) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('data: ')) continue;
            final data = trimmed.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              yield jsonDecode(data) as Map<String, dynamic>;
            } catch (_) {}
          }
        }
      }
    } catch (_) {
      yield {'type': 'error', 'text': 'Network error'};
    }
  }
}
