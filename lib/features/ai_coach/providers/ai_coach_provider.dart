import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_coach_message.dart';
import '../services/ai_coach_service.dart';

final aiCoachServiceProvider = Provider<AiCoachService>((ref) {
  final service = AiCoachService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AiCoachState {
  final List<AiCoachMessage> messages;
  final bool isLoading;
  final String? error;
  final String? selectedTopic;

  const AiCoachState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.selectedTopic,
  });

  AiCoachState copyWith({
    List<AiCoachMessage>? messages,
    bool? isLoading,
    String? error,
    String? selectedTopic,
  }) {
    return AiCoachState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedTopic: selectedTopic ?? this.selectedTopic,
    );
  }
}

class AiCoachNotifier extends Notifier<AiCoachState> {
  static const _uuid = Uuid();

  @override
  AiCoachState build() {
    return AiCoachState(
      messages: [
        AiCoachMessage(
          id: 'welcome-001',
          role: 'model',
          text: 'Hello! I am your EasyEnglish AI Coach. Pick a topic or say anything to start practicing your spoken English!',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void selectTopic(String topic) {
    state = state.copyWith(selectedTopic: topic);
    sendMessage("Let's practice talking about: $topic. Ask me a question to start!");
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = AiCoachMessage(
      id: _uuid.v4(),
      role: 'user',
      text: trimmed,
      timestamp: DateTime.now(),
    );

    // Append user message immediately
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    final service = ref.read(aiCoachServiceProvider);

    try {
      final response = await service.queryCoach(
        text: trimmed,
        mode: state.selectedTopic ?? 'conversation',
        history: state.messages,
      );

      final modelMessage = AiCoachMessage(
        id: _uuid.v4(),
        role: 'model',
        text: response.reply,
        correctedText: response.correctedText,
        feedback: response.feedback,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, modelMessage],
        isLoading: false,
      );
    } on AiCoachEntitlementException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } on AiCoachQuotaExceededException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearConversation() {
    state = AiCoachState(
      messages: [
        AiCoachMessage(
          id: 'welcome-002',
          role: 'model',
          text: 'New session started! What would you like to practice today?',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}

final aiCoachNotifierProvider =
    NotifierProvider<AiCoachNotifier, AiCoachState>(() {
  return AiCoachNotifier();
});
