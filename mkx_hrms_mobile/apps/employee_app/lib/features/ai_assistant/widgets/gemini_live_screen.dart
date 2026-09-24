import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
        data: {'prompt': query},
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

  /// Streams the AI assistant's spoken reply word-by-word onto the live screen
  /// mimicking Gemini Live voice streaming.
  void _streamAssistantSpeech(String fullText) {
    _lastFullResponse = fullText;
    setState(() {
      _state = LiveAssistantState.speaking;
      _currentTranscript = "";
    });

    final words = fullText.split(' ');
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
    // In listening state the mic button has no auto-trigger;
    // the user selects a chip to send a query.
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF111210),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.1),
                  radius: 0.95,
                  colors: [
                    Color(0xFF2B2712),
                    Color(0xFF171815),
                    Color(0xFF0F100E),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
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
                              color: const Color(0xFF242621),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_circle,
                                  size: 16,
                                  color: Color(0xFFE5B034),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _userSpokenText,
                                    style: const TextStyle(
                                      color: Color(0xFFE5E7EB),
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
                                ? Colors.white
                                : const Color(0xFFD1D5DB),
                            fontSize: size.height < 700 ? 20 : 24,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 8,
                          overflow: TextOverflow.fade,
                        ),
                        const SizedBox(height: 20),
                        _buildStatusIndicator(),
                        const SizedBox(height: 24),
                        if (_state == LiveAssistantState.listening)
                          _buildQuickPromptChips(),
                      ],
                    ),
                  ),
                ),
                _buildBottomControlDock(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top navigation bar with close button, active status badge, and transcript icon.
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E201B),
            ),
          ),
          _buildLiveStatusBadge(),
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
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white70,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E201B),
            ),
          ),
        ],
      ),
    );
  }

  /// Centered pill status indicator (Speaking UX / Listening Live).
  Widget _buildLiveStatusBadge() {
    final isSpeaking = _state == LiveAssistantState.speaking;
    final isThinking = _state == LiveAssistantState.thinking;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C242),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5C242).withValues(alpha: 0.35),
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
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 7),
            const Text(
              'Speaking',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ] else if (isThinking) ...[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Thinking',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Listening Live',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Real-time breathing status text (e.g. "Keep talking...").
  Widget _buildStatusIndicator() {
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

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF5C242),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5C242).withValues(alpha: 0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Quick voice prompt pills shown on the live voice screen.
  Widget _buildQuickPromptChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _quickVoicePrompts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              onPressed: () => _handleVoiceQuery(prompt),
              backgroundColor: const Color(0xFF1E201B),
              side: const BorderSide(color: Color(0xFF32342D)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              avatar: const Icon(
                Icons.mic,
                size: 14,
                color: Color(0xFFF5C242),
              ),
              label: Text(
                prompt,
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
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
  /// the signature pulsating Gemini Live yellow microphone, and the Close button.
  Widget _buildBottomControlDock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            icon: _state == LiveAssistantState.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onPressed: _togglePause,
          ),
          _buildGeminiLiveMicButton(),
          _buildCircleButton(
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
            color: const Color(0xFF1E201B),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF33352E),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  /// Signature large glowing yellow Gemini Live microphone button with multi-ring ripple pulse.
  Widget _buildGeminiLiveMicButton() {
    final isActive = _state == LiveAssistantState.listening ||
        _state == LiveAssistantState.speaking;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
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
                    color: const Color(0xFFF5C242).withValues(
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
                  color: const Color(0xFFF5C242).withValues(
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
                  color: const Color(0xFFF5C242),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5C242).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _state == LiveAssistantState.speaking
                      ? Icons.graphic_eq_rounded
                      : Icons.mic_rounded,
                  color: const Color(0xFF131411),
                  size: 34,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
