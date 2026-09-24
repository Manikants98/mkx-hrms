import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
    final theme = M3ETheme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(ai, colorScheme),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ai.isFetchingHistory
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.primary,
                      ),
                    )
                  : ai.hasMessages
                      ? _buildMessageList(ai, colorScheme)
                      : _buildPromptStarterHome(firstName, colorScheme),
            ),
            if (ai.isLoading) _buildTypingIndicator(colorScheme),
            _buildInputBar(colorScheme),
          ],
        ),
      ),
    );
  }

  /// App bar with back button, Gemini Live pill, and clear history action.
  PreferredSizeWidget _buildAppBar(AiProvider ai, M3EColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: () => _openGeminiLive(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Gemini Live',
                style: TextStyle(
                  color: colorScheme.primary,
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
            icon: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () async {
              await context.read<AiProvider>().clearHistory();
              if (mounted && context.read<AiProvider>().errorMessage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Chat history cleared'),
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    duration: const Duration(seconds: 2),
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
  Widget _buildPromptStarterHome(String firstName, M3EColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'GO PREMIUM',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Hi, $firstName',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How can I help today?',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm here to help — from quick answers to smart recommendations.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _buildSuggestionGrid(colorScheme),
          const SizedBox(height: 20),
          _buildProBanner(colorScheme),
        ],
      ),
    );
  }

  /// 2×2 grid of HRMS-specific prompt suggestions.
  Widget _buildSuggestionGrid(M3EColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                colorScheme: colorScheme,
                icon: Icons.beach_access_rounded,
                title: 'Leave Balance',
                subtitle: 'Check remaining casual & sick leaves in seconds.',
                prompt: 'What is my current leave balance for this year?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSuggestionCard(
                colorScheme: colorScheme,
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
                colorScheme: colorScheme,
                icon: Icons.receipt_long_rounded,
                title: 'Payslip & Salary',
                subtitle:
                    'Breakdown of your latest salary slip and deductions.',
                prompt:
                    'Can you break down my latest salary slip and net payout?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSuggestionCard(
                colorScheme: colorScheme,
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
    required M3EColorScheme colorScheme,
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
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
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
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
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
  Widget _buildProBanner(M3EColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            'Unlock more features with Pro',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Screen 3 — Scrollable conversation message list.
  Widget _buildMessageList(AiProvider ai, M3EColorScheme colorScheme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: ai.messages.length,
      itemBuilder: (context, index) =>
          _buildMessageItem(ai.messages[index], colorScheme),
    );
  }

  /// Renders a user bubble or AI markdown card (with optional waveform for voice).
  Widget _buildMessageItem(ChatMessage msg, M3EColorScheme colorScheme) {
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
            color: colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.isVoice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 12, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Voice Query',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
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
              AudioWaveformBubble(
                transcript: msg.text,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: _cleanMarkdownText(msg.text),
                    bulletBuilder: (_) => const SizedBox.shrink(),
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                        height: 1.45,
                      ),
                      strong: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 0,
                        height: 0,
                      ),
                      listBulletPadding: EdgeInsets.zero,
                      listIndent: 0,
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
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        onTap: () => setState(
                          () => msg.isLiked = msg.isLiked == true ? null : true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionIcon(
                        icon: msg.isLiked == false
                            ? Icons.thumb_down_rounded
                            : Icons.thumb_down_alt_outlined,
                        color: msg.isLiked == false
                            ? Colors.redAccent
                            : colorScheme.onSurfaceVariant,
                        onTap: () => setState(
                          () =>
                              msg.isLiked = msg.isLiked == false ? null : false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionIcon(
                        icon: Icons.copy_rounded,
                        color: colorScheme.onSurfaceVariant,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: colorScheme.surfaceContainerHigh,
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

  /// Cleans markdown message text to ensure no raw bullet symbols appear.
  String _cleanMarkdownText(String text) {
    return text.replaceAll(RegExp(r'^\s*•\s*', multiLine: true), '');
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
  Widget _buildTypingIndicator(M3EColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Gemini is thinking...',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
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
  Widget _buildInputBar(M3EColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  cursorColor: colorScheme.primary,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Describe your query...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.mic_rounded,
                color: colorScheme.primary,
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
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: colorScheme.onPrimary,
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

/// Dynamic audio waveform player bubble for voice messages.
///
/// Extracted to its own class to keep the screen widget tree focused.
class AudioWaveformBubble extends StatefulWidget {
  final String transcript;
  final M3EColorScheme colorScheme;

  const AudioWaveformBubble({
    super.key,
    required this.transcript,
    required this.colorScheme,
  });

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
    final scheme = widget.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
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
              decoration: BoxDecoration(
                color: scheme.onPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: scheme.primary,
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
                      color: scheme.onPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            '0:14',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
