import 'package:flutter_test/flutter_test.dart';
import 'package:easy_english/features/call/models/call_models.dart';

void main() {
  group('WebRTC Signaling Protocol Tests', () {
    test('SignalingMessage correctly serializes and deserializes Offer message', () {
      final msg = SignalingMessage(
        type: SignalingType.offer,
        senderId: 'peer_user_1',
        roomId: 'room_english_p2p',
        sdp: 'v=0\r\no=- 123456 2 IN IP4 127.0.0.1...',
        sasCode: '4829',
        timestamp: 1600000000,
      );

      final json = msg.toJson();
      expect(json['type'], 'offer');
      expect(json['senderId'], 'peer_user_1');
      expect(json['roomId'], 'room_english_p2p');
      expect(json['sasCode'], '4829');

      final reconstructed = SignalingMessage.fromJson(json);
      expect(reconstructed.type, SignalingType.offer);
      expect(reconstructed.senderId, 'peer_user_1');
      expect(reconstructed.sdp, msg.sdp);
      expect(reconstructed.sasCode, '4829');
    });

    test('SignalingMessage handles ICE Candidate payload', () {
      final candidateMap = {
        'candidate': 'candidate:1 1 UDP 2130706431 192.168.1.1 50000 typ host',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      };

      final msg = SignalingMessage(
        type: SignalingType.candidate,
        senderId: 'peer_user_2',
        candidate: candidateMap,
        timestamp: 1600000001,
      );

      final json = msg.toJson();
      expect(json['type'], 'candidate');

      final reconstructed = SignalingMessage.fromJson(json);
      expect(reconstructed.type, SignalingType.candidate);
      expect(reconstructed.candidate?['sdpMid'], '0');
      expect(reconstructed.candidate?['sdpMLineIndex'], 0);
    });

    test('SignalingMessage handles Leave type without SDP or candidate', () {
      final msg = SignalingMessage(
        type: SignalingType.leave,
        senderId: 'peer_user_1',
        timestamp: 1600000002,
      );

      final json = msg.toJson();
      expect(json['type'], 'leave');
      expect(json['sdp'], isNull);
      expect(json['candidate'], isNull);

      final reconstructed = SignalingMessage.fromJson(json);
      expect(reconstructed.type, SignalingType.leave);
    });
  });
}
