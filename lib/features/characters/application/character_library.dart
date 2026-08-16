import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_json_store.dart';
import '../domain/character_card.dart';

final characterLibraryProvider =
    NotifierProvider<CharacterLibraryController, List<CharacterCard>>(
        CharacterLibraryController.new);

class CharacterLibraryController extends Notifier<List<CharacterCard>> {
  @override
  List<CharacterCard> build() {
    _load();
    return _defaults;
  }

  static const _defaults = [
    CharacterCard(
        id: 'luna',
        name: 'Luna',
        tagline: '月光下的旅人',
        avatar: '🌙',
        description: '一位在旧城边缘旅行的神秘旅人。她相信每一盏灯都替某个人保留着回家的方向。',
        source: 'SillyTavern 角色卡',
        tags: ['幻想', '叙事']),
    CharacterCard(
        id: 'aria',
        name: 'Aria',
        tagline: '星海观测者',
        avatar: '🦋',
        description: '来自远方观测站的记录员，习惯把每段相遇写进星图。',
        source: '本地角色卡',
        tags: ['科幻', '陪伴']),
    CharacterCard(
        id: 'nova',
        name: 'Nova',
        tagline: '温柔的实验助手',
        avatar: '🤖',
        description: '一台正在学习人类情绪的实验型助手。',
        source: 'SillyTavern JSON',
        tags: ['助手', '创作']),
    CharacterCard(
        id: 'mori',
        name: 'Mori',
        tagline: '雨夜电台主持人',
        avatar: '🌧️',
        description: '在午夜电台读信，擅长把普通人的故事讲得很动人。',
        source: '本地角色卡',
        tags: ['治愈', '故事']),
  ];

  Future<void> _load() async {
    final json = await LocalJsonStore.read('character_library');
    final raw = json?['characters'];
    if (raw is! List || raw.isEmpty) return;
    final cards = raw
        .whereType<Map>()
        .map((item) => _fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (cards.isNotEmpty) state = cards;
  }

  void upsert(CharacterCard card) {
    state = [card, ...state.where((item) => item.id != card.id)];
    _persist();
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
    _persist();
  }

  Future<void> _persist() => LocalJsonStore.write(
      'character_library', {'characters': state.map(_toJson).toList()});

  static Map<String, dynamic> _toJson(CharacterCard card) => {
        'id': card.id,
        'name': card.name,
        'tagline': card.tagline,
        'avatar': card.avatar,
        'avatar_data': card.avatarData,
        'description': card.description,
        'personality': card.personality,
        'scenario': card.scenario,
        'first_mes': card.firstMessage,
        'mes_example': card.exampleMessages,
        'system_prompt': card.systemPrompt,
        'post_history_instructions': card.postHistoryInstructions,
        'alternate_greetings': card.alternateGreetings,
        'creator_notes': card.creatorNotes,
        'source': card.source,
        'tags': card.tags,
        'extensions': card.extensions,
        'character_book': card.characterBook == null
            ? null
            : {
                'name': card.characterBook!.name,
                'entries': card.characterBook!.entries
                    .map((entry) => {
                          'id': entry.id,
                          'keys': entry.keys,
                          'content': entry.content,
                          'constant': entry.constant,
                          'selective': entry.selective,
                          'enabled': entry.enabled,
                          'position': entry.position
                        })
                    .toList()
              }
      };

  static CharacterCard _fromJson(Map<String, dynamic> value) {
    final book = value['character_book'];
    return CharacterCard(
        id: value['id'] as String? ?? '',
        name: value['name'] as String? ?? '未命名角色',
        tagline: value['tagline'] as String? ?? '',
        avatar: value['avatar'] as String? ?? '✨',
        avatarData: value['avatar_data'] as String?,
        description: value['description'] as String? ?? '',
        personality: value['personality'] as String? ?? '',
        scenario: value['scenario'] as String? ?? '',
        firstMessage: value['first_mes'] as String? ?? '',
        exampleMessages: value['mes_example'] as String? ?? '',
        systemPrompt: value['system_prompt'] as String? ?? '',
        postHistoryInstructions:
            value['post_history_instructions'] as String? ?? '',
        alternateGreetings: value['alternate_greetings'] is List
            ? (value['alternate_greetings'] as List)
                .whereType<String>()
                .toList()
            : const [],
        creatorNotes: value['creator_notes'] as String? ?? '',
        source: value['source'] as String? ?? '本地角色卡',
        tags: value['tags'] is List
            ? (value['tags'] as List).whereType<String>().toList()
            : const [],
        extensions: value['extensions'] is Map
            ? Map<String, dynamic>.from(value['extensions'] as Map)
            : const {},
        characterBook: book is Map
            ? CharacterBook(
                name: book['name'] as String? ?? 'Character Book',
                entries: book['entries'] is List
                    ? (book['entries'] as List)
                        .whereType<Map>()
                        .map((entry) => WorldBookEntry(
                            id: entry['id'] as String? ?? '',
                            keys: entry['keys'] is List
                                ? (entry['keys'] as List)
                                    .whereType<String>()
                                    .toList()
                                : const [],
                            content: entry['content'] as String? ?? '',
                            constant: entry['constant'] == true,
                            selective: entry['selective'] != false,
                            enabled: entry['enabled'] != false,
                            position:
                                entry['position'] as String? ?? 'before_char'))
                        .toList()
                    : const [])
            : null);
  }
}
