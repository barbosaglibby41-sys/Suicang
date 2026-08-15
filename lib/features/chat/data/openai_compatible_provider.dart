import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/generation.dart';

class OpenAiCompatibleProvider implements LlmProvider {
  OpenAiCompatibleProvider({required this.baseUrl, required this.apiKey, Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), sendTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(minutes: 5)));

  final String baseUrl;
  final String apiKey;
  final Dio _dio;

  Future<String> testConnection({String? model}) async {
    try {
      final response = await _dio.get<dynamic>(
        '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey', 'Accept': 'application/json'}),
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) return '连接成功${model == null || model.isEmpty ? '' : ' · $model'}';
      throw Exception('HTTP ${response.statusCode}');
    } on DioException catch (error) {
      throw Exception(error.response?.statusMessage ?? error.message ?? '连接失败');
    }
  }

  @override
  Stream<GenerationEvent> generate(GenerationRequest request) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/chat/completions',
        data: jsonEncode({
          'model': request.model,
          'stream': true,
          'temperature': request.temperature,
          'top_p': request.topP,
          'max_tokens': request.maxTokens,
          'repetition_penalty': request.repetitionPenalty,
          'messages': [
            if (request.systemPrompt != null) {'role': 'system', 'content': request.systemPrompt},
            ...request.messages.map((message) => {'role': message.role.name, 'content': message.content}),
          ],
        }),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json', 'Accept': 'text/event-stream'},
        ),
      );
      final stream = response.data?.stream;
      if (stream == null) { yield const GenerationFailed('模型没有返回数据'); return; }
      var buffer = '';
      await for (final bytes in stream) {
        buffer += utf8.decode(bytes, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload == '[DONE]') { yield const GenerationCompleted(); continue; }
          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            final choices = json['choices'];
            final first = choices is List && choices.isNotEmpty ? choices.first : null;
            final delta = first is Map ? ((first['delta'] as Map?)?['content']) : null;
            if (delta is String && delta.isNotEmpty) yield TextDelta(delta);
          } catch (_) {
            // Ignore incomplete SSE frames; the next chunk completes them.
          }
        }
      }
    } on DioException catch (error) {
      yield GenerationFailed(error.message ?? '网络请求失败');
    } catch (error) {
      yield GenerationFailed(error.toString());
    }
  }
}

