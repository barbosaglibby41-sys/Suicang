class PromptNode {
  const PromptNode({required this.identifier, required this.name, required this.content, this.enabled = true, this.role = 'system', this.injectionPosition = 0, this.injectionDepth = 4, this.injectionOrder = 100, this.systemPrompt = false, this.marker = true, this.forbidOverrides = false, this.extensions = const {}});

  final String identifier;
  final String name;
  final String content;
  final bool enabled;
  final String role;
  final int injectionPosition;
  final int injectionDepth;
  final int injectionOrder;
  final bool systemPrompt;
  final bool marker;
  final bool forbidOverrides;
  final Map<String, dynamic> extensions;

  PromptNode copyWith({String? name, String? content, bool? enabled, String? role, int? injectionPosition, int? injectionDepth, int? injectionOrder}) => PromptNode(identifier: identifier, name: name ?? this.name, content: content ?? this.content, enabled: enabled ?? this.enabled, role: role ?? this.role, injectionPosition: injectionPosition ?? this.injectionPosition, injectionDepth: injectionDepth ?? this.injectionDepth, injectionOrder: injectionOrder ?? this.injectionOrder, systemPrompt: systemPrompt, marker: marker, forbidOverrides: forbidOverrides, extensions: extensions);
}

class PromptPreset {
  const PromptPreset({required this.name, this.model = '', this.temperature = .8, this.topP = .95, this.maxTokens = 2048, this.systemPrompt = '', this.source = '本地预设', this.nodes = const [], this.promptOrder = const [], this.templates = const {}, this.extensions = const {}});

  final String name;
  final String model;
  final double temperature;
  final double topP;
  final int maxTokens;
  final String systemPrompt;
  final String source;
  final List<PromptNode> nodes;
  final List<String> promptOrder;
  final Map<String, String> templates;
  final Map<String, dynamic> extensions;

  List<PromptNode> get enabledNodes {
    final byId = {for (final node in nodes) node.identifier: node};
    final ordered = <PromptNode>[];
    for (final id in promptOrder) {
      final node = byId[id];
      if (node != null && node.enabled) ordered.add(node);
    }
    for (final node in nodes) {
      if (node.enabled && !ordered.any((item) => item.identifier == node.identifier)) ordered.add(node);
    }
    return ordered;
  }
}

class WorldBook {
  const WorldBook({required this.name, required this.entries, this.source = '本地世界书'});
  final String name;
  final List<WorldBookEntryModel> entries;
  final String source;
}

class WorldBookEntryModel {
  const WorldBookEntryModel({required this.id, required this.keys, required this.content, this.enabled = true, this.constant = false, this.selective = true, this.position = 'before_char', this.extensions = const {}});
  final String id;
  final List<String> keys;
  final String content;
  final bool enabled;
  final bool constant;
  final bool selective;
  final String position;
  final Map<String, dynamic> extensions;
}
