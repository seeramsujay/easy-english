enum SignalingType {
  join,
  offer,
  answer,
  candidate,
  leave,
}

class SignalingMessage {
  final SignalingType type;
  final String senderId;
  final String? roomId;
  final String? sdp;
  final Map<String, dynamic>? candidate;
  final String? sasCode;
  final int timestamp;

  const SignalingMessage({
    required this.type,
    required this.senderId,
    this.roomId,
    this.sdp,
    this.candidate,
    this.sasCode,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'senderId': senderId,
        if (roomId != null) 'roomId': roomId,
        if (sdp != null) 'sdp': sdp,
        if (candidate != null) 'candidate': candidate,
        if (sasCode != null) 'sasCode': sasCode,
        'timestamp': timestamp,
      };

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: SignalingType.values.byName(json['type'] as String),
      senderId: json['senderId'] as String,
      roomId: json['roomId'] as String?,
      sdp: json['sdp'] as String?,
      candidate: json['candidate'] != null
          ? Map<String, dynamic>.from(json['candidate'] as Map)
          : null,
      sasCode: json['sasCode'] as String?,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
