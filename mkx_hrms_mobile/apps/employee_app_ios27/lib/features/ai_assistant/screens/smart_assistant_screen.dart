import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_glass_surface.dart';
import '../models/ai_chat_model.dart';
import '../state/ai_provider.dart';
import '../widgets/gemini_live_screen.dart';

class AssistantTheme {
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color surfaceContainerHighest;
  final Color surfaceContainerHigh;
  final Color outlineVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color error;

  const AssistantTheme({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.surfaceContainerHighest,
    required this.surfaceContainerHigh,
    required this.outlineVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.error,
  });
}

/// Smart Assistant Screen — AI-powered HR concierge conforming to the MKX HRMS design system.
///
/// Implements a 3-stage interface:
/// 1. Prompt Starters home screen with greeting, live voice mode banner, and suggestion cards.
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
  int _lastMessageCount = 0;

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

  /// Smoothly scrolls or jumps the message list to the latest message.
  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0.0);
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
      CupertinoPageRoute(
        builder: (context) => SmartAssistantLiveScreen(
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
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final primary = CupertinoTheme.of(context).primaryColor;

    final theme = AssistantTheme(
      primary: primary,
      onPrimary: CupertinoColors.white,
      surface: isDark ? const Color(0xFF10121A) : const Color(0xFFF2F2F7),
      surfaceContainerHighest:
          isDark ? const Color(0xFF1E2230) : const Color(0xFFE5E5EA),
      surfaceContainerHigh:
          isDark ? const Color(0xFF282D3F) : const Color(0xFFDCDCE2),
      outlineVariant:
          isDark ? const Color(0xFF2E3346) : const Color(0xFFC7C7CC),
      onSurface: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
      onSurfaceVariant:
          isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
      error: const Color(0xFFFF3B30),
    );

    if (!ai.hasMessages) {
      _lastMessageCount = 0;
    } else if (ai.messages.length != _lastMessageCount) {
      _lastMessageCount = ai.messages.length;
      _scrollToBottom(animate: true);
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      resizeToAvoidBottomInset: true,
      child: Ios27Background(
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              _buildLiquidHeader(ai, theme, isDark),
              Expanded(
                child: ai.isFetchingHistory
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 12),
                      )
                    : ai.hasMessages
                        ? _buildMessageList(ai, theme, isDark)
                        : _buildPromptStarterHome(firstName, theme, isDark),
              ),
              if (ai.isLoading) _buildTypingIndicator(theme),
              _buildInputBar(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// Liquid header with navigation, live voice shortcut, and clear history action.
  Widget _buildLiquidHeader(
      AiProvider ai, AssistantTheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icon(
              CupertinoIcons.chevron_left,
              color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Smart Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Connected • HR Concierge',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.6)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icon(
              CupertinoIcons.mic_fill,
              color: theme.primary,
              size: 20,
            ),
            onPressed: () => _openGeminiLive(),
          ),
          if (ai.hasMessages) ...[
            const SizedBox(width: 8),
            GlassIconButton(
              icon: Icon(
                CupertinoIcons.trash,
                size: 18,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.70)
                    : const Color(0xFF6C6C70),
              ),
              onPressed: () async {
                await context.read<AiProvider>().clearHistory();
                if (mounted &&
                    context.read<AiProvider>().errorMessage == null) {
                  UiHelpers.showSnackBar(context, 'Chat history cleared');
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Screen 1 — Home with personalised greeting, live voice banner, and 2x2 suggestion cards.
  Widget _buildPromptStarterHome(
    String firstName,
    AssistantTheme theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, $firstName',
            style: TextStyle(
              color: theme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How can I help today?',
            style: TextStyle(
              color: theme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm here to help — from quick answers to smart recommendations about your work and HR benefits.",
            style: TextStyle(
              color: theme.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildLiveVoiceBanner(theme, isDark),
          const SizedBox(height: 20),
          Text(
            'Quick Suggestions',
            style: TextStyle(
              color: theme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildSuggestionGrid(theme, isDark),
        ],
      ),
    );
  }

  /// Interactive banner promoting hands-free Gemini Live voice interaction.
  Widget _buildLiveVoiceBanner(AssistantTheme theme, bool isDark) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => _openGeminiLive(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.mic_fill,
                color: theme.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Live Voice Mode',
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(
                            alpha: isDark ? 0.25 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'VOICE AI',
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Speak hands-free with real-time AI voice conversation',
                    style: TextStyle(
                      color: theme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: theme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// 2x2 grid of HRMS-specific prompt suggestions.
  Widget _buildSuggestionGrid(AssistantTheme theme, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                theme: theme,
                isDark: isDark,
                icon: CupertinoIcons.umbrella_fill,
                title: 'Leave Balance',
                subtitle: 'Check remaining casual & sick leaves in seconds.',
                prompt: 'What is my current leave balance for this year?',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSuggestionCard(
                theme: theme,
                isDark: isDark,
                icon: CupertinoIcons.clock_fill,
                title: 'Shift & Timing',
                subtitle: 'View your scheduled shift hours and timing details.',
                prompt: 'What is my shift schedule and working hours today?',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                theme: theme,
                isDark: isDark,
                icon: CupertinoIcons.doc_text_fill,
                title: 'Payslip & Salary',
                subtitle:
                    'Breakdown of your latest salary slip and deductions.',
                prompt:
                    'Can you break down my latest salary slip and net payout?',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSuggestionCard(
                theme: theme,
                isDark: isDark,
                icon: CupertinoIcons.waveform_path_ecg,
                title: 'Attendance Log',
                subtitle: 'Review monthly attendance logs and punch history.',
                prompt: 'Show me my recent attendance logs and punch records.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                theme: theme,
                isDark: isDark,
                icon: CupertinoIcons.doc_plaintext,
                title: 'Company Policies',
                subtitle: 'Ask about HR policies, benefits, and holidays.',
                prompt:
                    'What are the company policies regarding remote work and holidays?',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSuggestionCard(
                theme: theme,
                isDark: isDark,
                icon: CupertinoIcons.gift_fill,
                title: 'Celebrations',
                subtitle: 'View upcoming birthdays and anniversaries.',
                prompt:
                    'Are there any upcoming birthdays or work anniversaries in my team this month?',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required AssistantTheme theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String prompt,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => _sendMessage(prompt),
      child: Container(
        height: 136,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.primary.withValues(
                  alpha: isDark ? 0.20 : 0.08,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  color: theme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen 3 — Scrollable conversation message list (anchored to latest messages).
  Widget _buildMessageList(
    AiProvider ai,
    AssistantTheme theme,
    bool isDark,
  ) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      itemCount: ai.messages.length,
      itemBuilder: (BuildContext context, int index) {
        final ChatMessage message =
            ai.messages[ai.messages.length - 1 - index];
        return _buildMessageItem(message, theme, isDark);
      },
    );
  }

  /// Renders a user bubble or AI markdown card conforming to MKX HRMS design.
  Widget _buildMessageItem(
    ChatMessage msg,
    AssistantTheme theme,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.80,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                      Icon(CupertinoIcons.mic_fill,
                          size: 12, color: theme.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Voice Query',
                        style: TextStyle(
                          color: theme.onPrimary,
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
                  color: theme.onPrimary,
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
          maxWidth: screenWidth * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isVoice) ...[
              AudioWaveformBubble(
                transcript: msg.text,
                theme: theme,
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                border: Border.all(
                  color: theme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
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
                        color: theme.onSurface,
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.primary,
                      ),
                      code: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: theme.onSurface,
                        backgroundColor: theme.surfaceContainerHigh,
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
                            ? CupertinoIcons.hand_thumbsup_fill
                            : CupertinoIcons.hand_thumbsup,
                        color: msg.isLiked == true
                            ? theme.primary
                            : theme.onSurfaceVariant,
                        onTap: () => setState(
                          () => msg.isLiked =
                              msg.isLiked == true ? null : true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionIcon(
                        icon: msg.isLiked == false
                            ? CupertinoIcons.hand_thumbsdown_fill
                            : CupertinoIcons.hand_thumbsdown,
                        color: msg.isLiked == false
                            ? theme.error
                            : theme.onSurfaceVariant,
                        onTap: () => setState(
                          () => msg.isLiked =
                              msg.isLiked == false ? null : false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReactionIcon(
                        icon: CupertinoIcons.doc_on_doc,
                        color: theme.onSurfaceVariant,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          UiHelpers.showSnackBar(
                              context, 'Copied to clipboard');
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  /// Animated typing indicator with standard circular spinner.
  Widget _buildTypingIndicator(AssistantTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CupertinoActivityIndicator(radius: 6),
              ),
              const SizedBox(width: 8),
              Text(
                'Assistant is thinking...',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.onSurfaceVariant,
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
  Widget _buildInputBar(AssistantTheme theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(
        left: 14,
        right: 14,
        top: 6,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 6, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.08)
              : CupertinoColors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.16)
                : CupertinoColors.white.withValues(alpha: 0.65),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _inputController,
                placeholder: 'Ask Smart Assistant anything...',
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
                ),
                placeholderStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.5)
                      : const Color(0xFF8E8E93),
                ),
                decoration: const BoxDecoration(
                  color: CupertinoColors.transparent,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => _openGeminiLive(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.mic_fill,
                  size: 20,
                  color: theme.primary,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: _sendMessage,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  color: CupertinoColors.white,
                  size: 19,
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
  final AssistantTheme theme;

  const AudioWaveformBubble({
    super.key,
    required this.transcript,
    required this.theme,
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
    final scheme = widget.theme;

    return Container(
      padding: const EdgeInsets.all(8),
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
                _isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                color: scheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 24,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
