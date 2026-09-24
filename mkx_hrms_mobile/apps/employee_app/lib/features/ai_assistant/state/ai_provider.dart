import 'package:flutter/material.dart';
import '../data/ai_repository.dart';
import '../models/ai_chat_model.dart';

/// State management for the Smart Assistant feature.
///
/// Follows the [ChangeNotifier] pattern established by [LeavesProvider]
/// and [AttendanceProvider]. Owns the message list, loading flags, and
/// all repository interactions so screens stay logic-free.
class AiProvider extends ChangeNotifier {
  final AiRepository _repo = AiRepository();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isFetchingHistory = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardInsights;
  bool _isLoadingInsights = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isFetchingHistory => _isFetchingHistory;
  String? get errorMessage => _errorMessage;
  bool get hasMessages => _messages.isNotEmpty;
  Map<String, dynamic>? get dashboardInsights => _dashboardInsights;
  bool get isLoadingInsights => _isLoadingInsights;

  /// Loads stored conversation history from the server on first open.
  Future<void> loadHistory() async {
    _isFetchingHistory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final entries = await _repo.getHistory();
      _messages.clear();

      for (final entry in entries) {
        if (entry.prompt.isNotEmpty) {
          _messages.add(ChatMessage(text: entry.prompt, isUser: true));
        }
        if (entry.response.isNotEmpty) {
          _messages.add(ChatMessage(text: entry.response, isUser: false));
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFetchingHistory = false;
      notifyListeners();
    }
  }

  /// Sends a text prompt and appends the AI reply to the conversation.
  Future<void> sendMessage(String prompt) async {
    if (prompt.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(text: prompt, isUser: true));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Extract the last 6 messages as context (excluding the prompt we just added)
      final contextMessages = _messages.length > 1 
          ? _messages.sublist(
              _messages.length > 7 ? _messages.length - 7 : 0, 
              _messages.length - 1,
            )
          : <ChatMessage>[];

      final List<Map<String, String>> historyPayload = contextMessages
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'model',
                'text': msg.text,
              })
          .toList();

      final reply = await _repo.chat(prompt, history: historyPayload);
      _messages.add(ChatMessage(text: reply, isUser: false));
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'Unable to connect to the Smart Assistant. Please try again.',
          isUser: false,
        ),
      );
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends a completed Gemini Live voice exchange to the message list.
  void addVoiceSession(LiveSessionResult result) {
    _messages.add(
      ChatMessage(text: result.prompt, isUser: true, isVoice: true),
    );
    _messages.add(
      ChatMessage(text: result.response, isUser: false, isVoice: true),
    );
    notifyListeners();
  }

  /// Clears all messages locally and on the server.
  Future<void> clearHistory() async {
    try {
      await _repo.clearHistory();
      _messages.clear();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Loads AI dashboard insights
  Future<void> loadDashboardInsights() async {
    _isLoadingInsights = true;
    notifyListeners();
    
    try {
      _dashboardInsights = await _repo.getDashboardInsights();
    } catch (_) {} finally {
      _isLoadingInsights = false;
      notifyListeners();
    }
  }
}
