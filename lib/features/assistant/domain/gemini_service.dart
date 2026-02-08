import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _apiKeyPrefKey = 'gemini_api_key';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefKey);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey);
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefKey);
  }

  Future<String> getResponse(String userMessage) async {
    final apiKey = await getApiKey();
    print(
      'GeminiService: API key configured: ${apiKey != null && apiKey.isNotEmpty}',
    );

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Gemini API key not configured. Please set your API key in Profile settings.',
      );
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey.trim(),
      );

      final prompt =
          '''You are KitchenAI, a professional kitchen assistant with expertise in:

1. Recipe development and adaptation
2. Ingredient substitution
3. Meal planning and Food storage
4. Seasonal cooking and ingredient pairing

Please provide:
- actionable advice
- Clear step-by-step instructions
- Consideration for ingredient availability and cost
- Alternatives for common dietary restrictions
- Concise but thorough responses

User Question: $userMessage

KitchenAI Response:''';
      print(
        'GeminiService: Sending request with prompt length: ${prompt.length}',
      );

      final response = await model.generateContent([Content.text(prompt)]);
      print('GeminiService: Received response: ${response.text != null}');

      return response.text ?? 'Sorry, I could not generate a response.';
    } catch (e) {
      print('GeminiService: Error: $e');

      // 提供更具体的错误信息
      String errorMessage = 'Failed to get response from Gemini API';
      if (e.toString().contains('API_KEY_INVALID')) {
        errorMessage =
            'Invalid API key. Please check your Gemini API key configuration.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('quota')) {
        errorMessage =
            'API quota exceeded. Please check your Gemini API usage limits.';
      }
      throw Exception('$errorMessage: ${e.toString()}');
    }
  }

  Stream<String> getResponseStream(String userMessage) async* {
    final apiKey = await getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Gemini API key not configured. Please set your API key in Profile settings.',
      );
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final prompt =
          '''You are KitchenAI, a professional kitchen assistant with expertise in:

1. Recipe development and adaptation
2. Ingredient substitution and nutritional analysis
3. Meal planning and preparation techniques
4. Food storage and preservation methods
5. Seasonal cooking and ingredient pairing

Please provide:
- Practical, actionable advice
- Clear step-by-step instructions when appropriate
- Consideration for ingredient availability and cost
- Alternatives for common dietary restrictions
- Concise but thorough responses

User Question: $userMessage

KitchenAI Response:''';

      final responseStream = model.generateContentStream([
        Content.text(prompt),
      ]);

      await for (final response in responseStream) {
        if (response.text != null && response.text!.isNotEmpty) {
          yield response.text!;
        }
      }
    } catch (e) {
      print('GeminiService: Stream Error: $e');

      String errorMessage = 'Failed to get response from Gemini API';
      if (e.toString().contains('API_KEY_INVALID')) {
        errorMessage =
            'Invalid API key. Please check your Gemini API key configuration.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('quota')) {
        errorMessage =
            'API quota exceeded. Please check your Gemini API usage limits.';
      }
      throw Exception('$errorMessage: ${e.toString()}');
    }
  }
}
