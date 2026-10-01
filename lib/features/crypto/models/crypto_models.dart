import 'dart:convert';

/// SAS (Short Authentication String) used for out-of-band visual verification.
class SasVerificationCode {
  final String numericCode; // e.g. "4829"
  final List<String> emojis; // e.g. ["🚀", "🐱", "💎", "🌟"]

  const SasVerificationCode({
    required this.numericCode,
    required this.emojis,
  });

  String get emojiString => emojis.join(' ');
}

/// Encrypted message envelope with replay-prevention sequence counter.
class EncryptedMessageEnvelope {
  final int sequenceNumber;
  final String nonceBase64;
  final String ciphertextBase64;
  final String macBase64;

  const EncryptedMessageEnvelope({
    required this.sequenceNumber,
    required this.nonceBase64,
    required this.ciphertextBase64,
    required this.macBase64,
  });

  Map<String, dynamic> toJson() => {
        'seq': sequenceNumber,
        'nonce': nonceBase64,
        'ciphertext': ciphertextBase64,
        'mac': macBase64,
      };

  String toJsonString() => jsonEncode(toJson());

  factory EncryptedMessageEnvelope.fromJson(Map<String, dynamic> json) {
    return EncryptedMessageEnvelope(
      sequenceNumber: json['seq'] as int,
      nonceBase64: json['nonce'] as String,
      ciphertextBase64: json['ciphertext'] as String,
      macBase64: json['mac'] as String,
    );
  }

  factory EncryptedMessageEnvelope.fromJsonString(String source) {
    return EncryptedMessageEnvelope.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}
