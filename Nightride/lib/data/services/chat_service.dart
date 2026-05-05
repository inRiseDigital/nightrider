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
  static const String _baseUrl =
      'https://9050-2406-2d40-6173-a008-bc37-814e-145-ab19.ngrok-free.app';

  // ── Streaming ──────────────────────────────────────────────────────────────

  ChatStreamHandle streamMessage(
    String message,
    List<ChatMessage> history, {
    double? latitude,
    double? longitude,
  }) {
    final client = http.Client();
    final stream = _streamImpl(
      client,
      message,
      history,
      latitude: latitude,
      longitude: longitude,
    );
    return ChatStreamHandle(stream, client);
  }

  Stream<Map<String, dynamic>> _streamImpl(
    http.Client client,
    String message,
    List<ChatMessage> history, {
    double? latitude,
    double? longitude,
  }) async* {
    try {
      final body = <String, dynamic>{
        'message': message,
        'history': history.map((m) => m.toJson()).toList(),
      };
      if (latitude != null && longitude != null) {
        body['latitude'] = latitude;
        body['longitude'] = longitude;
      }

      final request =
          http.Request('POST', Uri.parse('$_baseUrl/chat/stream'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        yield {'type': 'error', 'text': 'Server error: ${response.statusCode}'};
        return;
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          try {
            yield jsonDecode(data) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
    } catch (_) {
      // Client closed (cancelled) or network error — just stop yielding.
    }
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  Future<void> sendInteraction(
      String messageId, String type, bool value) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/interaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message_id': messageId,
          'type': type,
          'value': value,
        }),
      );
    } catch (e) {
      // ignore interaction failures
    }
  }
}
