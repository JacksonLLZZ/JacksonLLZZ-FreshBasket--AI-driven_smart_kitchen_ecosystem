import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../features/inventory/data/ingredient.dart';
import '../features/recipes/data/recipe.dart';
import '../core/config/api_config.dart';

class NutritionService {
  // Dio instance - supports dependency injection for testing
  final Dio _dio;

  // Baidu AI Token cache
  String? _baiduAccessToken;
  DateTime? _tokenExpireTime;

  // Constructor - allows injection of Dio instance for testing
  NutritionService({Dio? dio}) : _dio = dio ?? Dio();

  // Common condiments and basic ingredient blacklist (used when filtering missing ingredients)
  static const Set<String> _commonPantryItems = {
    'salt',
    'pepper',
    'oil',
    'olive oil',
    'vegetable oil',
    'water',
    'sugar',
    'brown sugar',
    'flour',
    'butter',
    'garlic',
    'onion',
    'black pepper',
    'white pepper',
    'soy sauce',
    'vinegar',
    'cooking oil',
    'sesame oil',
    'canola oil',
    'cornstarch',
    'baking powder',
    'baking soda',
    'vanilla',
    'vanilla extract',
    'milk',
    'cream',
    'honey',
    'lemon juice',
    'wine',
    'lime juice',
    'rice vinegar',
    'white vinegar',
    'cinnamon',
    'paprika',
    'cumin',
    'oregano',
    'thyme',
    'rosemary',
    'basil',
    'parsley',
    'cilantro',
    'bay leaf',
    'nutmeg',
    'ginger',
    'chili powder',
    'cayenne pepper',
    'red pepper flakes',
  };

  /// Filter out common condiments
  static bool _isPantryItem(String ingredientName) {
    final name = ingredientName.toLowerCase().trim();
    return _commonPantryItems.any(
      (pantryItem) => name == pantryItem || name.contains(pantryItem),
    );
  }

  /// 1. Use Edamam API to calculate calories (for single ingredient)
  Future<int?> calculateCalories(String name, double qty, String unit) async {
    final queryText = "$qty $unit $name";

    try {
      final response = await _dio.get(
        'https://api.edamam.com/api/nutrition-data',
        queryParameters: {
          'app_id': ApiConfig.edamamAppId,
          'app_key': ApiConfig.edamamAppKey,
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

  /// 1.1 Use OpenFoodFacts API to get product information via barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        'https://world.openfoodfacts.net/api/v2/product/$barcode',
        queryParameters: {'fields': 'product_name,nutriscore_data'},
      );

      if (response.data['status'] == 1 && response.data['product'] != null) {
        final product = response.data['product'];
        final productName = product['product_name'] ?? 'Unknown Product';

        // Calculate calories (convert from kJ to kcal)
        int? calories;
        final nutriscoreData = product['nutriscore_data'];
        if (nutriscoreData != null &&
            nutriscoreData['components'] != null &&
            nutriscoreData['components']['negative'] != null) {
          final negativeComponents =
              nutriscoreData['components']['negative'] as List;
          final energyComponent = negativeComponents.firstWhere(
            (comp) => comp['id'] == 'energy',
            orElse: () => null,
          );

          if (energyComponent != null && energyComponent['value'] != null) {
            final energyKJ = energyComponent['value'] as num;
            // 1 kJ ≈ 0.239 kcal
            calories = (energyKJ * 0.239).round();
          }
        }

        return {'product_name': productName, 'calories': calories};
      }
    } catch (e) {
      debugPrint("OpenFoodFacts API Error: $e");
    }
    return null;
  }

  /// 2. Use Spoonacular API to generate recipe recommendations based on ingredient list
  Future<List<Recipe>> generateCombinedRecipes(List<Ingredient> items) async {
    if (items.isEmpty) {
      throw Exception("No ingredients selected.");
    }

    // Convert ingredient names to comma-separated string
    String ingredientsQuery = items.map((e) => e.name).join(',');

    try {
      final response = await _dio.get(
        'https://api.spoonacular.com/recipes/findByIngredients',
        queryParameters: {
          'apiKey': ApiConfig.spoonacularApiKey,
          'ingredients': ingredientsQuery,
          'number': 2, // Return up to 10 recipes // TODO: Make user configurable
          'ranking': 1, // Prioritize maximizing use of existing ingredients
          'ignorePantry': true, // Ignore common condiments
        },
      );

      if (response.data == null || (response.data as List).isEmpty) {
        return [];
      }

      // Parse and return recipe list
      List<dynamic> recipesJson = response.data as List;
      List<Recipe> recipes = recipesJson
          .map((json) => Recipe.fromJson(json))
          .toList();

      // Filter out condiments from missing ingredients
      return recipes.map((recipe) {
        final filteredMissed = recipe.missedIngredients
            .where((ing) => !_isPantryItem(ing.name))
            .toList();

        return Recipe(
          id: recipe.id,
          title: recipe.title,
          image: recipe.image,
          usedIngredientCount: recipe.usedIngredientCount,
          missedIngredientCount: filteredMissed.length,
          usedIngredients: recipe.usedIngredients,
          missedIngredients: filteredMissed,
        );
      }).toList();
    } catch (e) {
      throw Exception("Failed to fetch recipes: $e");
    }
  }

  /// 3. Use TheMealDB (Free Recipe API) to search recipes by single ingredient
  Future<List<Recipe>> generateRecipesFromMealDb(String ingredient) async {
    if (ingredient.isEmpty) {
      throw Exception("No ingredient provided.");
    }

    try {
      // Try multiple forms of ingredient name
      List<String> ingredientVariants = [
        ingredient, // original form
        '${ingredient}s', // add s
        '${ingredient}es', // add es
      ];

      List<dynamic>? meals;
      String usedIngredient = ingredient;

      // Try different variants sequentially
      for (var variant in ingredientVariants) {
        debugPrint('Trying TheMealDB with ingredient: $variant');

        final filterResponse = await _dio.get(
          '${ApiConfig.mealDbBaseUrl}/filter.php',
          queryParameters: {'i': variant},
        );

        if (filterResponse.data != null &&
            filterResponse.data['meals'] != null &&
            (filterResponse.data['meals'] as List).isNotEmpty) {
          meals = filterResponse.data['meals'] as List;
          usedIngredient = variant;
          debugPrint('Found ${meals.length} meals with variant: $variant');
          break; // stop trying once result is found
        }
      }

      // If no results for any variant
      if (meals == null || meals.isEmpty) {
        debugPrint('No meals found for any variant of: $ingredient');
        return [];
      }

      // Limit number of returns to avoid too many requests
      final mealsToFetch = meals.take(2).toList();

      // Step 2: Fetch detailed information for each recipe concurrently
      List<Recipe> recipes = [];

      for (var meal in mealsToFetch) {
        try {
          final mealId = meal['idMeal'];
          final detailResponse = await _dio.get(
            '${ApiConfig.mealDbBaseUrl}/lookup.php',
            queryParameters: {'i': mealId},
          );

          if (detailResponse.data != null &&
              detailResponse.data['meals'] != null &&
              (detailResponse.data['meals'] as List).isNotEmpty) {
            final mealDetail = detailResponse.data['meals'][0];

            // Convert to Recipe object, using variant name that found result
            final recipe = _convertMealDbToRecipe(mealDetail, usedIngredient);
            recipes.add(recipe);
          }
        } catch (e) {
          // Failure to fetch single recipe does not affect others
          debugPrint('Failed to fetch meal details: $e');
          continue;
        }
      }

      return recipes;
    } catch (e) {
      throw Exception("Failed to fetch recipes from MealDB: $e");
    }
  }

  /// Convert TheMealDB data format to Recipe object
  Recipe _convertMealDbToRecipe(
    Map<String, dynamic> mealDetail,
    String searchedIngredient,
  ) {
    final id = int.tryParse(mealDetail['idMeal'] ?? '0') ?? 0;
    final title = mealDetail['strMeal'] ?? 'Unknown Recipe';
    final image = mealDetail['strMealThumb'] ?? '';

    // Extract all ingredients and measures (TheMealDB uses strIngredient1-20 and strMeasure1-20)
    List<RecipeIngredient> allIngredients = [];

    for (int i = 1; i <= 20; i++) {
      final ingredientName = mealDetail['strIngredient$i'];
      final ingredientMeasure = mealDetail['strMeasure$i'];

      if (ingredientName != null &&
          ingredientName.toString().trim().isNotEmpty) {
        final measure = (ingredientMeasure ?? '').toString().trim();
        final name = ingredientName.toString().trim();

        allIngredients.add(
          RecipeIngredient(
            name: name,
            original: measure.isEmpty ? name : '$measure $name',
            image: null, // TheMealDB does not provide ingredient images
          ),
        );
      }
    }

    // Determine which ingredients are already owned by user (used), which are missing (missed)
    List<RecipeIngredient> usedIngredients = [];
    List<RecipeIngredient> missedIngredients = [];

    for (var ingredient in allIngredients) {
      // Simple judgment: if ingredient name contains search keyword, consider as owned
      if (ingredient.name.toLowerCase().contains(
        searchedIngredient.toLowerCase(),
      )) {
        usedIngredients.add(ingredient);
      } else {
        // Filter out common condiments
        if (!_isPantryItem(ingredient.name)) {
          missedIngredients.add(ingredient);
        }
      }
    }

    return Recipe(
      id: id,
      title: title,
      image: image,
      usedIngredientCount: usedIngredients.length,
      missedIngredientCount: missedIngredients.length,
      usedIngredients: usedIngredients,
      missedIngredients: missedIngredients,
      // TheMealDB unique information
      instructions: mealDetail['strInstructions'],
      category: mealDetail['strCategory'],
      area: mealDetail['strArea'],
      tags: mealDetail['strTags'],
      youtubeUrl: mealDetail['strYoutube'],
    );
  }

  // Get Baidu AI Access Token
  Future<String?> _getBaiduAccessToken() async {
    // If token exists and not expired, return directly
    if (_baiduAccessToken != null &&
        _tokenExpireTime != null &&
        DateTime.now().isBefore(_tokenExpireTime!)) {
      return _baiduAccessToken;
    }

    try {
      final response = await _dio.post(
        'https://aip.baidubce.com/oauth/2.0/token',
        queryParameters: {
          'grant_type': 'client_credentials',
          'client_id': ApiConfig.baiduApiKey,
          'client_secret': ApiConfig.baiduSecretKey,
        },
      );

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        _baiduAccessToken = response.data['access_token'];
        // Token validity is usually 30 days, set to 29 days here for safety
        _tokenExpireTime = DateTime.now().add(const Duration(days: 29));
        return _baiduAccessToken;
      }
    } catch (e) {
      debugPrint('Error getting Baidu access token: $e');
    }
    return null;
  }

  // Generate MD5 signature
  String _generateMD5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  // Use Baidu Translation API to translate Chinese to English
  Future<String?> _translateToEnglish(String chineseText) async {
    try {
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final sign = _generateMD5(
        '${ApiConfig.baiduTranslateAppId}$chineseText$salt${ApiConfig.baiduTranslateSecretKey}',
      );

      final response = await _dio.get(
        'https://fanyi-api.baidu.com/api/trans/vip/translate',
        queryParameters: {
          'q': chineseText,
          'from': 'zh',
          'to': 'en',
          'appid': ApiConfig.baiduTranslateAppId,
          'salt': salt,
          'sign': sign,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Check for errors
        if (response.data['error_code'] != null) {
          debugPrint(
            'Translation error: ${response.data['error_code']} - ${response.data['error_msg']}',
          );
          return null;
        }

        final transResult = response.data['trans_result'];
        if (transResult != null &&
            transResult is List &&
            transResult.isNotEmpty) {
          return transResult[0]['dst'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error translating text: $e');
    }
    return null;
  }

  // Identify ingredients in image
  Future<Map<String, dynamic>> recognizeIngredientFromImage(
    String base64Image,
  ) async {
    try {
      final accessToken = await _getBaiduAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'error': 'Failed to get authentication token',
        };
      }

      final response = await _dio.post(
        'https://aip.baidubce.com/rest/2.0/image-classify/v1/classify/ingredient',
        queryParameters: {'access_token': accessToken},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'image': base64Image, // Dio will automatically URL encode
          'top_num': 20, // Get more results to handle "非果蔬食材" situation
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Check for error messages
        if (response.data['error_code'] != null) {
          final errorCode = response.data['error_code'];
          final errorMsg = response.data['error_msg'] ?? 'Unknown error';

          String userFriendlyMsg;
          switch (errorCode) {
            case 216015:
              userFriendlyMsg = 'Invalid image format. Please use JPG/PNG';
              break;
            case 216201:
              userFriendlyMsg = 'No ingredient detected in the image';
              break;
            case 110:
              userFriendlyMsg = 'Authentication failed. Please try again';
              break;
            case 17:
              userFriendlyMsg = 'Daily request limit exceeded';
              break;
            case 216630:
              userFriendlyMsg = 'Image is too large (max 4MB)';
              break;
            default:
              userFriendlyMsg = 'Error $errorCode: $errorMsg';
          }

          return {'success': false, 'error': userFriendlyMsg};
        }

        final result = response.data['result'];
        if (result != null && result is List && result.isNotEmpty) {
          // Iterate through results, skip "非果蔬食材"
          for (var item in result) {
            final ingredientName = item['name'] as String?;
            final score = item['score'];

            if (ingredientName != null && ingredientName != '非果蔬食材') {
              // Translate to English
              final englishName = await _translateToEnglish(ingredientName);

              return {
                'success': true,
                'name': englishName ?? ingredientName, // If translation fails, use original Chinese name
                'original_name': ingredientName, // Keep original Chinese name
                'score': score,
              };
            }
          }

          // If all results are "非果蔬食材"
          return {
            'success': false,
            'error': 'No vegetable or fruits detected in the image',
          };
        }

        return {'success': false, 'error': 'No ingredient found in the image'};
      }

      return {
        'success': false,
        'error': 'API request failed (status: ${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
