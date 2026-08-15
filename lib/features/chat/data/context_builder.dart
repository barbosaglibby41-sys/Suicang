import '../domain/chat_models.dart';
import '../domain/chat_workspace.dart';
import '../domain/generation.dart';
import '../../characters/domain/character_card.dart';
import '../../settings/domain/preset_models.dart';

class ChatContextBuilder {
  const ChatContextBuilder._();

  static GenerationRequest build({
    required CharacterProfile character,
    required UserPersona persona,
    required List<ChatMessage> history,
    required GenerationSettings settings,
    PromptPreset? preset,
    List<WorldBook> worldBooks = const [],
  }) {
    final system = _systemPrompt(character, persona, preset, worldBooks, history);
    return GenerationRequest(
      messages: history,
      model: preset?.model.isNotEmpty == true ? preset!.model : settings.model,
      temperature: preset?.temperature ?? settings.temperature,
      topP: preset?.topP ?? settings.topP,
      maxTokens: preset?.maxTokens ?? settings.maxTokens,
      repetitionPenalty: settings.repetitionPenalty,
      systemPrompt: system,
    );
  }

  static String _systemPrompt(CharacterProfile character, UserPersona persona, PromptPreset? preset, List<WorldBook> books, List<ChatMessage> history) {
    final recentText = history.reversed.take(8).map((message) => message.content).join('\n').toLowerCase();
    final matched = <WorldBookEntryModel>[];
    for (final book in books) {
      for (final entry in book.entries) {
        if (!entry.enabled) continue;
        final constant = entry.constant;
        final hit = entry.keys.any((key) => key.trim().isNotEmpty && recentText.contains(key.toLowerCase()));
        if (constant || hit) matched.add(entry);
      }
    }

    final card = character.card;
    final systemPrompt = card?.systemPrompt.isNotEmpty == true ? card!.systemPrompt : character.systemPrompt;
    final description = card?.description.isNotEmpty == true ? card!.description : character.description;
    final personality = card?.personality.isNotEmpty == true ? card!.personality : '';
    final scenario = card?.scenario.isNotEmpty == true ? card!.scenario : '';
    final postHistory = card?.postHistoryInstructions.isNotEmpty == true ? card!.postHistoryInstructions : '';
    final sections = <String>[
      if (preset?.systemPrompt.isNotEmpty == true) preset!.systemPrompt,
      if (systemPrompt.isNotEmpty) systemPrompt,
      '你正在扮演 ${character.name}。',
      if (description.isNotEmpty) '角色描述：\n$description',
      if (personality.isNotEmpty) '角色性格：\n$personality',
      if (scenario.isNotEmpty) '当前场景：\n$scenario',
      if (persona.name.isNotEmpty || persona.description.isNotEmpty) '用户 Persona：\n${persona.name}\n${persona.description}',
      if (matched.isNotEmpty) '已触发的世界书条目：\n${matched.map((entry) => entry.content).join('\n\n')}',
      if (postHistory.isNotEmpty) postHistory,
    ];
    return sections.join('\n\n');
  }
}
