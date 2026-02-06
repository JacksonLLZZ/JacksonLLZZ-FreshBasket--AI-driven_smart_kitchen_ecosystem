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
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not configured. Please set your API key in Profile settings.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = 'You are a helpful kitchen assistant. You help users with recipe suggestions, ingredient analysis, meal planning, and food management. Keep responses concise and practical.\n\nUser: $userMessage\nAssistant:';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Sorry, I could not generate a response.';
    } catch (e) {
      throw Exception('Failed to get response from Gemini API: $e');
    }
  }
}