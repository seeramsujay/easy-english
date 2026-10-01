import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/revenuecat_service.dart';
import '../models/ai_coach_message.dart';

class AiCoachException implements Exception {
  final String message;
  final String? code;
  const AiCoachException(this.message, [this.code]);

  @override
  String toString() => 'AiCoachException: $message (code: $code)';
}

class AiCoachEntitlementException extends AiCoachException {
  const AiCoachEntitlementException([String message = 'Active Pro subscription required to use AI Coach.'])
      : super(message, 'ENTITLEMENT_REQUIRED');
}

class AiCoachQuotaExceededException extends AiCoachException {
  const AiCoachQuotaExceededException([String message = 'Daily AI prompt quota (50/day) reached. Resets at midnight UTC.'])
      : super(message, 'QUOTA_EXCEEDED');
}

class AiCoachService {
  final http.Client _client;
  final String _endpoint;

  AiCoachService({
    http.Client? client,
    String? endpoint,
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? AppConstants.aiCoachEndpoint;

  /// Sends a conversational prompt to the Vercel Serverless Gemini Proxy.
  /// Passes the RevenueCat App User ID as a Bearer token for server-side verification.
  Future<AiCoachResponse> queryCoach({
    required String text,
    String mode = 'conversation',
    List<AiCoachMessage> history = const [],
  }) async {
    final appUserId = await RevenueCatService.getAppUserId();

    final payload = {
      'mode': mode,
      'text': text,
      'conversationHistory': history.map((m) => {
        'role': m.role,
        'text': m.text,
      }).toList(),
    };

    try {
      final response = await _client.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appUserId',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AiCoachResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw const AiCoachEntitlementException();
      } else if (response.statusCode == 429) {
        throw const AiCoachQuotaExceededException();
      } else {
        String errMsg = 'Server returned error status: ${response.statusCode}';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody['error'] != null) {
            errMsg = errBody['error'].toString();
          }
        } catch (_) {}
        throw AiCoachException(errMsg);
      }
    } on AiCoachException {
      rethrow;
    } catch (e) {
      debugPrint('[AiCoachService] Network error: $e');
      throw AiCoachException('Could not connect to AI Coach. Check your internet connection.');
    }
  }

  void dispose() {
    _client.close();
  }
}
