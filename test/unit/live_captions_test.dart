import 'package:flutter_test/flutter_test.dart';
import 'package:easy_english/features/ai_coach/services/live_captions_simulator.dart';

void main() {
  group('Google Live Captions Audio Simulator Tests', () {
    late LiveCaptionsAudioSimulator simulator;

    setUp(() {
      simulator = LiveCaptionsAudioSimulator();
    });

    tearDown(() {
      simulator.dispose();
    });

    test('Simulator initial state is not listening', () {
      expect(simulator.isListening, isFalse);
    });

    test('Simulator starts listening and emits progressive caption tokens', () async {
      final segments = <LiveCaptionSegment>[];
      final subscription = simulator.captionStream.listen(segments.add);

      String? finalizedText;
      simulator.startSimulatedListening(
        customUtterance: 'I like practice',
        onFinalResult: (finalText) {
          finalizedText = finalText;
        },
      );

      expect(simulator.isListening, isTrue);

      // Wait for the simulation timer to emit segments
      await Future.delayed(const Duration(milliseconds: 1600));

      expect(segments.isNotEmpty, isTrue);
      expect(segments.last.isFinal, isTrue);
      expect(segments.last.text, equals('I like practice'));
      expect(finalizedText, equals('I like practice'));

      await subscription.cancel();
    });

    test('Simulator stopListening halts emissions immediately', () async {
      simulator.startSimulatedListening(customUtterance: 'One two three four five');
      expect(simulator.isListening, isTrue);

      simulator.stopListening();
      expect(simulator.isListening, isFalse);
    });
  });
}
