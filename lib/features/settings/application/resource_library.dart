import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_json_store.dart';
import '../domain/preset_models.dart';

final resourceLibraryProvider =
    NotifierProvider<ResourceLibraryController, ResourceLibrary>(
        ResourceLibraryController.new);

class ResourceLibrary {
  const ResourceLibrary(
      {this.preset = const PromptPreset(name: '默认创作', model: 'Claude'),
      this.worldBooks = const []});
  final PromptPreset preset;
  final List<WorldBook> worldBooks;
  ResourceLibrary copyWith(
          {PromptPreset? preset, List<WorldBook>? worldBooks}) =>
      ResourceLibrary(
          preset: preset ?? this.preset,
          worldBooks: worldBooks ?? this.worldBooks);
}

class ResourceLibraryController extends Notifier<ResourceLibrary> {
  @override
  ResourceLibrary build() {
    _load();
    return const ResourceLibrary();
  }

  Future<void> _load() async {
    final json = await LocalJsonStore.read('resource_library');
    if (json == null) return;
    final presetJson = json['preset'];
    final booksJson = json['worldBooks'];
    final preset = presetJson is Map
        ? _presetFromJson(Map<String, dynamic>.from(presetJson))
        : state.preset;
    final books = booksJson is List
        ? booksJson
            .whereType<Map>()
            .map((item) => _bookFromJson(Map<String, dynamic>.from(item)))
            .toList()
        : state.worldBooks;
    state = state.copyWith(preset: preset, worldBooks: books);
  }

  void setPreset(PromptPreset preset) {
    state = state.copyWith(preset: preset);
    _persist();
  }

  void addWorldBook(WorldBook book) {
    state = state.copyWith(worldBooks: [book, ...state.worldBooks]);
    _persist();
  }

  Future<void> _persist() => LocalJsonStore.write('resource_library', {
        'preset': _presetJson(state.preset),
        'worldBooks': state.worldBooks.map(_bookJson).toList()
      });

  static Map<String, dynamic> _presetJson(PromptPreset value) => {
        'name': value.name,
        'model': value.model,
        'temperature': value.temperature,
        'top_p': value.topP,
        'max_tokens': value.maxTokens,
        'system_prompt': value.systemPrompt,
        'source': value.source,
        'extensions': value.extensions
      };
  static PromptPreset _presetFromJson(Map<String, dynamic> value) =>
      PromptPreset(
          name: value['name'] as String? ?? '默认创作',
          model: value['model'] as String? ?? '',
          temperature: (value['temperature'] as num?)?.toDouble() ?? .8,
          topP: (value['top_p'] as num?)?.toDouble() ?? .95,
          maxTokens: (value['max_tokens'] as num?)?.toInt() ?? 2048,
          systemPrompt: value['system_prompt'] as String? ?? '',
          source: value['source'] as String? ?? '本地预设',
          extensions: value['extensions'] is Map
              ? Map<String, dynamic>.from(value['extensions'] as Map)
              : const {});
  static Map<String, dynamic> _bookJson(WorldBook book) => {
        'name': book.name,
        'source': book.source,
        'entries': book.entries
            .map((entry) => {
                  'id': entry.id,
                  'keys': entry.keys,
                  'content': entry.content,
                  'enabled': entry.enabled,
                  'constant': entry.constant,
                  'selective': entry.selective,
                  'position': entry.position,
                  'extensions': entry.extensions
                })
            .toList()
      };
  static WorldBook _bookFromJson(Map<String, dynamic> value) => WorldBook(
      name: value['name'] as String? ?? '未命名世界书',
      source: value['source'] as String? ?? '本地世界书',
      entries: value['entries'] is List
          ? (value['entries'] as List)
              .whereType<Map>()
              .map((entry) => WorldBookEntryModel(
                  id: entry['id'] as String? ?? '',
                  keys: entry['keys'] is List
                      ? (entry['keys'] as List).whereType<String>().toList()
                      : const [],
                  content: entry['content'] as String? ?? '',
                  enabled: entry['enabled'] != false,
                  constant: entry['constant'] == true,
                  selective: entry['selective'] != false,
                  position: entry['position'] as String? ?? 'before_char',
                  extensions: entry['extensions'] is Map
                      ? Map<String, dynamic>.from(entry['extensions'] as Map)
                      : const {}))
              .toList()
          : const []);
}
