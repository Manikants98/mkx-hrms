import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:mkx_core/network/dio_client.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/ai_chat_model.dart';

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
  /// mimicking Smart Assistant Live voice streaming while speaking via Text-To-Speech.
  Future<void> _streamAssistantSpeech(String fullText) async {
    final speakable = _toSpeakableText(fullText);
    _lastFullResponse = fullText;
    setState(() {
      _state = LiveAssistantState.speaking;
      _currentTranscript = "";
    });

    if (_ttsInitialized) {
      try {
        await _flutterTts.stop();
        await _flutterTts.speak(speakable);
      } catch (_) {}
    }

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
          if (!_ttsInitialized) {
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted && _state == LiveAssistantState.speaking) {
                _startListeningCycle();
              }
            });
          }
        }
      },
    );
  }

  /// Toggles pause and resume of the voice interaction.
  void _togglePause() {
    setState(() {
      if (_state == LiveAssistantState.paused) {
        _state = LiveAssistantState.listening;
        _pulseController.repeat();
        _startListeningCycle();
      } else {
        _state = LiveAssistantState.paused;
        _speechStreamTimer?.cancel();
        _pulseController.stop();
        try {
          _speechToText.stop();
          _flutterTts.stop();
        } catch (_) {}
      }
    });
  }

  /// Handles tap on the primary yellow microphone button.
  /// In speaking state interrupts the current output.
  /// In listening/paused state toggles listening on/off or submits captured speech.
  Future<void> _onMicButtonTapped() async {
    if (_state == LiveAssistantState.speaking) {
      _speechStreamTimer?.cancel();
      try {
        await _flutterTts.stop();
      } catch (_) {}
      _startListeningCycle();
    } else if (_state == LiveAssistantState.paused) {
      _startListeningCycle();
    } else if (_state == LiveAssistantState.listening) {
      if (_speechToText.isListening) {
        try {
          await _speechToText.stop();
        } catch (_) {}
        if (_userSpokenText.trim().isNotEmpty) {
          _handleVoiceQuery(_userSpokenText.trim());
        }
      } else {
        _startListeningCycle();
      }
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
                          textAlign: TextAlign.center,
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
                          color: colorScheme.onPrimary,
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
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ] else if (isThinking) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: M3EProgressIndicator.circular(
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

  /// Real-time breathing status pill badge (e.g. "Listening to your voice...").
  Widget _buildStatusIndicator(M3EColorScheme colorScheme) {
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
    final double chipWidth = (MediaQuery.of(context).size.width - 32 - 8) / 2;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _quickVoicePrompts.map((prompt) {
        return SizedBox(
          width: chipWidth,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Bottom control dock containing the Pause button,
  /// the signature pulsating Smart Assistant Live microphone, and the Close button.
  Widget _buildBottomControlDock(M3EColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: SizedBox(
        height: 84,
        child: Row(
          spacing: 60,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCircleButton(
              colorScheme: colorScheme,
              icon: _state == LiveAssistantState.paused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              onPressed: _togglePause,
            ),
            _buildSmartAssistantLiveMicButton(colorScheme),
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

  /// Signature large glowing Smart Assistant Live microphone button with multi-ring ripple pulse.
  Widget _buildSmartAssistantLiveMicButton(M3EColorScheme colorScheme) {
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
                      color: colorScheme.primary.withValues(
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
                    color: colorScheme.primary.withValues(
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
      ),
    );
  }
}
