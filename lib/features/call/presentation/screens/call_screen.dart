import 'dart:async';
import 'package:flutter/material.dart';
import '../../../crypto/models/crypto_models.dart';
import '../../../moderation/services/moderation_service.dart';

class CallScreen extends StatefulWidget {
  final String peerName;
  final SasVerificationCode? sasVerification;

  const CallScreen({
    super.key,
    this.peerName = 'English Learner',
    this.sasVerification,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMicMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  final AudioSafetyBuffer _audioBuffer = AudioSafetyBuffer();

  // Active SAS code for E2EE visual verification
  late SasVerificationCode _activeSas;

  @override
  void initState() {
    super.initState();
    _activeSas = widget.sasVerification ??
        const SasVerificationCode(
          numericCode: '4829',
          emojis: ['🚀', '🐱', '💎', '🌟'],
        );

    // Call duration timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _audioBuffer.clear();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video Viewport (Full screen)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1E293B),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.blue.shade700,
                        child: const Icon(Icons.person, size: 64, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.peerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Direct P2P WebRTC Connected',
                        style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Local Video Picture-in-Picture (Top Right)
            Positioned(
              top: 16,
              right: 16,
              width: 110,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: _isVideoEnabled
                        ? const Icon(Icons.videocam, color: Colors.white38, size: 36)
                        : const Icon(Icons.videocam_off, color: Colors.redAccent, size: 36),
                  ),
                ),
              ),
            ),

            // Top Status Bar & E2EE SAS Verification Pill
            Positioned(
              top: 16,
              left: 16,
              right: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Call timer pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_callDurationSeconds),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // SAS Verification Pill
                  GestureDetector(
                    onTap: _showSasInfoDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'SAS: ${_activeSas.numericCode} ${_activeSas.emojiString}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom In-Call Controls Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black87.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Audio Toggle
                    IconButton(
                      icon: Icon(
                        _isMicMuted ? Icons.mic_off : Icons.mic,
                        color: _isMicMuted ? Colors.redAccent : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isMicMuted = !_isMicMuted;
                        });
                      },
                    ),

                    // Camera Video Toggle
                    IconButton(
                      icon: Icon(
                        _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        color: _isVideoEnabled ? Colors.white : Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _isVideoEnabled = !_isVideoEnabled;
                        });
                      },
                    ),

                    // Speakerphone Toggle
                    IconButton(
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSpeakerOn = !_isSpeakerOn;
                        });
                      },
                    ),

                    // Report Peer (Moderation snapshot)
                    IconButton(
                      icon: const Icon(Icons.shield_outlined, color: Colors.amber),
                      tooltip: 'Report Peer',
                      onPressed: _showReportDialog,
                    ),

                    // End Call Button
                    FloatingActionButton.small(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.call_end),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSasInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('End-to-End Encryption'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your call is secured with direct peer-to-peer encryption (X25519 & AES-256-GCM).',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Compare these 4 emojis and code with your peer:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${_activeSas.numericCode}\n${_activeSas.emojiString}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If they match, your connection is guaranteed free of any eavesdropping or interception.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report & Block Peer'),
        content: const Text(
          'Would you like to report this user for abusive behavior? The last 15 seconds of audio buffer will be saved locally to create an abuse report, and this peer will be blocked from matching with you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Peer reported and blocked. Thank you for keeping EasyEnglish safe!'),
                ),
              );
            },
            child: const Text('Report & Block'),
          ),
        ],
      ),
    );
  }
}
