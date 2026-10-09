import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mkx_core/network/dio_client.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/ai_chat_model.dart';

class _LiveTheme {
  final Color surface;
  final Color surfaceContainerLow;
  final Color surfaceContainerHighest;
  final Color outlineVariant;
  final Color primary;
  final Color onPrimary;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _LiveTheme({
    required this.surface,
    required this.surfaceContainerLow,
    required this.surfaceContainerHighest,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.onSurface,
    required this.onSurfaceVariant,
  });
}

/// Full-screen Voice-to-Voice Smart Assistant Live Assistant.
///
/// Implements an immersive, dark-themed voice conversation interface
/// inspired by Google Smart Assistant Live. Features radial golden ambient glow,
/// multi-ring pulsating ripples around a signature 76px yellow microphone,
/// real-time streaming transcripts, and voice state management.
class SmartAssistantLiveScreen extends StatefulWidget {
  final String userName;
  final String? initialPrompt;

  const SmartAssistantLiveScreen({
    super.key,
    required this.userName,
    this.initialPrompt,
  });

  @override
  State<SmartAssistantLiveScreen> createState() =>
      _SmartAssistantLiveScreenState();
}

class _SmartAssistantLiveScreenState extends State<SmartAssistantLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _soundWaveController;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  LiveAssistantState _state = LiveAssistantState.listening;
  bool _speechEnabled = false;
  bool _ttsInitialized = false;

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
      _initVoiceEngines();
    });
  }

  /// Initializes Text-To-Speech and Speech-To-Text engines.
  Future<void> _initVoiceEngines() async {
    await _initTts();
    await _initSpeech();
    if (mounted) {
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        _handleVoiceQuery(widget.initialPrompt!);
      } else {
        _startListeningCycle();
      }
    }
  }

  /// Sets up the Text-To-Speech engine.
  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (mounted && _state == LiveAssistantState.speaking) {
          _startListeningCycle();
        }
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        if (mounted && _state == LiveAssistantState.speaking) {
          _startListeningCycle();
        }
      });

      _ttsInitialized = true;
    } catch (_) {
      _ttsInitialized = false;
    }
  }

  /// Sets up Speech-To-Text microphone engine and requests permissions.
  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          if (mounted && _state == LiveAssistantState.listening) {
            setState(() {});
          }
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted && _state == LiveAssistantState.listening) {
              setState(() {});
            }
          }
        },
      );
    } catch (_) {
      _speechEnabled = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _soundWaveController.dispose();
    _speechStreamTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

  /// Starts listening for real user speech via microphone.
  Future<void> _startListeningCycle() async {
    _speechStreamTimer?.cancel();
    try {
      await _flutterTts.stop();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _state = LiveAssistantState.listening;
      _userSpokenText = "";
      _currentTranscript = _speechEnabled
          ? "I'm listening. Speak your query..."
          : "Tap the mic to grant permission or tap a suggestion below...";
    });

    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize();
      if (!_speechEnabled) return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_IN',
        ),
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  /// Receives speech recognition results and automatically submits queries.
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _userSpokenText = result.recognizedWords;
      if (result.recognizedWords.isNotEmpty) {
        _currentTranscript = result.recognizedWords;
      }
    });

    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      _speechToText.stop();
      _handleVoiceQuery(result.recognizedWords.trim());
    }
  }

  /// Processes a voice query by contacting the Smart Assistant HRMS assistant backend.
  Future<void> _handleVoiceQuery(String query) async {
    _speechStreamTimer?.cancel();
    try {
      await _speechToText.stop();
      await _flutterTts.stop();
    } catch (_) {}

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
        .replaceAll(RegExp(r'#{1,6}\s*'), '');

    final lines = text.split('\n');
    final processedLines = <String>[];
    final currentListItems = <String>[];

    void flushList() {
      if (currentListItems.isEmpty) return;
      if (currentListItems.length == 1) {
        processedLines.add(currentListItems.first);
      } else {
        final last = currentListItems.removeLast();
        final joined = '${currentListItems.join(', ')}, and $last.';
        processedLines.add(joined);
      }
      currentListItems.clear();
    }

    final bulletPattern = RegExp(r'^\s*[-*•]\s+(.+)$');
    final numberedPattern = RegExp(r'^\s*\d+[\.\)]\s+(.+)$');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flushList();
        continue;
      }

      final bulletMatch = bulletPattern.firstMatch(trimmed);
      final numberedMatch = numberedPattern.firstMatch(trimmed);

      if (bulletMatch != null) {
        var item = bulletMatch.group(1)!.trim();
        item = item.replaceFirst(RegExp(r':\s*'), ' is ');
        item = item.replaceAll(RegExp(r'[\.;]$'), '');
        currentListItems.add(item);
      } else if (numberedMatch != null) {
        var item = numberedMatch.group(1)!.trim();
        item = item.replaceFirst(RegExp(r':\s*'), ' is ');
        item = item.replaceAll(RegExp(r'[\.;]$'), '');
        currentListItems.add(item);
      } else {
        flushList();
        var normalLine = trimmed.replaceAllMapped(
          RegExp(r'^([A-Za-z0-9 ]+):\s+'),
          (m) => '${m[1]} is ',
        );
        processedLines.add(normalLine);
      }
    }
    flushList();

    final joined = processedLines.join(' ');
    return joined
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\s+([,\.!?;:])'), r'$1')
        .replaceAll(RegExp(r'([,\.!?;:])([A-Za-z])'), r'$1 $2')
        .replaceAll('..', '.')
        .replaceAll(',,', ',')
        .trim();
  }

  /// Streams the TTS audio output and types out text progressively.
  Future<void> _streamAssistantSpeech(String fullText) async {
    _lastFullResponse = fullText;
    final speakable = _toSpeakableText(fullText);

    setState(() {
      _state = LiveAssistantState.speaking;
      _currentTranscript = "";
    });

    final words = fullText.split(' ');
    int wordIndex = 0;
    _speechStreamTimer?.cancel();

    _speechStreamTimer =
        Timer.periodic(const Duration(milliseconds: 65), (timer) {
      if (wordIndex < words.length) {
        if (mounted) {
          setState(() {
            _currentTranscript =
                "${words.sublist(0, wordIndex + 1).join(' ')} ▋";
          });
        }
        wordIndex++;
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _currentTranscript = fullText;
          });
        }
      }
    });

    if (_ttsInitialized) {
      try {
        await _flutterTts.speak(speakable);
      } catch (_) {
        await Future<void>.delayed(
          Duration(milliseconds: words.length * 68 + 800),
        );
        if (mounted && _state == LiveAssistantState.speaking) {
          _startListeningCycle();
        }
      }
    } else {
      await Future<void>.delayed(
        Duration(milliseconds: words.length * 68 + 800),
      );
      if (mounted && _state == LiveAssistantState.speaking) {
        _startListeningCycle();
      }
    }
  }

  /// Toggles pause/resume state.
  void _togglePause() {
    if (_state == LiveAssistantState.paused) {
      _startListeningCycle();
    } else {
      _speechStreamTimer?.cancel();
      _speechToText.stop();
      _flutterTts.stop();
      setState(() {
        _state = LiveAssistantState.paused;
        _currentTranscript = "Paused. Tap the mic or play to resume.";
      });
    }
  }

  /// Handles main microphone button interaction.
  void _onMicButtonTapped() {
    if (_state == LiveAssistantState.listening) {
      if (_speechToText.isListening) {
        _speechToText.stop();
        if (_userSpokenText.trim().isNotEmpty) {
          _handleVoiceQuery(_userSpokenText.trim());
        }
      } else {
        _startListeningCycle();
      }
    } else if (_state == LiveAssistantState.speaking) {
      _speechStreamTimer?.cancel();
      _flutterTts.stop();
      _startListeningCycle();
    } else {
      _startListeningCycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final colors = _LiveTheme(
      surface: isDark ? const Color(0xFF10121A) : const Color(0xFFF2F2F7),
      surfaceContainerLow:
          isDark ? const Color(0xFF161922) : const Color(0xFFE5E5EA),
      surfaceContainerHighest:
          isDark ? const Color(0xFF1E2230) : const Color(0xFFDCDCE2),
      outlineVariant:
          isDark ? const Color(0xFF2E3346) : const Color(0xFFC7C7CC),
      primary: const Color(0xFFFFD60A),
      onPrimary: const Color(0xFF000000),
      onSurface: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
      onSurfaceVariant:
          isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
    );
    final size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      backgroundColor: colors.surface,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.1),
                  radius: 0.95,
                  colors: [
                    colors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                    colors.surfaceContainerLow,
                    colors.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(colors),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_userSpokenText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.outlineVariant
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.person_crop_circle,
                                  size: 16,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _userSpokenText,
                                    style: TextStyle(
                                      color: colors.onSurface,
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _state == LiveAssistantState.speaking
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                            fontSize: size.height < 700 ? 15 : 17,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 12,
                          overflow: TextOverflow.fade,
                        ),
                        const SizedBox(height: 20),
                        _buildStatusIndicator(colors),
                        const SizedBox(height: 24),
                        if (_state == LiveAssistantState.listening)
                          _buildQuickPromptChips(colors),
                      ],
                    ),
                  ),
                ),
                _buildBottomControlDock(colors),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top navigation bar with close button, active status badge, and transcript icon.
  Widget _buildTopBar(_LiveTheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(CupertinoIcons.chevron_back,
                  color: colors.onSurface, size: 20),
            ),
          ),
          _buildLiveStatusBadge(colors),
          CupertinoButton(
            padding: EdgeInsets.zero,
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
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                CupertinoIcons.chat_bubble_2,
                color: colors.onSurface,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Centered pill status indicator (Speaking UX / Listening Live).
  Widget _buildLiveStatusBadge(_LiveTheme colors) {
    final isSpeaking = _state == LiveAssistantState.speaking;
    final isThinking = _state == LiveAssistantState.thinking;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSpeaking) ...[
            SizedBox(
              height: 14,
              child: AnimatedBuilder(
                animation: _soundWaveController,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final height = 4.0 +
                          math
                                  .sin(
                                    _soundWaveController.value * math.pi +
                                        (index * 0.8),
                                  )
                                  .abs() *
                              8.0;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 2.5,
                        height: height,
                        decoration: BoxDecoration(
                          color: colors.onPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Speaking',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ] else if (isThinking) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CupertinoActivityIndicator(radius: 6),
            ),
            const SizedBox(width: 7),
            Text(
              'Thinking',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: colors.onPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Listening Live',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Real-time breathing status pill badge (e.g. "Listening to your voice...").
  Widget _buildStatusIndicator(_LiveTheme colors) {
    String text;
    switch (_state) {
      case LiveAssistantState.listening:
        text = _speechToText.isListening
            ? "Listening to your voice..."
            : _speechEnabled
                ? "Tap mic to speak"
                : "Microphone permission needed";
        break;
      case LiveAssistantState.thinking:
        text = "Processing...";
        break;
      case LiveAssistantState.speaking:
        text = "Assistant is speaking...";
        break;
      case LiveAssistantState.paused:
        text = "Session paused";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Quick voice prompt pills shown on the live voice screen.
  Widget _buildQuickPromptChips(_LiveTheme colors) {
    final double chipWidth =
        (MediaQuery.of(context).size.width - 32 - 8) / 2;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _quickVoicePrompts.map((prompt) {
        return SizedBox(
          width: chipWidth,
          child: GestureDetector(
            onTap: () => _handleVoiceQuery(prompt),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.mic_fill,
                    size: 13,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Bottom control dock containing the Pause button,
  /// the signature pulsating Smart Assistant Live microphone, and the Close button.
  Widget _buildBottomControlDock(_LiveTheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: SizedBox(
        height: 84,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCircleButton(
              colors: colors,
              icon: _state == LiveAssistantState.paused
                  ? CupertinoIcons.play_fill
                  : CupertinoIcons.pause_fill,
              onPressed: _togglePause,
            ),
            _buildSmartAssistantLiveMicButton(colors),
            _buildCircleButton(
              colors: colors,
              icon: CupertinoIcons.xmark,
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
      ),
    );
  }

  /// Helper to build secondary round control buttons (pause, close).
  Widget _buildCircleButton({
    required _LiveTheme colors,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Icon(icon, color: colors.onSurface, size: 22),
      ),
    );
  }

  /// Signature large glowing Smart Assistant Live microphone button with multi-ring ripple pulse.
  Widget _buildSmartAssistantLiveMicButton(_LiveTheme colors) {
    final isActive = _state == LiveAssistantState.listening ||
        _state == LiveAssistantState.speaking;

    return SizedBox(
      width: 84,
      height: 84,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isActive) ...[
                Container(
                  width: 108 + (_pulseController.value * 20),
                  height: 108 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.primary.withValues(
                        alpha: (1.0 - _pulseController.value) * 0.35,
                      ),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 88 + (_pulseController.value * 14),
                  height: 88 + (_pulseController.value * 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(
                      alpha: (1.0 - _pulseController.value) * 0.18,
                    ),
                  ),
                ),
              ],
              child!,
            ],
          );
        },
        child: GestureDetector(
          onTap: _onMicButtonTapped,
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _state == LiveAssistantState.speaking
                  ? CupertinoIcons.waveform
                  : CupertinoIcons.mic_fill,
              color: colors.onPrimary,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}
