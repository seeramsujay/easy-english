import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../models/crypto_models.dart';

class CryptoSecurityException implements Exception {
  final String message;
  const CryptoSecurityException(this.message);

  @override
  String toString() => 'CryptoSecurityException: $message';
}

/// Zero-Trust Cryptographic Engine providing E2EE, HKDF key derivation,
/// replay attack prevention, and SAS (Short Authentication String) generation.
class CryptoService {
  final X25519 _x25519;
  final AesGcm _aesGcm;
  final Sha256 _sha256;

  static const List<String> _sasEmojiAlphabet = [
    '🐱', '🚀', '🌟', '🍎', '🎸', '🐬', '🍕', '🎯',
    '💎', '🌈', '⚽', '🌸', '⚡', '🔔', '🍦', '🏆',
  ];

  CryptoService({
    X25519? x25519,
    AesGcm? aesGcm,
    Sha256? sha256,
  })  : _x25519 = x25519 ?? X25519(),
        _aesGcm = aesGcm ?? AesGcm.with256bits(),
        _sha256 = sha256 ?? Sha256();

  /// 1. Generate an ephemeral X25519 key pair for the WebRTC session.
  Future<SimpleKeyPair> generateEphemeralKeyPair() async {
    return await _x25519.newKeyPair();
  }

  /// 2. Derive AES-256 session key from X25519 shared secret using HKDF-SHA256.
  Future<SecretKey> deriveSessionKey({
    required SimpleKeyPair localKeyPair,
    required SimplePublicKey remotePublicKey,
    required String sessionId,
  }) async {
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: remotePublicKey,
    );

    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );

    final info = utf8.encode('EasyEnglish-E2EE-v1:$sessionId');
    return await hkdf.deriveKey(
      secretKey: sharedSecret,
      info: info,
    );
  }

  /// 3. Derive deterministic SAS (Short Authentication String) for visual MITM verification.
  /// Generates identical 4-digit numeric code and 4-emoji sequence on both endpoints.
  Future<SasVerificationCode> deriveSas({
    required SimplePublicKey localPublicKey,
    required SimplePublicKey remotePublicKey,
  }) async {
    final localBytes = localPublicKey.bytes;
    final remoteBytes = remotePublicKey.bytes;

    // Lexicographical sorting to ensure both peers get the exact same order
    final isLocalFirst = _compareByteArrays(localBytes, remoteBytes) <= 0;
    final combinedBytes = BytesBuilder();
    if (isLocalFirst) {
      combinedBytes.add(localBytes);
      combinedBytes.add(remoteBytes);
    } else {
      combinedBytes.add(remoteBytes);
      combinedBytes.add(localBytes);
    }

    final hash = await _sha256.hash(combinedBytes.toBytes());
    final hashBytes = hash.bytes;

    // 4-digit numeric code between 1000 and 9999
    final codeValue = ((hashBytes[0] << 8) | hashBytes[1]) % 9000 + 1000;
    final numericCode = codeValue.toString();

    // 4 visual emojis
    final emojis = <String>[
      _sasEmojiAlphabet[hashBytes[2] % _sasEmojiAlphabet.length],
      _sasEmojiAlphabet[hashBytes[3] % _sasEmojiAlphabet.length],
      _sasEmojiAlphabet[hashBytes[4] % _sasEmojiAlphabet.length],
      _sasEmojiAlphabet[hashBytes[5] % _sasEmojiAlphabet.length],
    ];

    return SasVerificationCode(
      numericCode: numericCode,
      emojis: emojis,
    );
  }

  /// 4. Encrypt message with AES-256-GCM using monotonic sequence counter and session AAD.
  Future<EncryptedMessageEnvelope> encrypt({
    required String plaintext,
    required SecretKey key,
    required int sequenceNumber,
    required String sessionId,
  }) async {
    final plaintextBytes = utf8.encode(plaintext);
    final aad = utf8.encode('$sessionId:$sequenceNumber');

    final secretBox = await _aesGcm.encrypt(
      plaintextBytes,
      secretKey: key,
      aad: aad,
    );

    return EncryptedMessageEnvelope(
      sequenceNumber: sequenceNumber,
      nonceBase64: base64Encode(secretBox.nonce),
      ciphertextBase64: base64Encode(secretBox.cipherText),
      macBase64: base64Encode(secretBox.mac.bytes),
    );
  }

  /// 5. Decrypt message with AES-256-GCM and verify sequence counter against replay attacks.
  Future<String> decrypt({
    required EncryptedMessageEnvelope envelope,
    required SecretKey key,
    required int expectedSequenceNumber,
    required String sessionId,
  }) async {
    if (envelope.sequenceNumber != expectedSequenceNumber) {
      throw CryptoSecurityException(
        'Replay or out-of-order packet detected! Expected seq $expectedSequenceNumber, got ${envelope.sequenceNumber}',
      );
    }

    final aad = utf8.encode('$sessionId:${envelope.sequenceNumber}');
    final nonce = base64Decode(envelope.nonceBase64);
    final cipherText = base64Decode(envelope.ciphertextBase64);
    final macBytes = base64Decode(envelope.macBase64);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    try {
      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: key,
        aad: aad,
      );
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw CryptoSecurityException('Message authentication failed: tampered ciphertext or key mismatch.');
    }
  }

  int _compareByteArrays(List<int> a, List<int> b) {
    final minLen = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLen; i++) {
      if (a[i] != b[i]) {
        return a[i].compareTo(b[i]);
      }
    }
    return a.length.compareTo(b.length);
  }
}
