enum PluginPermission { readContext, writeVariables, injectPrompt, modifyMessages, network, clipboard }

enum PluginEventType { messageReceived, messageSent, generationStarted, generationEnded, sessionChanged, variableChanged }

class PluginManifest {
  const PluginManifest({required this.id, required this.name, this.version = '1.0.0', this.permissions = const {}, this.enabled = true});
  final String id;
  final String name;
  final String version;
  final Set<PluginPermission> permissions;
  final bool enabled;
}

class PluginEvent {
  const PluginEvent({required this.type, required this.payload, this.sessionId});
  final PluginEventType type;
  final Map<String, dynamic> payload;
  final String? sessionId;
}

class PromptInjection {
  const PromptInjection({required this.pluginId, required this.content, this.priority = 0, this.position = 'system', this.enabled = true});
  final String pluginId;
  final String content;
  final int priority;
  final String position;
  final bool enabled;
}

class PluginWarning {
  const PluginWarning({required this.pluginId, required this.api, required this.message});
  final String pluginId;
  final String api;
  final String message;
}
