import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_english/features/moderation/models/moderation_result.dart';
import 'package:easy_english/features/moderation/services/moderation_service.dart';

void main() {
  group('On-Device Content Moderation Tests', () {
    test('Safe language returns isSafe = true', () {
      final result = ModerationService.evaluateText('Hello! Nice to meet you for English practice.');
      expect(result.isSafe, isTrue);
      expect(result.riskLevel, ModerationRiskLevel.none);
      expect(result.flaggedTerms, isEmpty);
    });

    test('Avoids Scunthorpe false positives', () {
      final safeWords = [
        'This is a classic book.',
        'Can I pass you the salt?',
        'I am an assistant teacher.',
        'Please spread the butter on toast.',
      ];

      for (final text in safeWords) {
        final result = ModerationService.evaluateText(text);
        expect(result.isSafe, isTrue, reason: 'Failed on word: $text');
      }
    });

    test('Detects direct toxic terms', () {
      final result = ModerationService.evaluateText('You are an asshole');
      expect(result.isSafe, isFalse);
      expect(result.riskLevel, ModerationRiskLevel.high);
      expect(result.flaggedTerms, contains('asshole'));
    });

    test('Normalizes homoglyphs and leetspeak', () {
      // @ -> a, ! -> i, $ -> s, 0 -> o
      final normalized = ModerationService.normalize('b!tch');
      expect(normalized, contains('bitch'));

      final result = ModerationService.evaluateText('You are a b!tch');
      expect(result.isSafe, isFalse);
    });

    test('Strips zero-width characters', () {
      // Invisible zero-width space in the middle of a blocked word
      const zeroWidthText = 'f\u200Buck';
      final result = ModerationService.evaluateText(zeroWidthText);
      expect(result.isSafe, isFalse);
    });

    test('AudioSafetyBuffer rolls over older chunks past maxBytes', () {
      // Buffer for 100 bytes
      final buffer = AudioSafetyBuffer(sampleRate: 50, seconds: 1); // 50 * 2 * 1 = 100 bytes

      // Append 60 bytes
      buffer.appendChunk(Uint8List(60));
      // Append 60 more bytes (total 120 > 100)
      buffer.appendChunk(Uint8List(60));

      final exported = buffer.exportBuffer();
      expect(exported.length, 60); // First 60 bytes evicted
    });
  });
}
