import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_coach_message.dart';
import '../../providers/ai_coach_provider.dart';
import '../../services/live_captions_simulator.dart';
import '../../../paywall/presentation/screens/paywall_screen.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LiveCaptionsAudioSimulator _captionSimulator = LiveCaptionsAudioSimulator();

  StreamSubscription<LiveCaptionSegment>? _captionSubscription;
  String _liveCaptionText = '';
  bool _isLiveCapturing = false;

  final List<String> _quickTopics = const [
    '☕ Ordering Coffee',
    '💼 Job Interview',
    '✈️ Airport & Travel',
    '🍕 Restaurant Dinner',
    '🎬 Movies & Hobbies',
  ];

  @override
  void initState() {
    super.initState();
    _captionSubscription = _captionSimulator.captionStream.listen((segment) {
      if (mounted) {
        setState(() {
          _liveCaptionText = segment.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _captionSubscription?.cancel();
    _captionSimulator.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleLiveCaptions() {
    if (_isLiveCapturing) {
      _captionSimulator.stopListening();
      setState(() {
        _isLiveCapturing = false;
        _liveCaptionText = '';
      });
    } else {
      setState(() {
        _isLiveCapturing = true;
        _liveCaptionText = 'Listening to speech...';
      });

      _captionSimulator.startSimulatedListening(
        onFinalResult: (finalText) {
          if (mounted) {
            setState(() {
              _isLiveCapturing = false;
              _liveCaptionText = '';
            });
            ref.read(aiCoachNotifierProvider.notifier).sendMessage(finalText);
            _scrollToBottom();
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCoachNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: Colors.blue, size: 20),
                SizedBox(width: 6),
                Text('Gemini AI Coach', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(
              'Powered by Gemini 2.5 Flash Lite • Live Captions',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(aiCoachNotifierProvider.notifier).clearConversation();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Topic Suggestion Pills
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickTopics.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = _quickTopics[index];
                  return ActionChip(
                    label: Text(topic, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      ref.read(aiCoachNotifierProvider.notifier).selectTopic(topic);
                      _scrollToBottom();
                    },
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Live Caption Banner (Google Live Captions simulator)
            if (_isLiveCapturing || _liveCaptionText.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: Colors.cyanAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'GOOGLE LIVE CAPTIONS (SPEECH-TO-TEXT)',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _liveCaptionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: () {
                        _captionSimulator.stopListening();
                        setState(() {
                          _isLiveCapturing = false;
                          _liveCaptionText = '';
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Error banner if any (e.g. Quota or Entitlement needed)
            if (aiState.error != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        aiState.error!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaywallScreen()),
                        );
                      },
                      child: const Text('Upgrade'),
                    ),
                  ],
                ),
              ),

            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: aiState.messages.length,
                itemBuilder: (context, index) {
                  final message = aiState.messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Loading indicator
            if (aiState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gemini 2.5 Flash Lite is thinking...',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

            // Input Bar with Google Live Captions Mic Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Live Captions simulated speech button
                  IconButton.filledTonal(
                    tooltip: 'Speak with Live Captions',
                    onPressed: aiState.isLoading ? null : _toggleLiveCaptions,
                    style: IconButton.styleFrom(
                      backgroundColor: _isLiveCapturing ? Colors.red.shade100 : Colors.blue.shade50,
                    ),
                    icon: Icon(
                      _isLiveCapturing ? Icons.mic_off : Icons.mic,
                      color: _isLiveCapturing ? Colors.red : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type or tap mic for Live Captions...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onSubmitted: (val) {
                        _handleSend();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: aiState.isLoading ? null : _handleSend,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(aiCoachNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Widget _buildMessageBubble(AiCoachMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 3),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.closed_caption_outlined, size: 12, color: Colors.white70),
                  SizedBox(width: 3),
                  Text(
                    'Live Captions',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // AI Response Bubble with optional Grammar feedback card
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conversational reply
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 12, color: Colors.blue.shade700),
                      const SizedBox(width: 3),
                      Text(
                        'Gemini 2.5 Flash Lite',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Grammar Correction & Tip Card (if provided by Gemini)
            if (message.hasCorrection || (message.feedback != null && message.feedback!.isNotEmpty)) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Grammar Suggestion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    if (message.hasCorrection) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Better: "${message.correctedText}"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    if (message.feedback != null && message.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message.feedback!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
