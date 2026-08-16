import 'dart:async';
import '../domain/plugin_models.dart';

class PluginRuntime {
  PluginRuntime({this.onWarning});
  final void Function(PluginWarning warning)? onWarning;
  final _events = StreamController<PluginEvent>.broadcast();
  final _manifests = <String, PluginManifest>{};
  final _variables = <String, Map<String, dynamic>>{};
  final _injections = <String, List<PromptInjection>>{};
  final _subscriptions = <String, List<StreamSubscription<PluginEvent>>>{};

  Stream<PluginEvent> get events => _events.stream;
  List<PluginManifest> get plugins => List.unmodifiable(_manifests.values);

  void register(PluginManifest manifest) {
    _manifests[manifest.id] = manifest;
    _variables.putIfAbsent(manifest.id, () => <String, dynamic>{});
  }

  void unregister(String pluginId) {
    for (final subscription in _subscriptions.remove(pluginId) ?? const <StreamSubscription<PluginEvent>>[]) {
      subscription.cancel();
    }
    _manifests.remove(pluginId);
    _variables.remove(pluginId);
    _injections.remove(pluginId);
  }

  StreamSubscription<PluginEvent> eventOn(String pluginId, PluginEventType type, void Function(PluginEvent event) callback) {
    final subscription = events.where((event) => event.type == type).listen(callback);
    _subscriptions.putIfAbsent(pluginId, () => []).add(subscription);
    return subscription;
  }

  void eventEmit(String pluginId, PluginEvent event) {
    if (!_can(pluginId, PluginPermission.readContext)) return;
    _events.add(event);
  }

  dynamic getVariable(String pluginId, String key) => _variables[pluginId]?[key];

  void setVariable(String pluginId, String key, dynamic value) {
    if (!_can(pluginId, PluginPermission.writeVariables)) return;
    _variables.putIfAbsent(pluginId, () => <String, dynamic>{})[key] = value;
    _events.add(PluginEvent(type: PluginEventType.variableChanged, payload: {'key': key, 'value': value}));
  }

  void setPromptInjection(PromptInjection injection) {
    if (!_can(injection.pluginId, PluginPermission.injectPrompt)) return;
    final list = _injections.putIfAbsent(injection.pluginId, () => []);
    list.removeWhere((item) => item.position == injection.position);
    list.add(injection);
  }

  List<PromptInjection> promptInjections() => _injections.values.expand((items) => items).where((item) => item.enabled && _can(item.pluginId, PluginPermission.injectPrompt)).toList()..sort((a, b) => a.priority.compareTo(b.priority));

  bool _can(String pluginId, PluginPermission permission) {
    final manifest = _manifests[pluginId];
    if (manifest == null || !manifest.enabled || !manifest.permissions.contains(permission)) {
      onWarning?.call(PluginWarning(pluginId: pluginId, api: permission.name, message: '插件未声明或未获准使用此能力'));
      return false;
    }
    return true;
  }

  Future<void> dispose() async {
    for (final subscriptions in _subscriptions.values) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    await _events.close();
  }
}
