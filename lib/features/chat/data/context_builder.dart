import '../domain/chat_models.dart';
import '../domain/chat_workspace.dart';
import '../domain/generation.dart';
import '../../characters/domain/character_card.dart';
import '../../settings/domain/preset_models.dart';

class ContextInspection {
  const ContextInspection({required this.entries, required this.systemPrompt});
  final List<ContextEntry> entries;
  final String systemPrompt;
}

class ContextEntry {
  const ContextEntry({required this.source, required this.keys, required this.content, required this.constant, required this.position, this.role = 'system', this.depth = 0, this.order = 0});
  final String source;
  final List<String> keys;
  final String content;
  final bool constant;
  final String position;
  final String role;
  final int depth;
  final int order;
}

class ChatContextBuilder {
  const ChatContextBuilder._();

  static GenerationRequest build({required CharacterProfile character, required UserPersona persona, required List<ChatMessage> history, required GenerationSettings settings, PromptPreset? preset, List<WorldBook> worldBooks = const []}) {
    final inspection = inspect(character: character, persona: persona, history: history, preset: preset, worldBooks: worldBooks);
    return GenerationRequest(messages: history, model: preset?.model.isNotEmpty == true ? preset!.model : settings.model, temperature: preset?.temperature ?? settings.temperature, topP: preset?.topP ?? settings.topP, maxTokens: preset?.maxTokens ?? settings.maxTokens, repetitionPenalty: settings.repetitionPenalty, systemPrompt: inspection.systemPrompt);
  }

  static ContextInspection inspect({required CharacterProfile character, required UserPersona persona, required List<ChatMessage> history, PromptPreset? preset, List<WorldBook> worldBooks = const []}) {
    final recentText = history.reversed.take(8).map((message) => message.content).join('\n').toLowerCase();
    final card = character.card;
    final candidates = <ContextEntry>[
      if (preset != null) ...preset.enabledNodes.map((node) => ContextEntry(source: '预设 · ${node.name}', keys: const [], content: node.content, constant: true, position: 'preset:${node.injectionPosition}', role: node.role, depth: node.injectionDepth, order: node.injectionOrder)),
      ...?card?.characterBook?.entries.map((entry) => ContextEntry(source: '角色 Character Book', keys: entry.keys, content: entry.content, constant: entry.constant, position: entry.position)),
      for (final book in worldBooks) ...book.entries.map((entry) => ContextEntry(source: book.name, keys: entry.keys, content: entry.content, constant: entry.constant, position: entry.position)),
    ];
    final matched = <ContextEntry>[];
    final seen = <String>{};
    for (final entry in candidates) {
      if (entry.content.trim().isEmpty) continue;
      final hit = entry.source.startsWith('预设 · ') || entry.constant || entry.keys.any((key) => key.trim().isNotEmpty && recentText.contains(key.toLowerCase()));
      final signature = '${entry.position}|${entry.content}';
      if (hit && seen.add(signature)) matched.add(entry);
    }
    final byPosition = (String position) => matched.where((entry) => entry.position == position).map((entry) => entry.content).join('\n\n');
    final systemPrompt = card?.systemPrompt ?? '';
    final presetNodes = matched.where((entry) => entry.source.startsWith('预设 · ')).toList()..sort((a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.depth.compareTo(b.depth));
    final sections = <String>[
      if (preset?.systemPrompt.isNotEmpty == true) preset!.systemPrompt,
      if (presetNodes.isNotEmpty) '预设提示词节点：\n${presetNodes.map((entry) => '[${entry.role}] ${entry.content}').join('\n\n')}',
      if (systemPrompt.isNotEmpty) systemPrompt,
      if (byPosition('before_char').isNotEmpty) '世界书（角色定义前）：\n${byPosition('before_char')}',
      '你正在扮演 ${character.name}。',
      if (character.description.isNotEmpty) '角色描述：\n${character.description}',
      if (card?.personality.isNotEmpty == true) '角色性格：\n${card!.personality}',
      if (card?.scenario.isNotEmpty == true) '当前场景：\n${card!.scenario}',
      if (byPosition('after_char').isNotEmpty) '世界书（角色定义后）：\n${byPosition('after_char')}',
      '用户 Persona：\n${persona.name}\n${persona.description}',
      if (byPosition('before_example_messages').isNotEmpty) '世界书（示例消息前）：\n${byPosition('before_example_messages')}',
      if (card?.exampleMessages.isNotEmpty == true) '示例消息：\n${card!.exampleMessages}',
      if (byPosition('after_example_messages').isNotEmpty) '世界书（示例消息后）：\n${byPosition('after_example_messages')}',
      if (card?.postHistoryInstructions.isNotEmpty == true) card!.postHistoryInstructions,
    ];
    return ContextInspection(entries: matched, systemPrompt: sections.join('\n\n'));
  }
}
