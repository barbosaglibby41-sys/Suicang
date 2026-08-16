import 'dart:convert';
import 'dart:typed_data';
import '../domain/character_card.dart';

class CharacterCardParser {
  const CharacterCardParser._();

  static CharacterCard fromJsonText(String source,
      {String sourceName = '导入角色卡', String? avatarData}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>)
      throw const FormatException('角色卡 JSON 根节点必须是对象');
    return fromJson(decoded, sourceName: sourceName, avatarData: avatarData);
  }

  static CharacterCard fromPng(Uint8List bytes,
      {String sourceName = 'PNG 社区角色卡'}) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8 || !_startsWith(bytes, signature))
      throw const FormatException('不是有效的 PNG 文件');
    var offset = 8;
    while (offset + 12 <= bytes.length) {
      final length = _u32(bytes, offset);
      final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
      final dataStart = offset + 8;
      final dataEnd = dataStart + length;
      if (dataEnd + 4 > bytes.length) break;
      final data = bytes.sublist(dataStart, dataEnd);
      if (type == 'tEXt') {
        final split = data.indexOf(0);
        if (split > 0) {
          final keyword = ascii.decode(data.sublist(0, split));
          final value =
              latin1.decode(data.sublist(split + 1), allowInvalid: true);
          if (keyword == 'chara')
            return fromJsonText(utf8.decode(base64.decode(value.trim())),
                sourceName: sourceName, avatarData: base64Encode(bytes));
        }
      } else if (type == 'iTXt') {
        final zero = data.indexOf(0);
        if (zero > 0 && ascii.decode(data.sublist(0, zero)) == 'chara') {
          final textStart = _iTextPayloadStart(data, zero);
          if (textStart != null) {
            final value = utf8.decode(data.sublist(textStart));
            return fromJsonText(utf8.decode(base64.decode(value.trim())),
                sourceName: sourceName, avatarData: base64Encode(bytes));
          }
        }
      }
      offset = dataEnd + 4;
    }
    throw const FormatException('PNG 中没有找到 chara 角色卡元数据');
  }

  static CharacterCard fromJson(Map<String, dynamic> json,
      {String sourceName = '导入角色卡', String? avatarData}) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final name = _string(data, 'name', fallback: '未命名角色');
    return CharacterCard(
      id: 'imported-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      tagline: _string(data, 'creator_notes', fallback: '社区角色卡'),
      avatar: '✨',
      avatarData: avatarData,
      description: _string(data, 'description'),
      personality: _string(data, 'personality'),
      scenario: _string(data, 'scenario'),
      firstMessage:
          _string(data, 'first_mes', fallback: _string(data, 'first_message')),
      exampleMessages: _string(data, 'mes_example',
          fallback: _string(data, 'example_messages')),
      systemPrompt: _string(data, 'system_prompt'),
      postHistoryInstructions: _string(data, 'post_history_instructions'),
      alternateGreetings: _strings(data, 'alternate_greetings'),
      creatorNotes: _string(data, 'creator_notes'),
      characterBook: _book(data['character_book']),
      extensions: data['extensions'] is Map
          ? Map<String, dynamic>.from(data['extensions'] as Map)
          : <String, dynamic>{},
      source: sourceName,
      tags: _strings(data, 'tags'),
    );
  }

  static String _string(Map<String, dynamic> map, String key,
          {String fallback = ''}) =>
      map[key] is String && (map[key] as String).trim().isNotEmpty
          ? map[key] as String
          : fallback;

  static List<String> _strings(Map<String, dynamic> map, String key) =>
      map[key] is List
          ? (map[key] as List)
              .whereType<String>()
              .where((item) => item.trim().isNotEmpty)
              .toList()
          : const [];

  static CharacterBook? _book(dynamic value) {
    if (value is! Map || value['entries'] is! List) return null;
    final entries = value['entries'] as List;
    return CharacterBook(
        name: value['name'] is String
            ? value['name'] as String
            : 'Character Book',
        entries: entries
            .whereType<Map>()
            .map((entry) => WorldBookEntry(
                id: '${entry['uid'] ?? entry['id'] ?? entries.indexOf(entry)}',
                keys: entry['keys'] is List
                    ? (entry['keys'] as List).whereType<String>().toList()
                    : const [],
                content: entry['content'] is String
                    ? entry['content'] as String
                    : '',
                constant: entry['constant'] == true,
                selective: entry['selective'] != false,
                enabled: entry['enabled'] != false,
                position: entry['position'] is String
                    ? entry['position'] as String
                    : 'before_char'))
            .toList());
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) =>
      prefix.asMap().entries.every((item) => bytes[item.key] == item.value);
  static int _u32(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  static int? _iTextPayloadStart(Uint8List data, int keywordEnd) {
    var cursor = keywordEnd + 1;
    final languageEnd = data.indexOf(0, cursor);
    if (languageEnd < 0) return null;
    cursor = languageEnd + 1;
    final translatedEnd = data.indexOf(0, cursor);
    if (translatedEnd < 0 || cursor + 1 >= data.length) return null;
    cursor = translatedEnd + 1;
    final compressionFlag = data[cursor++];
    cursor++;
    if (compressionFlag != 0) return null;
    final textEnd = data.indexOf(0, cursor);
    return textEnd < 0 ? null : textEnd + 1;
  }
}
