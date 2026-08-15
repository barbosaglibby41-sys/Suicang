import 'chat_models.dart';

class GenerationSettings {
  const GenerationSettings({
    this.model = 'Claude',
    this.temperature = .8,
    this.maxTokens = 2048,
    this.topP = .95,
    this.repetitionPenalty = 1.05,
  });

  final String model;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double repetitionPenalty;

  GenerationSettings copyWith({
    String? model,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? repetitionPenalty,
  }) => GenerationSettings(
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        topP: topP ?? this.topP,
        repetitionPenalty: repetitionPenalty ?? this.repetitionPenalty,
      );
}

class GenerationRequest {
  const GenerationRequest({
    required this.messages,
    required this.model,
    this.temperature = .8,
    this.topP = .95,
    this.maxTokens = 2048,
    this.repetitionPenalty = 1.05,
    this.systemPrompt,
  });

  final List<ChatMessage> messages;
  final String model;
  final double temperature;
  final double topP;
  final int maxTokens;
  final double repetitionPenalty;
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
