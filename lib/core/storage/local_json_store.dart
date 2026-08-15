import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalJsonStore {
  const LocalJsonStore._();

  static Future<File> _file(String name) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$name.json');
  }

  static Future<Map<String, dynamic>?> read(String name) async {
    final file = await _file(name);
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String name, Map<String, dynamic> value) async {
    final file = await _file(name);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(value));
    await temporary.rename(file.path);
  }

  static Future<File> writeText(String name, String content) async {
    final file = await _file(name);
    await file.writeAsString(content);
    return file;
  }

  static Future<File> writeBytes(String name, List<int> bytes, {String extension = 'bin'}) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$name.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
