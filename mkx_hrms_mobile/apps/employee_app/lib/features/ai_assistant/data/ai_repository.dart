import 'package:mkx_core/network/dio_client.dart';
import '../models/ai_chat_model.dart';

/// Data repository for all AI Smart Assistant API interactions.
///
/// Mirrors the pattern used by [LeavesRepository] and [PayrollRepository].
class AiRepository {
  final DioClient _client = DioClient.instance;

  /// Sends a text prompt to the Gemini-powered assistant endpoint
  /// and returns the AI-generated reply.
  Future<String> chat(String prompt, {List<Map<String, String>>? history}) async {
    final Map<String, dynamic> data = {'prompt': prompt};
    if (history != null && history.isNotEmpty) {
      data['history'] = history;
    }
    
    final response = await _client.post(
      '/ai/chat',
      data: data,
    );

    if (response is Map<String, dynamic>) {
      return response['message']?.toString() ??
          "I'm sorry, I couldn't process that request.";
    }
    throw Exception('Unexpected chat response format');
  }

  /// Fetches the last 50 stored conversation turns for the current employee.
  Future<List<AiChatHistoryEntry>> getHistory() async {
    final response = await _client.get('/ai/history');

    if (response is Map<String, dynamic>) {
      final list = response['history'] as List<dynamic>? ?? [];
      return list
          .map((item) =>
              AiChatHistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Deletes all stored conversation history for the current employee.
  Future<void> clearHistory() async {
    await _client.delete('/ai/history');
  }
}
