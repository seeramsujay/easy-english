import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:easy_english/features/ai_coach/models/ai_coach_message.dart';
import 'package:easy_english/features/ai_coach/services/ai_coach_service.dart';

void main() {
  group('AI Coach Models & Logic Tests', () {
    test('AiCoachMessage properly detects grammar corrections', () {
      final messageWithCorrection = AiCoachMessage(
        id: 'msg-1',
        role: 'model',
        text: 'I goes to store',
        correctedText: 'I go to the store',
        feedback: 'Use "go" with first person subject.',
        timestamp: DateTime.now(),
      );

      expect(messageWithCorrection.hasCorrection, isTrue);

      final messageWithoutCorrection = AiCoachMessage(
        id: 'msg-2',
        role: 'model',
        text: 'I go to the store',
        correctedText: 'I go to the store',
        timestamp: DateTime.now(),
      );

      expect(messageWithoutCorrection.hasCorrection, isFalse);
    });

    test('AiCoachResponse parses valid JSON from Vercel proxy', () {
      final json = {
        'correctedText': 'How are you doing today?',
        'feedback': 'Sounds very natural!',
        'reply': 'I am doing wonderful, thanks for asking!',
      };

      final response = AiCoachResponse.fromJson(json);
      expect(response.correctedText, 'How are you doing today?');
      expect(response.feedback, 'Sounds very natural!');
      expect(response.reply, 'I am doing wonderful, thanks for asking!');
    });

    test('AiCoachService succeeds on 200 response from Vercel proxy', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], startsWith('Bearer '));
        return http.Response(
          jsonEncode({
            'correctedText': 'I would like a coffee.',
            'feedback': 'Polite phrasing used.',
            'reply': 'Sure! Would you like milk with that?',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiCoachService(client: mockClient, endpoint: 'https://test.api/coach');
      final result = await service.queryCoach(text: 'I want coffee');

      expect(result.correctedText, 'I would like a coffee.');
      expect(result.reply, 'Sure! Would you like milk with that?');
    });

    test('AiCoachService throws AiCoachEntitlementException on 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Pro subscription required.'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiCoachService(client: mockClient, endpoint: 'https://test.api/coach');
      expect(
        () async => await service.queryCoach(text: 'Hello'),
        throwsA(isA<AiCoachEntitlementException>()),
      );
    });

    test('AiCoachService throws AiCoachQuotaExceededException on 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Daily limit reached.'}),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiCoachService(client: mockClient, endpoint: 'https://test.api/coach');
      expect(
        () async => await service.queryCoach(text: 'Hello'),
        throwsA(isA<AiCoachQuotaExceededException>()),
      );
    });
  });
}
