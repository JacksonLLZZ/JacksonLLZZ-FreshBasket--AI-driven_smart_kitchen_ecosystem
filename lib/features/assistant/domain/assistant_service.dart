import 'gemini_service.dart';

class AssistantService {
  final GeminiService _geminiService = GeminiService();

  Future<String> getResponse(String userMessage) async {
    try {
      return await _geminiService.getResponse(userMessage);
    } catch (e) {
      // 检查错误类型，如果是 API 密钥未配置，传播错误
      if (e.toString().contains('API key not configured')) {
        rethrow; // 传播错误到上层
      }

      // 对于其他错误，返回包含错误信息的友好消息
      await Future.delayed(const Duration(seconds: 1));

      return "I'm having technical difficulties. Error: ${e.toString().split(':').last.trim()}";
    }
  }

  Stream<String> getResponseStream(String userMessage) async* {
    try {
      yield* _geminiService.getResponseStream(userMessage);
    } catch (e) {
      // 检查错误类型，如果是 API 密钥未配置，传播错误
      if (e.toString().contains('API key not configured')) {
        rethrow; // 传播错误到上层
      }

      // 对于其他错误，返回包含错误信息的友好消息
      await Future.delayed(const Duration(seconds: 1));

      yield "I'm having technical difficulties. Error: ${e.toString().split(':').last.trim()}";
    }
  }
}