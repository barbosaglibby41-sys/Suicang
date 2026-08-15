import 'dart:convert';
import '../domain/preset_models.dart';

class PresetParser {
  const PresetParser._();

  static PromptPreset fromJsonText(String source,
      {String sourceName = '导入预设'}) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException('预设 JSON 根节点必须是对象');
    final json = Map<String, dynamic>.from(value);
    final extensions = json['extensions'] is Map
        ? Map<String, dynamic>.from(json['extensions'] as Map)
        : <String, dynamic>{};
    return PromptPreset(
        name: _string(json, 'name', fallback: sourceName),
        model: _string(json, 'model', fallback: _string(json, 'model_name')),
        temperature: _number(json, 'temperature', .8),
        topP: _number(json, 'top_p', .95),
        maxTokens:
            _int(json, 'max_tokens', _int(json, 'max_output_tokens', 2048)),
        systemPrompt:
            _string(json, 'system_prompt', fallback: _string(json, 'system')),
        source: sourceName,
        extensions: extensions);
  }

  static WorldBook fromJsonTextAsWorldBook(String source,
      {String sourceName = '导入世界书'}) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException('世界书 JSON 根节点必须是对象');
    final json = Map<String, dynamic>.from(value);
    final rawEntries = json['entries'] is List
        ? json['entries'] as List
        : json.values.whereType<Map>().toList();
    final entries = rawEntries
        .whereType<Map>()
        .map((entry) => WorldBookEntryModel(
            id: '${entry['uid'] ?? entry['id'] ?? rawEntries.indexOf(entry)}',
            keys: _strings(entry, 'keys', fallback: _strings(entry, 'key')),
            content: _string(entry, 'content'),
            enabled: entry['enabled'] != false,
            constant: entry['constant'] == true,
            selective: entry['selective'] != false,
            position: _string(entry, 'position', fallback: 'before_char'),
            extensions: entry['extensions'] is Map
                ? Map<String, dynamic>.from(entry['extensions'] as Map)
                : const {}))
        .toList();
    return WorldBook(
        name: _string(json, 'name', fallback: sourceName),
        entries: entries,
        source: sourceName);
  }

  static String _string(Map map, String key, {String fallback = ''}) =>
      map[key] is String && (map[key] as String).trim().isNotEmpty
          ? map[key] as String
          : fallback;
  static double _number(Map map, String key, double fallback) =>
      map[key] is num ? (map[key] as num).toDouble() : fallback;
  static int _int(Map map, String key, int fallback) =>
      map[key] is num ? (map[key] as num).round() : fallback;
  static List<String> _strings(Map map, String key,
          {List<String> fallback = const []}) =>
      map[key] is List
          ? (map[key] as List).whereType<String>().toList()
          : fallback;
}
