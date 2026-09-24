import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/network/dio_client.dart';

import '../models/ai_chat_model.dart';

/// Full-screen Voice-to-Voice Gemini Live Assistant.
///
/// Implements an immersive, dark-themed voice conversation interface
/// inspired by Google Gemini Live. Features radial golden ambient glow,
/// multi-ring pulsating ripples around a signature 76px yellow microphone,
/// real-time streaming transcripts, and voice state management.
class GeminiLiveScreen extends StatefulWidget {
  final String userName;
  final String? initialPrompt;

  const GeminiLiveScreen({
    super.key,
    required this.userName,
    this.initialPrompt,
  });

  @override
  State<GeminiLiveScreen> createState() => _GeminiLiveScreenState();
}

class _GeminiLiveScreenState extends State<GeminiLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _soundWaveController;
  LiveAssistantState _state = LiveAssistantState.listening;

  String _currentTranscript = "";
  String _userSpokenText = "";
  String _lastFullResponse = "";
  Timer? _speechStreamTimer;

  final List<String> _quickVoicePrompts = const [
    "What is my shift timing today?",
    "How many leaves do I have left?",
    "Explain my latest salary slip",
    "Did I punch in on time today?",
    "Who is my reporting manager?",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        _handleVoiceQuery(widget.initialPrompt!);
      } else {
        _startListeningCycle();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _soundWaveController.dispose();
    _speechStreamTimer?.cancel();
    super.dispose();
  }

  /// Starts an ambient listening cycle waiting for voice input.
  void _startListeningCycle() {
    _speechStreamTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _state = LiveAssistantState.listening;
      _currentTranscript =
          "I'm listening. Tap a suggestion below or tap the mic to query...";
      _userSpokenText = "";
    });
  }

  /// Processes a voice query by contacting the Gemini HRMS assistant backend.
  Future<void> _handleVoiceQuery(String query) async {
    _speechStreamTimer?.cancel();

    setState(() {
      _userSpokenText = query;
      _state = LiveAssistantState.thinking;
      _currentTranscript = "Analyzing your HR profile and records...";
    });

    try {
      final response = await DioClient.instance.post(
        '/ai/chat',
        data: {
          'prompt': query,
          'mode': 'live',
        },
      );

      final reply = (response['message'] as String?) ??
          "I have reviewed your request. Everything looks in order.";

      if (!mounted) return;
      _streamAssistantSpeech(reply);
    } catch (_) {
      if (!mounted) return;
      _streamAssistantSpeech(
        "I could not connect to your HR records right now. Please verify your connection.",
      );
    }
  }

  /// Converts an AI response into clean, natural spoken paragraph text
  /// for live voice mode.
  ///
  /// Strips markdown formatting and ensures any bullet points, numbered lists,
  /// or key-value list lines are transformed into flowing, comma-separated
  /// sentences within continuous paragraphs.
  String _toSpeakableText(String raw) {
    var text = raw
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*', dotAll: true),
          (m) => m[1] ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\*(.+?)\*'),
          (m) => m[1] ?? '',
        )
        .replaceAllMapped(
          RegExp(r'`(.+?)`'),
          (m) => m[1] ?? '',
        )
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    final rawLines = text.split('\n');
    final processedParagraphs = <String>[];
    final currentListItems = <String>[];

    void flushList() {
      if (currentListItems.isEmpty) return;
      var joined = currentListItems.join(', ');
      if (!joined.endsWith('.')) {
        joined = '$joined.';
      }
      if (processedParagraphs.isNotEmpty &&
          processedParagraphs.last.trim().endsWith(':')) {
        final lastIntro = processedParagraphs.removeLast().trim();
        processedParagraphs.add('$lastIntro $joined');
      } else {
        processedParagraphs.add(joined);
      }
      currentListItems.clear();
    }

    for (final rawLine in rawLines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushList();
        continue;
      }

      final bulletMatch =
          RegExp(r'^(\*|-|•|\+|>\s*|\d+[.)])\s+(.*)$').firstMatch(line);
      final isKeyValueLine = !line.endsWith(':') &&
          RegExp(r'^[A-Za-z0-9\s/()_-]+:\s*.+$').hasMatch(line);

      if (bulletMatch != null) {
        var item = bulletMatch.group(2)?.trim() ?? '';
        if (item.endsWith('.') || item.endsWith(';') || item.endsWith(',')) {
          item = item.substring(0, item.length - 1).trim();
        }
        if (item.isNotEmpty) {
          currentListItems.add(item);
        }
      } else if (isKeyValueLine &&
          (currentListItems.isNotEmpty ||
              (processedParagraphs.isNotEmpty &&
                  processedParagraphs.last.trim().endsWith(':')))) {
        var item = line;
        if (item.endsWith('.') || item.endsWith(';') || item.endsWith(',')) {
          item = item.substring(0, item.length - 1).trim();
        }
        currentListItems.add(item);
      } else {
        flushList();
        processedParagraphs.add(line);
      }
    }
    flushList();

    return processedParagraphs
        .join('\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  /// Streams the AI assistant's spoken reply word-by-word onto the live screen
  /// mimicking Gemini Live voice streaming.
  void _streamAssistantSpeech(String fullText) {
    final speakable = _toSpeakableText(fullText);
    _lastFullResponse = fullText;
    setState(() {
      _state = LiveAssistantState.speaking;
      _currentTranscript = "";
    });

    final words = speakable.split(' ');
    int wordIndex = 0;

    _speechStreamTimer?.cancel();
    _speechStreamTimer = Timer.periodic(
      const Duration(milliseconds: 140),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (wordIndex < words.length) {
          setState(() {
            _currentTranscript = words.sublist(0, wordIndex + 1).join(' ');
          });
          wordIndex++;
        } else {
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && _state == LiveAssistantState.speaking) {
              setState(() {
                _state = LiveAssistantState.listening;
              });
            }
          });
        }
      },
    );
  }

  /// Toggles pause and resume of the voice interaction.
  void _togglePause() {
    setState(() {
      if (_state == LiveAssistantState.paused) {
        _state = LiveAssistantState.listening;
      } else {
        _state = LiveAssistantState.paused;
        _speechStreamTimer?.cancel();
      }
    });
  }

  /// Handles tap on the primary yellow microphone button.
  /// In speaking state interrupts the current output.
  /// In listening/paused state it acts as a visual cue (real mic input
  /// requires a native plugin — tapping a chip is the current input path).
  void _onMicButtonTapped() {
    if (_state == LiveAssistantState.speaking) {
      _speechStreamTimer?.cancel();
      _startListeningCycle();
    } else if (_state == LiveAssistantState.paused) {
      _startListeningCycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.1),
                  radius: 0.95,
                  colors: [
                    colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                    colorScheme.surfaceContainerLow,
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(colorScheme),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_userSpokenText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_circle,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _userSpokenText,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          _currentTranscript,
                          style: TextStyle(
                            color: _state == LiveAssistantState.speaking
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontSize: size.height < 700 ? 15 : 17,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 12,
                          overflow: TextOverflow.fade,
                        ),
                        const SizedBox(height: 20),
                        _buildStatusIndicator(colorScheme),
                        const SizedBox(height: 24),
                        if (_state == LiveAssistantState.listening)
                          _buildQuickPromptChips(colorScheme),
                      ],
                    ),
                  ),
                ),
                _buildBottomControlDock(colorScheme),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top navigation bar with close button, active status badge, and transcript icon.
  Widget _buildTopBar(M3EColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainer,
            ),
          ),
          _buildLiveStatusBadge(colorScheme),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(
                _userSpokenText.isNotEmpty && _lastFullResponse.isNotEmpty
                    ? LiveSessionResult(
                        prompt: _userSpokenText,
                        response: _lastFullResponse,
                      )
                    : null,
              );
            },
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Centered pill status indicator (Speaking UX / Listening Live).
  Widget _buildLiveStatusBadge(M3EColorScheme colorScheme) {
    final isSpeaking = _state == LiveAssistantState.speaking;
    final isThinking = _state == LiveAssistantState.thinking;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSpeaking) ...[
            AnimatedBuilder(
              animation: _soundWaveController,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (index) {
                    final height = 4.0 +
                        math
                                .sin(
                                  _soundWaveController.value * math.pi +
                                      (index * 0.8),
                                )
                                .abs() *
                            9.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 2.5,
                      height: height,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 7),
            Text(
              'Speaking',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ] else if (isThinking) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Thinking',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Listening Live',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Real-time breathing status pill badge (e.g. "Keep talking...").
  Widget _buildStatusIndicator(M3EColorScheme colorScheme) {
    String text;
    switch (_state) {
      case LiveAssistantState.listening:
        text = "Keep talking...";
        break;
      case LiveAssistantState.thinking:
        text = "Processing your query...";
        break;
      case LiveAssistantState.speaking:
        text = "Gemini is speaking • Tap mic to interrupt";
        break;
      case LiveAssistantState.paused:
        text = "Session paused";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Quick voice prompt pills shown on the live voice screen.
  Widget _buildQuickPromptChips(M3EColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _quickVoicePrompts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              onPressed: () => _handleVoiceQuery(prompt),
              backgroundColor: colorScheme.surfaceContainer,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              avatar: Icon(
                Icons.mic,
                size: 14,
                color: colorScheme.primary,
              ),
              label: Text(
                prompt,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Bottom control dock containing the Pause button,
  /// the signature pulsating Gemini Live microphone, and the Close button.
  Widget _buildBottomControlDock(M3EColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            colorScheme: colorScheme,
            icon: _state == LiveAssistantState.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onPressed: _togglePause,
          ),
          _buildGeminiLiveMicButton(colorScheme),
          _buildCircleButton(
            colorScheme: colorScheme,
            icon: Icons.close_rounded,
            onPressed: () {
              Navigator.of(context).pop(
                _userSpokenText.isNotEmpty && _lastFullResponse.isNotEmpty
                    ? LiveSessionResult(
                        prompt: _userSpokenText,
                        response: _lastFullResponse,
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Helper to build secondary round control buttons (pause, close).
  Widget _buildCircleButton({
    required M3EColorScheme colorScheme,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Icon(icon, color: colorScheme.onSurface, size: 22),
        ),
      ),
    );
  }

  /// Signature large glowing Gemini Live microphone button with multi-ring ripple pulse.
  Widget _buildGeminiLiveMicButton(M3EColorScheme colorScheme) {
    final isActive = _state == LiveAssistantState.listening ||
        _state == LiveAssistantState.speaking;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isActive) ...[
          Container(
            width: 110 + (_pulseController.value * 22),
            height: 110 + (_pulseController.value * 22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(
                  alpha: (1.0 - _pulseController.value) * 0.35,
                ),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 90 + (_pulseController.value * 14),
            height: 90 + (_pulseController.value * 14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(
                alpha: (1.0 - _pulseController.value) * 0.18,
              ),
            ),
          ),
        ],
        GestureDetector(
          onTap: _onMicButtonTapped,
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _state == LiveAssistantState.speaking
                  ? Icons.graphic_eq_rounded
                  : Icons.mic_rounded,
              color: colorScheme.onPrimary,
              size: 34,
            ),
          ),
        ),
      ],
    );
  }
}
