class CharacterCard {
  const CharacterCard({
    required this.id,
    required this.name,
    required this.tagline,
    required this.avatar,
    required this.description,
    this.avatarData,
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.exampleMessages = '',
    this.systemPrompt = '',
    this.postHistoryInstructions = '',
    this.alternateGreetings = const [],
    this.creatorNotes = '',
    this.characterBook,
    this.extensions = const {},
    this.source = '本地角色卡',
    this.tags = const [],
  });

  final String id;
  final String name;
  final String tagline;
  final String avatar;
  final String? avatarData;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final String exampleMessages;
  final String systemPrompt;
  final String postHistoryInstructions;
  final List<String> alternateGreetings;
  final String creatorNotes;
  final CharacterBook? characterBook;
  final Map<String, dynamic> extensions;
  final String source;
  final List<String> tags;

  CharacterCard copyWith(
          {String? name,
          String? tagline,
          String? avatar,
          String? avatarData,
          String? description,
          String? personality,
          String? scenario,
          String? firstMessage,
          String? exampleMessages,
          String? systemPrompt,
          String? postHistoryInstructions,
          List<String>? alternateGreetings,
          String? creatorNotes,
          CharacterBook? characterBook,
          Map<String, dynamic>? extensions,
          String? source,
          List<String>? tags,
          bool clearCharacterBook = false}) =>
      CharacterCard(
        id: id,
        name: name ?? this.name,
        tagline: tagline ?? this.tagline,
        avatar: avatar ?? this.avatar,
        avatarData: avatarData ?? this.avatarData,
        description: description ?? this.description,
        personality: personality ?? this.personality,
        scenario: scenario ?? this.scenario,
        firstMessage: firstMessage ?? this.firstMessage,
        exampleMessages: exampleMessages ?? this.exampleMessages,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        postHistoryInstructions:
            postHistoryInstructions ?? this.postHistoryInstructions,
        alternateGreetings: alternateGreetings ?? this.alternateGreetings,
        creatorNotes: creatorNotes ?? this.creatorNotes,
        characterBook:
            clearCharacterBook ? null : characterBook ?? this.characterBook,
        extensions: extensions ?? this.extensions,
        source: source ?? this.source,
        tags: tags ?? this.tags,
      );
}

class CharacterBook {
  const CharacterBook({required this.name, required this.entries});
  final String name;
  final List<WorldBookEntry> entries;
}

class WorldBookEntry {
  const WorldBookEntry(
      {required this.id,
      required this.keys,
      required this.content,
      this.constant = false,
      this.selective = true,
      this.enabled = true,
      this.position = 'before_char'});
  final String id;
  final List<String> keys;
  final String content;
  final bool constant;
  final bool selective;
  final bool enabled;
  final String position;
}
