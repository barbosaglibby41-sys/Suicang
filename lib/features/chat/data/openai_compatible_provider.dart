import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/chat_models.dart';
import '../domain/generation.dart';

class OpenAiCompatibleProvider implements LlmProvider {
  OpenAiCompatibleProvider({required this.baseUrl, required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  final String baseUrl;
  final String apiKey;
  final Dio _dio;

  @override
  Stream<GenerationEvent> generate(GenerationRequest request) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/chat/completions',
        data: jsonEncode({
          'model': request.model,
          'stream': true,
          'temperature': request.temperature,
          'max_tokens': request.maxTokens,
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

