/// Represents the voice state of the Gemini Live assistant session.
enum LiveAssistantState {
  listening,
  thinking,
  speaking,
  paused,
}

/// A single message in the AI conversation history.
///
/// [isVoice] is true when the message originated from a Gemini Live session.
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isVoice;
  bool? isLiked;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isVoice = false,
  });
}

/// Data returned by a completed Gemini Live voice session,
/// used to persist the spoken exchange in the chat history.
class LiveSessionResult {
  final String prompt;
  final String response;
  final bool isVoice;

  const LiveSessionResult({
    required this.prompt,
    required this.response,
    this.isVoice = true,
  });
}

/// Raw chat history entry returned from the backend `GET /ai/history`.
class AiChatHistoryEntry {
  final int id;
  final String prompt;
  final String response;
  final DateTime createdAt;

  const AiChatHistoryEntry({
    required this.id,
    required this.prompt,
    required this.response,
    required this.createdAt,
  });

  factory AiChatHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AiChatHistoryEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      prompt: json['prompt']?.toString() ?? '',
      response: json['response']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
