import 'dart:convert';
import '../domain/preset_models.dart';

class PresetExporter {
  const PresetExporter._();

  static String toJsonText(PromptPreset preset) {
    final data = <String, dynamic>{...preset.extensions};
    data['name'] = preset.name;
    data['model'] = preset.model;
    data['temperature'] = preset.temperature;
    data['top_p'] = preset.topP;
    data['max_tokens'] = preset.maxTokens;
    data['system_prompt'] = preset.systemPrompt;
    data['prompts'] = preset.nodes.map((node) => <String, dynamic>{...node.extensions, 'identifier': node.identifier, 'name': node.name, 'content': node.content, 'enabled': node.enabled, 'role': node.role, 'injection_position': node.injectionPosition, 'injection_depth': node.injectionDepth, 'injection_order': node.injectionOrder, 'system_prompt': node.systemPrompt, 'marker': node.marker, 'forbid_overrides': node.forbidOverrides}).toList();
    data['prompt_order'] = [
      {'character_id': 100001, 'order': preset.promptOrder.map((id) => {'identifier': id, 'enabled': preset.nodes.any((node) => node.identifier == id && node.enabled)}).toList()},
    ];
    data.addAll(preset.templates);
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
