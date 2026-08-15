import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final providerConfigProvider = NotifierProvider<ProviderConfigController, ProviderConfig>(ProviderConfigController.new);

class ProviderConfig {
  const ProviderConfig({this.baseUrl = '', this.model = '', this.apiKey = '', this.enabled = false});
  final String baseUrl;
  final String model;
  final String apiKey;
  final bool enabled;

  bool get isReady => enabled && baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty && model.trim().isNotEmpty;
  ProviderConfig copyWith({String? baseUrl, String? model, String? apiKey, bool? enabled}) => ProviderConfig(baseUrl: baseUrl ?? this.baseUrl, model: model ?? this.model, apiKey: apiKey ?? this.apiKey, enabled: enabled ?? this.enabled);
}

class ProviderConfigController extends Notifier<ProviderConfig> {
  static const _storage = FlutterSecureStorage();

  @override
  ProviderConfig build() {
    _load();
    return const ProviderConfig();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      _storage.read(key: 'provider.base_url'),
      _storage.read(key: 'provider.model'),
      _storage.read(key: 'provider.api_key'),
      _storage.read(key: 'provider.enabled'),
    ]);
    state = ProviderConfig(baseUrl: values[0] ?? '', model: values[1] ?? '', apiKey: values[2] ?? '', enabled: values[3] == 'true');
  }

  void update(ProviderConfig next) {
    state = next;
    _persist(next);
  }

  void setConnection({required String baseUrl, required String model, required String apiKey, required bool enabled}) => update(ProviderConfig(baseUrl: baseUrl, model: model, apiKey: apiKey, enabled: enabled));

  Future<void> _persist(ProviderConfig config) async {
    await Future.wait([
      _storage.write(key: 'provider.base_url', value: config.baseUrl),
      _storage.write(key: 'provider.model', value: config.model),
      _storage.write(key: 'provider.api_key', value: config.apiKey),
      _storage.write(key: 'provider.enabled', value: config.enabled.toString()),
    ]);
  }
}
