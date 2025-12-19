import 'package:dio/dio.dart';
import '../features/inventory/data/ingredient.dart';

class NutritionService {
  // 移除了 ApiClient (Gemini)，只保留用于 Edamam 的 Dio
  final Dio _dio = Dio(); 
  
  // Edamam 凭据
  static const String _appId = 'd40c3d5b';
  static const String _appKey = '14e8ae86c83914498144d64886f25484';

  /// 1. 使用 Edamam API 计算卡路里 (用于单个食材)
  Future<int?> calculateCalories(String name, double qty, String unit) async {
  final queryText = "$qty $unit $name";

  try {
    final response = await _dio.get(
      'https://api.edamam.com/api/nutrition-data',
      queryParameters: {
        'app_id': _appId,
        'app_key': _appKey,
        'ingr': queryText,
      },
    );

    final ingredients = response.data['ingredients'];
    if (ingredients is List && ingredients.isNotEmpty) {
      final parsed = ingredients[0]['parsed'];
      if (parsed is List && parsed.isNotEmpty) {
        final nutrients = parsed[0]['nutrients'];
        final energy = nutrients['ENERC_KCAL'];
        if (energy != null) {
          return (energy['quantity'] as num).round();
        }
      }
    }
  } catch (e) {
    print("Edamam API Error: $e");
  }
  return null;
  }



  
  Future<String> generateCombinedRecipes(List<Ingredient> items) async {
    if (items.isEmpty) return "No ingredients selected.";
    
    String ingredientsList = items.map((e) => "• ${e.name} (${e.quantity} ${e.unit})").join("\n");
    
    // 返回一段固定的提示文本，说明 AI 功能已按要求关闭
    return """
[Recipe Recommendation]
Based on your current inventory:
$ingredientsList

Recommended Dish: Healthy Mixed Bowl
Instructions:
1. Prepare and clean all the ingredients listed above.
2. Mix them in a large bowl.
3. Add a dash of olive oil and salt to taste.
4. Enjoy your balanced meal!

Note: The Gemini AI recipe generation has been disabled per project requirements. 
This page now displays a standardized suggestion format.
""";
  }
}