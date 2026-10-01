import 'package:flutter_test/flutter_test.dart';
import 'package:easy_english/features/crypto/services/crypto_service.dart';

void main() {
  group('Zero-Trust Cryptographic Engine Tests', () {
    late CryptoService crypto;

    setUp(() {
      crypto = CryptoService();
    });

    test('Peer A and Peer B derive matching shared session keys via ECDH & HKDF', () async {
      final peerA = await crypto.generateEphemeralKeyPair();
      final peerB = await crypto.generateEphemeralKeyPair();

      final pubA = await peerA.extractPublicKey();
      final pubB = await peerB.extractPublicKey();

      const sessionId = 'session-test-12345';

      final keyA = await crypto.deriveSessionKey(
        localKeyPair: peerA,
        remotePublicKey: pubB,
        sessionId: sessionId,
      );

      final keyB = await crypto.deriveSessionKey(
        localKeyPair: peerB,
        remotePublicKey: pubA,
        sessionId: sessionId,
      );

      final keyABytes = await keyA.extractBytes();
      final keyBBytes = await keyB.extractBytes();

      expect(keyABytes, equals(keyBBytes));
      expect(keyABytes.length, 32); // 256 bits
    });

    test('Both peers calculate identical SAS numeric code and emojis', () async {
      final peerA = await crypto.generateEphemeralKeyPair();
      final peerB = await crypto.generateEphemeralKeyPair();

      final pubA = await peerA.extractPublicKey();
      final pubB = await peerB.extractPublicKey();

      // Peer A derives SAS
      final sasA = await crypto.deriveSas(
        localPublicKey: pubA,
        remotePublicKey: pubB,
      );

      // Peer B derives SAS in opposite parameter order
      final sasB = await crypto.deriveSas(
        localPublicKey: pubB,
        remotePublicKey: pubA,
      );

      expect(sasA.numericCode, equals(sasB.numericCode));
      expect(sasA.emojis, equals(sasB.emojis));
      expect(sasA.emojis.length, 4);
      expect(int.parse(sasA.numericCode), inInclusiveRange(1000, 9999));
    });

    test('Encrypt and decrypt message round-trip succeeds with valid sequence counter', () async {
      final peerA = await crypto.generateEphemeralKeyPair();
      final peerB = await crypto.generateEphemeralKeyPair();

      final pubA = await peerA.extractPublicKey();
      final pubB = await peerB.extractPublicKey();

      const sessionId = 'session-roundtrip-test';

      final keyA = await crypto.deriveSessionKey(
        localKeyPair: peerA,
        remotePublicKey: pubB,
        sessionId: sessionId,
      );

      final keyB = await crypto.deriveSessionKey(
        localKeyPair: peerB,
        remotePublicKey: pubA,
        sessionId: sessionId,
      );

      const secretText = 'Hello from confidential P2P English session!';

      final envelope = await crypto.encrypt(
        plaintext: secretText,
        key: keyA,
        sequenceNumber: 1,
        sessionId: sessionId,
      );

      final decrypted = await crypto.decrypt(
        envelope: envelope,
        key: keyB,
        expectedSequenceNumber: 1,
        sessionId: sessionId,
      );

      expect(decrypted, equals(secretText));
    });

    test('Replay attack / mismatched sequence number is rejected', () async {
      final peerA = await crypto.generateEphemeralKeyPair();
      final peerB = await crypto.generateEphemeralKeyPair();

      final pubA = await peerA.extractPublicKey();
      final pubB = await peerB.extractPublicKey();

      const sessionId = 'session-replay-test';

      final keyA = await crypto.deriveSessionKey(
        localKeyPair: peerA,
        remotePublicKey: pubB,
        sessionId: sessionId,
      );

      final keyB = await crypto.deriveSessionKey(
        localKeyPair: peerB,
        remotePublicKey: pubA,
        sessionId: sessionId,
      );

      final envelope = await crypto.encrypt(
        plaintext: 'Replayed message',
        key: keyA,
        sequenceNumber: 1,
        sessionId: sessionId,
      );

      // Attempt to decrypt with unexpected sequence number 2
      expect(
        () async => await crypto.decrypt(
          envelope: envelope,
          key: keyB,
          expectedSequenceNumber: 2,
          sessionId: sessionId,
        ),
        throwsA(isA<CryptoSecurityException>()),
      );
    });
  });
}
