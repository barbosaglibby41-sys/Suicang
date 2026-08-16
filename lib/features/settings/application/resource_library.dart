import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_json_store.dart';
import '../domain/preset_models.dart';

final resourceLibraryProvider = NotifierProvider<ResourceLibraryController, ResourceLibrary>(ResourceLibraryController.new);

class ResourceLibrary {
  const ResourceLibrary({this.preset = const PromptPreset(name: '默认创作', model: 'Claude'), this.worldBooks = const []});
  final PromptPreset preset;
  final List<WorldBook> worldBooks;
  ResourceLibrary copyWith({PromptPreset? preset, List<WorldBook>? worldBooks}) => ResourceLibrary(preset: preset ?? this.preset, worldBooks: worldBooks ?? this.worldBooks);
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
    final preset = presetJson is Map ? _presetFromJson(Map<String, dynamic>.from(presetJson)) : state.preset;
    final books = booksJson is List ? booksJson.whereType<Map>().map((item) => _bookFromJson(Map<String, dynamic>.from(item))).toList() : state.worldBooks;
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

  void updateWorldBook(WorldBook book) {
    final books = state.worldBooks.map((item) => item.name == book.name ? book : item).toList();
    state = state.copyWith(worldBooks: books);
    _persist();
  }

  void removeWorldBook(WorldBook book) {
    state = state.copyWith(worldBooks: state.worldBooks.where((item) => item.name != book.name).toList());
    _persist();
  }

  void updateWorldBookEntry(WorldBook book, WorldBookEntryModel entry) {
    final updated = book.entries.map((item) => item.id == entry.id ? entry : item).toList();
    updateWorldBook(WorldBook(name: book.name, entries: updated, source: book.source));
  }

  void removeWorldBookEntry(WorldBook book, WorldBookEntryModel entry) {
    updateWorldBook(WorldBook(name: book.name, entries: book.entries.where((item) => item.id != entry.id).toList(), source: book.source));
  }

  void reorderWorldBookEntry(WorldBook book, int oldIndex, int newIndex) {
    final entries = [...book.entries];
    if (oldIndex < newIndex) newIndex -= 1;
    final entry = entries.removeAt(oldIndex);
    entries.insert(newIndex, entry);
    updateWorldBook(WorldBook(name: book.name, entries: entries, source: book.source));
  }

  Future<void> _persist() => LocalJsonStore.write('resource_library', {'preset': _presetJson(state.preset), 'worldBooks': state.worldBooks.map(_bookJson).toList()});

  static Map<String, dynamic> _presetJson(PromptPreset value) => {'name': value.name, 'model': value.model, 'temperature': value.temperature, 'top_p': value.topP, 'max_tokens': value.maxTokens, 'system_prompt': value.systemPrompt, 'source': value.source, 'templates': value.templates, 'prompt_order': value.promptOrder, 'prompts': value.nodes.map((node) => {'identifier': node.identifier, 'name': node.name, 'content': node.content, 'enabled': node.enabled, 'role': node.role, 'injection_position': node.injectionPosition, 'injection_depth': node.injectionDepth, 'injection_order': node.injectionOrder, 'system_prompt': node.systemPrompt, 'marker': node.marker, 'forbid_overrides': node.forbidOverrides, ...node.extensions}).toList(), 'extensions': value.extensions};
  static PromptPreset _presetFromJson(Map<String, dynamic> value) => PromptPreset(name: value['name'] as String? ?? '默认创作', model: value['model'] as String? ?? '', temperature: (value['temperature'] as num?)?.toDouble() ?? .8, topP: (value['top_p'] as num?)?.toDouble() ?? .95, maxTokens: (value['max_tokens'] as num?)?.toInt() ?? 2048, systemPrompt: value['system_prompt'] as String? ?? '', source: value['source'] as String? ?? '本地预设', templates: value['templates'] is Map ? Map<String, String>.from((value['templates'] as Map).map((key, item) => MapEntry(key.toString(), item.toString()))) : const {}, promptOrder: value['prompt_order'] is List ? (value['prompt_order'] as List).whereType<String>().toList() : const [], nodes: value['prompts'] is List ? (value['prompts'] as List).whereType<Map>().map((item) { final node = Map<String, dynamic>.from(item); return PromptNode(identifier: node['identifier'] as String? ?? '', name: node['name'] as String? ?? '未命名提示词', content: node['content'] as String? ?? '', enabled: node['enabled'] != false, role: node['role'] as String? ?? 'system', injectionPosition: (node['injection_position'] as num?)?.toInt() ?? 0, injectionDepth: (node['injection_depth'] as num?)?.toInt() ?? 4, injectionOrder: (node['injection_order'] as num?)?.toInt() ?? 100, systemPrompt: node['system_prompt'] == true, marker: node['marker'] != false, forbidOverrides: node['forbid_overrides'] == true, extensions: node); }).toList() : const [], extensions: value['extensions'] is Map ? Map<String, dynamic>.from(value['extensions'] as Map) : const {});
  static Map<String, dynamic> _bookJson(WorldBook book) => {'name': book.name, 'source': book.source, 'entries': book.entries.map((entry) => {'id': entry.id, 'keys': entry.keys, 'content': entry.content, 'enabled': entry.enabled, 'constant': entry.constant, 'selective': entry.selective, 'position': entry.position, 'extensions': entry.extensions}).toList()};
  static WorldBook _bookFromJson(Map<String, dynamic> value) => WorldBook(name: value['name'] as String? ?? '未命名世界书', source: value['source'] as String? ?? '本地世界书', entries: value['entries'] is List ? (value['entries'] as List).whereType<Map>().map((entry) => WorldBookEntryModel(id: entry['id'] as String? ?? '', keys: entry['keys'] is List ? (entry['keys'] as List).whereType<String>().toList() : const [], content: entry['content'] as String? ?? '', enabled: entry['enabled'] != false, constant: entry['constant'] == true, selective: entry['selective'] != false, position: entry['position'] as String? ?? 'before_char', extensions: entry['extensions'] is Map ? Map<String, dynamic>.from(entry['extensions'] as Map) : const {})).toList() : const []);
}
