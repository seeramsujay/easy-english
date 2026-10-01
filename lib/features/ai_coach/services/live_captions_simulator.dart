import 'dart:async';
import 'dart:math';

/// Represents a simulated live caption segment produced by Google Live Caption
class LiveCaptionSegment {
  final String text;
  final bool isFinal;
  final double confidence;
  final Duration timestamp;

  const LiveCaptionSegment({
    required this.text,
    this.isFinal = false,
    this.confidence = 0.95,
    required this.timestamp,
  });
}

/// Service simulating real-time Google Live Captions speech-to-text
/// from user microphone audio in real time.
class LiveCaptionsAudioSimulator {
  final StreamController<LiveCaptionSegment> _captionController =
      StreamController<LiveCaptionSegment>.broadcast();

  Stream<LiveCaptionSegment> get captionStream => _captionController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  Timer? _simulationTimer;
  int _currentStep = 0;

  // Preset conversation prompts commonly uttered by learners
  final List<List<String>> _utteranceBatches = [
    [
      'I want to...',
      'I want to order...',
      'I want to order a coffee with less sugar please.',
    ],
    [
      'Yesterday I...',
      'Yesterday I go to the supermarket...',
      'Yesterday I go to the supermarket and bought some fruits.',
    ],
    [
      'Can you tell...',
      'Can you tell me how...',
      'Can you tell me how to prepare for a job interview in English?',
    ],
    [
      'I have been...',
      'I have been learning English...',
      'I have been learning English for three years but I feel nervous speaking.',
    ],
    [
      'In my opinion...',
      'In my opinion watching movies...',
      'In my opinion watching movies is the most best way to improve pronunciation.',
    ],
  ];

  int _batchIndex = 0;

  /// Starts listening and emitting simulated Google Live Caption chunks
  void startSimulatedListening({
    String? customUtterance,
    void Function(String finalText)? onFinalResult,
  }) {
    if (_isListening) return;
    _isListening = true;
    _currentStep = 0;

    List<String> words;
    if (customUtterance != null && customUtterance.isNotEmpty) {
      final tokens = customUtterance.split(' ');
      words = [];
      for (int i = 1; i <= tokens.length; i++) {
        words.add(tokens.take(i).join(' '));
      }
    } else {
      words = _utteranceBatches[_batchIndex % _utteranceBatches.length];
      _batchIndex++;
    }

    // Emit live interim caption tokens every 450ms, then finalize
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      if (_currentStep < words.length) {
        final isLast = _currentStep == words.length - 1;
        final segment = LiveCaptionSegment(
          text: words[_currentStep],
          isFinal: isLast,
          confidence: 0.92 + Random().nextDouble() * 0.07,
          timestamp: Duration(milliseconds: _currentStep * 450),
        );
        _captionController.add(segment);

        if (isLast) {
          timer.cancel();
          _isListening = false;
          if (onFinalResult != null) {
            onFinalResult(words.last);
          }
        }
        _currentStep++;
      } else {
        timer.cancel();
        _isListening = false;
      }
    });
  }

  /// Stop simulated live captions
  void stopListening() {
    _isListening = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void dispose() {
    stopListening();
    _captionController.close();
  }
}
