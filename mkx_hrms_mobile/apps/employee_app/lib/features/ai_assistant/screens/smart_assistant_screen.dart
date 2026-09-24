import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:provider/provider.dart';

import '../models/ai_chat_model.dart';
import '../state/ai_provider.dart';
import '../widgets/gemini_live_screen.dart';

/// Smart Assistant Screen — AI-powered HR concierge inspired by Google Gemini.
///
/// Implements a 3-stage interface:
/// 1. Prompt Starters home screen with suggestion cards and greeting.
/// 2. Full-screen Gemini Live Voice-to-Voice assistant.
/// 3. Conversation view with waveform bubbles, markdown, and reactions.
class SmartAssistantScreen extends StatefulWidget {
  const SmartAssistantScreen({super.key});

  @override
  State<SmartAssistantScreen> createState() => _SmartAssistantScreenState();
}

class _SmartAssistantScreenState extends State<SmartAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Smoothly scrolls the message list to the bottom after the next frame.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Submits a text message via [AiProvider] and scrolls to the reply.
  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty) return;
    if (presetText == null) _inputController.clear();

    await context.read<AiProvider>().sendMessage(text);
    _scrollToBottom();
  }

  /// Opens the Gemini Live voice screen and persists the session result.
  Future<void> _openGeminiLive([String? initialPrompt]) async {
    final auth = context.read<AuthProvider>();
    final userName = auth.currentUser?.name ?? 'Employee';

    final result = await Navigator.of(context).push<LiveSessionResult?>(
      MaterialPageRoute(
        builder: (context) => GeminiLiveScreen(
          userName: userName,
          initialPrompt: initialPrompt,
        ),
      ),
    );

    if (result != null && mounted) {
      context.read<AiProvider>().addVoiceSession(result);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.currentUser?.name ?? 'Employee').split(' ').first;
    final ai = context.watch<AiProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF111210),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(ai),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ai.isFetchingHistory
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFF5C242),
                      ),
                    )
                  : ai.hasMessages
                      ? _buildMessageList(ai)
                      : _buildPromptStarterHome(firstName),
            ),
            if (ai.isLoading) _buildTypingIndicator(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  /// App bar with back button, Gemini Live pill, and clear history action.
  PreferredSizeWidget _buildAppBar(AiProvider ai) {
    return AppBar(
      backgroundColor: const Color(0xFF111210),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: () => _openGeminiLive(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E201B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF5C242).withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, size: 14, color: Color(0xFFF5C242)),
              SizedBox(width: 6),
              Text(
                'Gemini Live',
                style: TextStyle(
                  color: Color(0xFFF5C242),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        if (ai.hasMessages)
          IconButton(
            tooltip: 'Clear Conversation',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white54,
              size: 20,
            ),
            onPressed: () async {
              await context.read<AiProvider>().clearHistory();
              if (mounted && context.read<AiProvider>().errorMessage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat history cleared'),
                    backgroundColor: Color(0xFF242621),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Screen 1 — Home with personalised greeting and 2×2 suggestion cards.
  Widget _buildPromptStarterHome(String firstName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E201B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF5C242).withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'GO PREMIUM',
                  style: TextStyle(
                    color: Color(0xFFF5C242),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF242621),
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E',
                  style: const TextStyle(
                    color: Color(0xFFF5C242),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Hi, $firstName',
            style: const TextStyle(
              color: Color(0xFFF5C242),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'How can I help today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "I'm here to help — from quick answers to smart recommendations.",
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _buildSuggestionGrid(),
          const SizedBox(height: 20),
          _buildProBanner(),
        ],
      ),
    );
  }

  /// 2×2 grid of HRMS-specific prompt suggestions.
  Widget _buildSuggestionGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.beach_access_rounded,
                title: 'Leave Balance',
                subtitle: 'Check remaining casual & sick leaves in seconds.',
                prompt: 'What is my current leave balance for this year?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.schedule_rounded,
                title: 'Shift & Timing',
                subtitle: 'View your scheduled shift hours and timing details.',
                prompt: 'What is my shift schedule and working hours today?',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.receipt_long_rounded,
                title: 'Payslip & Salary',
                subtitle: 'Breakdown of your latest salary slip and deductions.',
                prompt: 'Can you break down my latest salary slip and net payout?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.fingerprint_rounded,
                title: 'Attendance Log',
                subtitle: 'Review monthly attendance logs and punch history.',
                prompt: 'Show me my recent attendance logs and punch records.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Individual tappable suggestion card.
  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String prompt,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendMessage(prompt),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1C1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E302A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFFF5C242)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF888B84),
                  fontSize: 11,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pro upgrade promotional banner.
  Widget _buildProBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2D27)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: Color(0xFFF5C242)),
          SizedBox(width: 10),
          Text(
            'Unlock more features with Pro',
            style: TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Screen 3 — Scrollable conversation message list.
  Widget _buildMessageList(AiProvider ai) {
    _scrollToBottom();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: ai.messages.length,
      itemBuilder: (context, index) =>
          _buildMessageItem(ai.messages[index]),
    );
  }

  /// Renders a user bubble or AI markdown card (with optional waveform for voice).
  Widget _buildMessageItem(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF242621),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: const Color(0xFF353830)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.isVoice)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 12, color: Color(0xFFF5C242)),
                      SizedBox(width: 4),
                      Text(
                        'Voice Query',
                        style: TextStyle(
                          color: Color(0xFFF5C242),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isVoice) ...[
              AudioWaveformBubble(transcript: msg.text),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1C1A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: const Color(0xFF2D2F28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE5E7EB),
                        height: 1.45,
                      ),
                      strong: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5C242),
                      ),
                      listBullet: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF5C242),
                      ),
                      blockSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildReactionIcon(
                        icon: msg.isLiked == true
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_alt_outlined,
                        color: msg.isLiked == true
                            ? const Color(0xFFF5C242)
                            : Colors.white38,
                        onTap: () => setState(
                          () => msg.isLiked =
                              msg.isLiked == true ? null : true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionIcon(
                        icon: msg.isLiked == false
                            ? Icons.thumb_down_rounded
                            : Icons.thumb_down_alt_outlined,
                        color: msg.isLiked == false
                            ? Colors.redAccent
                            : Colors.white38,
                        onTap: () => setState(
                          () => msg.isLiked =
                              msg.isLiked == false ? null : false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionIcon(
                        icon: Icons.copy_rounded,
                        color: Colors.white38,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Color(0xFF242621),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for message reaction buttons (like / dislike / copy).
  Widget _buildReactionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  /// Animated "Gemini is thinking…" indicator shown while awaiting a reply.
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1C1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E3029)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF5C242),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Gemini is thinking...',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom input dock with text field, voice mic, and send button.
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF111210),
        border: Border(
          top: BorderSide(color: Color(0xFF242621), width: 1),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1C1A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF2E3029)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.attach_file_rounded,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Describe your query...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.mic_rounded,
                color: Color(0xFFF5C242),
                size: 22,
              ),
              tooltip: 'Gemini Live Voice Mode',
              onPressed: () => _openGeminiLive(),
            ),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5C242),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Color(0xFF111210),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Golden audio waveform player bubble for voice messages.
///
/// Extracted to its own class to keep the screen widget tree focused.
class AudioWaveformBubble extends StatefulWidget {
  final String transcript;

  const AudioWaveformBubble({super.key, required this.transcript});

  @override
  State<AudioWaveformBubble> createState() => _AudioWaveformBubbleState();
}

class _AudioWaveformBubbleState extends State<AudioWaveformBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  late final List<double> _waveformHeights;
  bool _isPlaying = false;
  static const int _barCount = 28;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final rng = math.Random(widget.transcript.hashCode);
    _waveformHeights = List.generate(
      _barCount,
      (_) => 4.0 + (rng.nextDouble() * 18.0),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// Toggles waveform animation playback.
  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C242),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5C242).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF131411),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFFF5C242),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Row(
                children: List.generate(_barCount, (index) {
                  final base = _waveformHeights[index];
                  final dynH = _isPlaying
                      ? (base +
                              math.sin(
                                    (_waveController.value * math.pi * 2) +
                                        (index * 0.4),
                                  ) *
                                  6.0)
                          .clamp(3.0, 24.0)
                      : base;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.2),
                    width: 2.5,
                    height: dynH,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131411),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 10),
          const Text(
            '0:14',
            style: TextStyle(
              color: Color(0xFF131411),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
