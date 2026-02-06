import 'gemini_service.dart';

class AssistantService {
  final GeminiService _geminiService = GeminiService();

  Future<String> getResponse(String userMessage) async {
    try {
      return await _geminiService.getResponse(userMessage);
    } catch (e) {
      // Fallback to mock responses if API fails
      await Future.delayed(const Duration(seconds: 1));

      if (userMessage.toLowerCase().contains('recipe')) {
        return "I can suggest recipes based on your fridge inventory. Try the 'Explore Recipes' button in your Fridge screen!";
      } else if (userMessage.toLowerCase().contains('shopping')) {
        return "Check the seasonal recommendations in your Shopping Cart for the best ingredients to buy now.";
      } else {
        return "I'm your kitchen AI assistant! I can help with recipe suggestions, ingredient analysis, and meal planning.";
      }
    }
  }
}