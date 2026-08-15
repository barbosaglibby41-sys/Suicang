import 'chat_models.dart';

class GenerationRequest {
  const GenerationRequest({
    required this.messages,
    required this.model,
    this.temperature = .8,
    this.maxTokens = 2048,
    this.systemPrompt,
  });

  final List<ChatMessage> messages;
  final String model;
  final double temperature;
  final int maxTokens;
  final String? systemPrompt;
}

sealed class GenerationEvent {
  const GenerationEvent();
}

class TextDelta extends GenerationEvent {
  const TextDelta(this.text);
  final String text;
}

class GenerationUsage extends GenerationEvent {
  const GenerationUsage({required this.inputTokens, required this.outputTokens});
  final int inputTokens;
  final int outputTokens;
}

class GenerationCompleted extends GenerationEvent {
  const GenerationCompleted();
}

class GenerationFailed extends GenerationEvent {
  const GenerationFailed(this.message);
  final String message;
}

abstract interface class LlmProvider {
  Stream<GenerationEvent> generate(GenerationRequest request);
}
