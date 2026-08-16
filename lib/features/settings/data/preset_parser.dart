import 'dart:convert';
import '../domain/preset_models.dart';

class PresetParser {
  const PresetParser._();

  static PromptPreset fromJsonText(String source, {String sourceName = '导入预设'}) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException('预设 JSON 根节点必须是对象');
    final json = Map<String, dynamic>.from(value);
    final rawPrompts = json['prompts'] is List ? json['prompts'] as List : const [];
    final nodes = rawPrompts.whereType<Map>().map((item) => _promptNode(Map<String, dynamic>.from(item))).toList();
    final rawOrder = json['prompt_order'] is List ? json['prompt_order'] as List : const [];
    final order = <String>[];
    for (final group in rawOrder.whereType<Map>()) {
      final items = group['order'];
      if (items is List) {
        order.addAll(items.whereType<Map>().where((item) => item['enabled'] != false).map((item) => item['identifier']).whereType<String>());
      }
    }
    final templates = <String, String>{};
    for (final key in ['impersonation_prompt', 'continue_nudge_prompt', 'group_nudge_prompt', 'wi_format', 'scenario_format', 'personality_format', 'send_if_empty', 'new_chat_prompt', 'new_group_chat_prompt', 'new_example_chat_prompt', 'assistant_prefill', 'assistant_impersonation', 'continue_postfix']) {
      if (json[key] is String) templates[key] = json[key] as String;
    }
    final extensions = Map<String, dynamic>.from(json);
    extensions.remove('prompts');
    extensions.remove('prompt_order');
    return PromptPreset(name: _string(json, 'name', fallback: sourceName), model: _string(json, 'model', fallback: _string(json, 'model_name')), temperature: _number(json, 'temperature', .8), topP: _number(json, 'top_p', .95), maxTokens: _int(json, 'max_tokens', _int(json, 'openai_max_tokens', _int(json, 'max_output_tokens', 2048))), systemPrompt: _string(json, 'system_prompt', fallback: _string(json, 'system')), source: sourceName, nodes: nodes, promptOrder: order, templates: templates, extensions: extensions);
  }

  static WorldBook fromJsonTextAsWorldBook(String source, {String sourceName = '导入世界书'}) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException('世界书 JSON 根节点必须是对象');
    final json = Map<String, dynamic>.from(value);
    final rawEntries = json['entries'] is List ? json['entries'] as List : json.values.whereType<Map>().toList();
    final entries = rawEntries.whereType<Map>().map((entry) => WorldBookEntryModel(id: '${entry['uid'] ?? entry['id'] ?? rawEntries.indexOf(entry)}', keys: _strings(entry, 'keys', fallback: _strings(entry, 'key')), content: _string(entry, 'content'), enabled: entry['enabled'] != false, constant: entry['constant'] == true, selective: entry['selective'] != false, position: _string(entry, 'position', fallback: 'before_char'), extensions: entry['extensions'] is Map ? Map<String, dynamic>.from(entry['extensions'] as Map) : const {})).toList();
    return WorldBook(name: _string(json, 'name', fallback: sourceName), entries: entries, source: sourceName);
  }

  static PromptNode _promptNode(Map<String, dynamic> value) => PromptNode(identifier: _string(value, 'identifier', fallback: 'node-${value.hashCode}'), name: _string(value, 'name', fallback: '未命名提示词'), content: _string(value, 'content'), enabled: value['enabled'] != false, role: _string(value, 'role', fallback: 'system'), injectionPosition: _int(value, 'injection_position', 0), injectionDepth: _int(value, 'injection_depth', 4), injectionOrder: _int(value, 'injection_order', 100), systemPrompt: value['system_prompt'] == true, marker: value['marker'] != false, forbidOverrides: value['forbid_overrides'] == true, extensions: Map<String, dynamic>.from(value));

  static String _string(Map map, String key, {String fallback = ''}) => map[key] is String && (map[key] as String).trim().isNotEmpty ? map[key] as String : fallback;
  static double _number(Map map, String key, double fallback) => map[key] is num ? (map[key] as num).toDouble() : fallback;
  static int _int(Map map, String key, int fallback) => map[key] is num ? (map[key] as num).round() : fallback;
  static List<String> _strings(Map map, String key, {List<String> fallback = const []}) => map[key] is List ? (map[key] as List).whereType<String>().toList() : fallback;
}
