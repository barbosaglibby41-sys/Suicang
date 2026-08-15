import 'dart:convert';
import 'dart:typed_data';
import '../domain/character_card.dart';

class CharacterCardExporter {
  const CharacterCardExporter._();

  static String toJsonText(CharacterCard card) {
    final data = {
      'name': card.name,
      'description': card.description,
      'personality': card.personality,
      'scenario': card.scenario,
      'first_mes': card.firstMessage,
      'mes_example': card.exampleMessages,
      'system_prompt': card.systemPrompt,
      'post_history_instructions': card.postHistoryInstructions,
      'alternate_greetings': card.alternateGreetings,
      'creator_notes': card.creatorNotes,
      'tags': card.tags,
      'extensions': card.extensions,
      if (card.characterBook != null) 'character_book': {
        'name': card.characterBook!.name,
        'entries': card.characterBook!.entries.map((entry) => {
              'uid': entry.id,
              'keys': entry.keys,
              'content': entry.content,
              'enabled': entry.enabled,
              'constant': entry.constant,
              'selective': entry.selective,
              'position': entry.position,
            }).toList(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert({'spec': 'chara_card_v2', 'spec_version': '2.0', 'data': data});
  }

  static Uint8List toPngCard(CharacterCard card) {
    final source = card.avatarData;
    if (source == null || source.isEmpty) throw const FormatException('该角色卡没有可复用的 PNG 头像');
    final bytes = base64Decode(source);
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8 || !_startsWith(bytes, signature)) throw const FormatException('头像不是有效的 PNG');
    final metadata = base64Encode(utf8.encode(toJsonText(card)));
    final output = BytesBuilder(copy: true)..add(bytes.sublist(0, 8));
    var offset = 8;
    while (offset + 12 <= bytes.length) {
      final length = _u32(bytes, offset);
      final end = offset + 12 + length;
      if (end > bytes.length) break;
      final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
      final data = bytes.sublist(offset + 8, offset + 8 + length);
      final isCharaText = (type == 'tEXt' || type == 'iTXt') && _keyword(data) == 'chara';
      if (!isCharaText && type != 'IEND') output.add(bytes.sublist(offset, end));
      if (type == 'IEND') {
        output.add(_textChunk('chara', metadata));
        output.add(bytes.sublist(offset, end));
        break;
      }
      offset = end;
    }
    return output.takeBytes();
  }

  static String? _keyword(Uint8List data) {
    final zero = data.indexOf(0);
    return zero > 0 ? ascii.decode(data.sublist(0, zero), allowInvalid: true) : null;
  }

  static Uint8List _textChunk(String keyword, String value) {
    final payload = Uint8List.fromList([...ascii.encode(keyword), 0, ...latin1.encode(value)]);
    final type = ascii.encode('tEXt');
    final crc = _crc32([...type, ...payload]);
    return Uint8List.fromList([..._u32Bytes(payload.length), ...type, ...payload, ..._u32Bytes(crc)]);
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) => prefix.asMap().entries.every((item) => bytes[item.key] == item.value);
  static int _u32(Uint8List bytes, int offset) => (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
  static List<int> _u32Bytes(int value) => [(value >> 24) & 255, (value >> 16) & 255, (value >> 8) & 255, value & 255];

  static int _crc32(List<int> bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}
