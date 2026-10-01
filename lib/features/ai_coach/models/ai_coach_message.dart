class AiCoachMessage {
  final String id;
  final String role; // 'user' or 'model'
  final String text;
  final String? correctedText;
  final String? feedback;
  final DateTime timestamp;

  const AiCoachMessage({
    required this.id,
    required this.role,
    required this.text,
    this.correctedText,
    this.feedback,
    required this.timestamp,
  });

  bool get isUser => role == 'user';
  bool get hasCorrection =>
      correctedText != null &&
      correctedText!.trim().isNotEmpty &&
      correctedText!.trim().toLowerCase() != text.trim().toLowerCase();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      if (correctedText != null) 'correctedText': correctedText,
      if (feedback != null) 'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AiCoachMessage.fromJson(Map<String, dynamic> json) {
    return AiCoachMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      text: json['text'] as String,
      correctedText: json['correctedText'] as String?,
      feedback: json['feedback'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class AiCoachResponse {
  final String correctedText;
  final String feedback;
  final String reply;

  const AiCoachResponse({
    required this.correctedText,
    required this.feedback,
    required this.reply,
  });

  factory AiCoachResponse.fromJson(Map<String, dynamic> json) {
    return AiCoachResponse(
      correctedText: json['correctedText'] as String? ?? '',
      feedback: json['feedback'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
    );
  }
}
