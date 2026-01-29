import 'package:dio/dio.dart';
import '../features/inventory/data/ingredient.dart';
import '../features/recipes/data/recipe.dart';

class NutritionService {
  // 移除了 ApiClient (Gemini)，只保留用于 Edamam 的 Dio
  final Dio _dio = Dio();

  // Edamam 凭据
  static const String _appId = 'd40c3d5b';
  static const String _appKey = '14e8ae86c83914498144d64886f25484';

  // Spoonacular API 凭据
  static const String _spoonacularApiKey = 'cb85e29952744463a42f1e69d51a234a';

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
      //print("Edamam API Error: $e");
    }
    return null;
  }

  /// 2. 使用 Spoonacular API 根据食材列表生成食谱推荐
  Future<List<Recipe>> generateCombinedRecipes(List<Ingredient> items) async {
    if (items.isEmpty) {
      throw Exception("No ingredients selected.");
    }

    // 将食材名称转换为逗号分隔的字符串
    String ingredientsQuery = items.map((e) => e.name).join(',');

    try {
      final response = await _dio.get(
        'https://api.spoonacular.com/recipes/findByIngredients',
        queryParameters: {
          'apiKey': _spoonacularApiKey,
          'ingredients': ingredientsQuery,
          'number': 10, // 最多返回10个食谱
          'ranking': 1, // 优先最大化使用现有食材
          'ignorePantry': true, // 忽略常见调味品
        },
      );

      if (response.data == null || (response.data as List).isEmpty) {
        return [];
      }

      // 解析并返回食谱列表
      List<dynamic> recipesJson = response.data as List;
      return recipesJson.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Failed to fetch recipes: $e");
    }
  }
}
