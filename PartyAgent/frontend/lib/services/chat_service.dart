import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatService {
  // Replace with your local IP if testing on a physical device
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Default for Android Emulator

  Future<Map<String, dynamic>> sendMessage(
    String message, 
    List<ChatMessage> history, 
    {double? latitude, double? longitude}
  ) async {
    try {
      final body = {
        'message': message,
        'history': history.map((m) => m.toJson()).toList(),
      };
      
      // Add location if provided
      if (latitude != null && longitude != null) {
        body['latitude'] = latitude;
        body['longitude'] = longitude;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['response'] as String;
        // String leading/trailing quotes if LLM added them
        text = text.trim();
        if (text.startsWith('"') && text.endsWith('"')) {
          text = text.substring(1, text.length - 1);
        }
        
        // Extract suggestions
        List<String> suggestions = [];
        if (data['suggestions'] != null) {
          suggestions = List<String>.from(data['suggestions']);
        }
        
        return {
          'response': text.trim(),
          'suggestions': suggestions,
        };
      } else {
        throw Exception('Failed to connect to agent: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'response': "I'm having trouble connecting to the server. Please make sure the backend is running.",
        'suggestions': <String>[],
      };
    }
  }

  Future<void> sendInteraction(String messageId, String type, bool value) async {
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
      print('Failed to send interaction: $e');
    }
  }
}
