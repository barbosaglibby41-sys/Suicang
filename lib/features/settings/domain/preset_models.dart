class PromptPreset {
  const PromptPreset(
      {required this.name,
      this.model = '',
      this.temperature = .8,
      this.topP = .95,
      this.maxTokens = 2048,
      this.systemPrompt = '',
      this.source = '本地预设',
      this.extensions = const {}});

  final String name;
  final String model;
  final double temperature;
  final double topP;
  final int maxTokens;
  final String systemPrompt;
  final String source;
  final Map<String, dynamic> extensions;
}

class WorldBook {
  const WorldBook(
      {required this.name, required this.entries, this.source = '本地世界书'});
  final String name;
  final List<WorldBookEntryModel> entries;
  final String source;
}

class WorldBookEntryModel {
  const WorldBookEntryModel(
      {required this.id,
      required this.keys,
      required this.content,
      this.enabled = true,
      this.constant = false,
      this.selective = true,
      this.position = 'before_char',
      this.extensions = const {}});
  final String id;
  final List<String> keys;
  final String content;
  final bool enabled;
  final bool constant;
  final bool selective;
  final String position;
  final Map<String, dynamic> extensions;
}
