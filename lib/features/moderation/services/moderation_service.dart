import 'dart:typed_data';
import '../models/moderation_result.dart';

/// On-device, privacy-preserving moderation engine.
/// Evaluates text and manages an in-memory 15s rolling audio buffer locally.
class ModerationService {
  // Homoglyph & Leetspeak substitution map
  static final Map<String, String> _leetMap = {
    '@': 'a',
    '4': 'a',
    '8': 'b',
    '3': 'e',
    '1': 'i',
    '!': 'i',
    '|': 'i',
    '0': 'o',
    '5': 's',
    '\$': 's',
    '7': 't',
    '+': 't',
    'vv': 'w',
  };

  // Blocked severe toxicity and harassment terms (exact word boundary tokens)
  static final Set<String> _blockedTokens = {
    'abuse',
    'asshole',
    'bitch',
    'bastard',
    'cunt',
    'dick',
    'fuck',
    'fucker',
    'fucking',
    'kill yourself',
    'kys',
    'nigger',
    'nigga',
    'pussy',
    'retard',
    'slut',
    'whore',
  };

  /// Normalizes unicode homoglyphs, zero-width characters, and repeated leetspeak.
  static String normalize(String input) {
    if (input.isEmpty) return '';

    // 1. Remove zero-width & invisible characters
    String clean = input.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // 2. Lowercase for normalization
    clean = clean.toLowerCase();

    // 3. Replace leetspeak symbols
    _leetMap.forEach((leet, replacement) {
      clean = clean.replaceAll(leet, replacement);
    });

    // 4. Collapse runs of 3+ identical consecutive characters to single character
    // e.g. "fuuuuuck" -> "fuck"
    clean = clean.replaceAllMapped(
      RegExp(r'(.)\1{2,}'),
      (match) => match.group(1)!,
    );

    return clean;
  }

  /// Evaluates text for harassment and toxicity using tokenized word-boundary matching.
  /// Prevents false-positives on words like "classic", "pass", "assistant", etc.
  static ModerationResult evaluateText(String input) {
    if (input.trim().isEmpty) {
      return ModerationResult.safe;
    }

    final normalized = normalize(input);
    final flaggedTerms = <String>[];

    for (final term in _blockedTokens) {
      // Use regex with word boundaries or space boundaries
      final pattern = RegExp(
        r'(^|\s|[^\w])' + RegExp.escape(term) + r'($|\s|[^\w])',
        caseSensitive: false,
      );

      if (pattern.hasMatch(normalized)) {
        flaggedTerms.add(term);
      }
    }

    if (flaggedTerms.isEmpty) {
      return ModerationResult(
        isSafe: true,
        riskLevel: ModerationRiskLevel.none,
        flaggedTerms: const [],
        normalizedText: normalized,
      );
    }

    return ModerationResult(
      isSafe: false,
      riskLevel: ModerationRiskLevel.high,
      flaggedTerms: flaggedTerms,
      normalizedText: normalized,
      feedbackReason: 'Message contains prohibited language or harassment.',
    );
  }
}

/// In-memory rolling audio FIFO buffer holding up to 15 seconds of raw audio.
/// Used exclusively for client-side user reporting without continuous cloud storage.
class AudioSafetyBuffer {
  final int maxBytes;
  final List<Uint8List> _chunks = [];
  int _currentByteLength = 0;

  /// Default: 16kHz 16-bit mono PCM = 32,000 bytes/sec * 15 sec = 480,000 bytes (~470 KB)
  AudioSafetyBuffer({int sampleRate = 16000, int seconds = 15})
      : maxBytes = sampleRate * 2 * seconds;

  /// Adds a new audio chunk into the rolling buffer.
  void appendChunk(Uint8List chunk) {
    _chunks.add(chunk);
    _currentByteLength += chunk.length;

    // Prune oldest chunks if buffer exceeds maxBytes
    while (_currentByteLength > maxBytes && _chunks.isNotEmpty) {
      final removed = _chunks.removeAt(0);
      _currentByteLength -= removed.length;
    }
  }

  /// Captures the last 15 seconds of audio for user reporting.
  Uint8List exportBuffer() {
    final builder = BytesBuilder(copy: false);
    for (final chunk in _chunks) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  /// Clears the buffer on call disconnect.
  void clear() {
    _chunks.clear;
    _currentByteLength = 0;
  }
}
