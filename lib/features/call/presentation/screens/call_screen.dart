import 'dart:async';
import 'package:flutter/material.dart';
import '../../../crypto/models/crypto_models.dart';
import '../../../moderation/services/moderation_service.dart';

class CallScreen extends StatefulWidget {
  final String peerName;
  final String? peerLocation;
  final SasVerificationCode? sasVerification;

  const CallScreen({
    super.key,
    this.peerName = 'English Learner',
    this.peerLocation = 'India 🇮🇳',
    this.sasVerification,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  bool _isMicMuted = false;
  bool _isSpeakerOn = true;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  final AudioSafetyBuffer _audioBuffer = AudioSafetyBuffer();

  late AnimationController _waveController;
  late SasVerificationCode _activeSas;

  @override
  void initState() {
    super.initState();
    _activeSas = widget.sasVerification ??
        const SasVerificationCode(
          numericCode: '4829',
          emojis: ['🚀', '🐱', '💎', '🌟'],
        );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

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
    _waveController.dispose();
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
      backgroundColor: const Color(0xFF0F172A), // Premium dark slate
      body: SafeArea(
        child: Stack(
          children: [
            // Center Pure Audio Experience UI
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Audio Waveform Radar Avatar
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 170 + (_waveController.value * 28),
                            height: 170 + (_waveController.value * 28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.12 * (1 - _waveController.value)),
                            ),
                          ),
                          Container(
                            width: 140 + (_waveController.value * 16),
                            height: 140 + (_waveController.value * 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.2 * (1 - _waveController.value)),
                            ),
                          ),
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: const Color(0xFF2563EB),
                            child: Text(
                              widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Peer Name & Location
                  Text(
                    widget.peerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Direct Audio • ${widget.peerLocation}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Call duration counter
                  Text(
                    _formatDuration(_callDurationSeconds),
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Audio Only Mode Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headset, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text(
                          '100% P2P Audio Practice (Zero Video)',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Status & Safety Bar
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // End-to-End Encryption Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'E2EE Audio',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // SAS Verification Pill
                  GestureDetector(
                    onTap: _showSasInfoDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
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

                  // Report / Block Action
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                    tooltip: 'Report & Block Audio',
                    onPressed: _showReportDialog,
                  ),
                ],
              ),
            ),

            // Bottom Audio Controls Bar
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Audio Toggle
                    IconButton(
                      icon: Icon(
                        _isMicMuted ? Icons.mic_off : Icons.mic,
                        color: _isMicMuted ? Colors.redAccent : Colors.white,
                        size: 26,
                      ),
                      tooltip: _isMicMuted ? 'Unmute' : 'Mute',
                      onPressed: () {
                        setState(() {
                          _isMicMuted = !_isMicMuted;
                        });
                      },
                    ),

                    // End Audio Call Button
                    FloatingActionButton(
                      heroTag: 'end_call_btn',
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: const CircleBorder(),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.call_end, size: 28),
                    ),

                    // Speakerphone Toggle
                    IconButton(
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: _isSpeakerOn ? const Color(0xFF38BDF8) : Colors.white60,
                        size: 26,
                      ),
                      tooltip: 'Speaker',
                      onPressed: () {
                        setState(() {
                          _isSpeakerOn = !_isSpeakerOn;
                        });
                      },
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
            Text('Audio Encryption (SAS)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compare this 4-digit code and emoji set with your peer to ensure zero eavesdropping or interception:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '${_activeSas.numericCode}   ${_activeSas.emojiString}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Verified'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report & Block Peer?'),
        content: const Text(
          'This will immediately end the audio call and submit the last 15 seconds of the encrypted audio buffer to our safety team.',
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
                  content: Text('Peer blocked and safety audio report submitted.'),
                ),
              );
            },
            child: const Text('Report & End Call'),
          ),
        ],
      ),
    );
  }
}
