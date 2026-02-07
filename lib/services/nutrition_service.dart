import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../features/inventory/data/ingredient.dart';
import '../features/recipes/data/recipe.dart';
import '../core/config/api_config.dart';

class NutritionService {
  // 移除了 ApiClient (Gemini)，只保留用于 Edamam 的 Dio
  final Dio _dio = Dio();

  // 百度 AI Token 缓存
  String? _baiduAccessToken;
  DateTime? _tokenExpireTime;

  // 常见调味料和基础食材黑名单（过滤缺失食材时使用）
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

  /// 过滤掉常见调味料
  static bool _isPantryItem(String ingredientName) {
    final name = ingredientName.toLowerCase().trim();
    return _commonPantryItems.any(
      (pantryItem) => name == pantryItem || name.contains(pantryItem),
    );
  }

  /// 1. 使用 Edamam API 计算卡路里 (用于单个食材)
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

  /// 1.1 使用 OpenFoodFacts API 通过条形码获取产品信息
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        'https://world.openfoodfacts.net/api/v2/product/$barcode',
        queryParameters: {'fields': 'product_name,nutriscore_data'},
      );

      if (response.data['status'] == 1 && response.data['product'] != null) {
        final product = response.data['product'];
        final productName = product['product_name'] ?? 'Unknown Product';

        // 计算卡路里（从 kJ 转换为 kcal）
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
          'apiKey': ApiConfig.spoonacularApiKey,
          'ingredients': ingredientsQuery,
          'number': 2, // 最多返回10个食谱 // TODO: 调整为用户可配置
          'ranking': 1, // 优先最大化使用现有食材
          'ignorePantry': true, // 忽略常见调味品
        },
      );

      if (response.data == null || (response.data as List).isEmpty) {
        return [];
      }

      // 解析并返回食谱列表
      List<dynamic> recipesJson = response.data as List;
      List<Recipe> recipes = recipesJson
          .map((json) => Recipe.fromJson(json))
          .toList();

      // 过滤掉缺失食材中的调味料
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

  /// 3. 使用 TheMealDB (Free Recipe API) 根据单个食材搜索食谱
  Future<List<Recipe>> generateRecipesFromMealDb(String ingredient) async {
    if (ingredient.isEmpty) {
      throw Exception("No ingredient provided.");
    }

    try {
      // 尝试多种形式的食材名称
      List<String> ingredientVariants = [
        ingredient, // 原始形式
        '${ingredient}s', // 加 s
        '${ingredient}es', // 加 es
      ];

      List<dynamic>? meals;
      String usedIngredient = ingredient;

      // 依次尝试不同的变体
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
          break; // 找到结果就停止尝试
        }
      }

      // 如果所有变体都没有结果
      if (meals == null || meals.isEmpty) {
        debugPrint('No meals found for any variant of: $ingredient');
        return [];
      }

      // 限制返回数量，避免请求过多
      final mealsToFetch = meals.take(2).toList();

      // 步骤2: 并发获取每个菜谱的详细信息
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

            // 转换为 Recipe 对象，使用找到结果的变体名称
            final recipe = _convertMealDbToRecipe(mealDetail, usedIngredient);
            recipes.add(recipe);
          }
        } catch (e) {
          // 单个菜谱获取失败不影响其他
          debugPrint('Failed to fetch meal details: $e');
          continue;
        }
      }

      return recipes;
    } catch (e) {
      throw Exception("Failed to fetch recipes from MealDB: $e");
    }
  }

  /// 将 TheMealDB 的数据格式转换为 Recipe 对象
  Recipe _convertMealDbToRecipe(
    Map<String, dynamic> mealDetail,
    String searchedIngredient,
  ) {
    final id = int.tryParse(mealDetail['idMeal'] ?? '0') ?? 0;
    final title = mealDetail['strMeal'] ?? 'Unknown Recipe';
    final image = mealDetail['strMealThumb'] ?? '';

    // 提取所有食材和用量（TheMealDB 使用 strIngredient1-20 和 strMeasure1-20）
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
            image: null, // TheMealDB 不提供食材图片
          ),
        );
      }
    }

    // 判断哪些是用户已有的食材（used），哪些是缺失的（missed）
    List<RecipeIngredient> usedIngredients = [];
    List<RecipeIngredient> missedIngredients = [];

    for (var ingredient in allIngredients) {
      // 简单判断：如果食材名包含搜索的关键词，则视为已有
      if (ingredient.name.toLowerCase().contains(
        searchedIngredient.toLowerCase(),
      )) {
        usedIngredients.add(ingredient);
      } else {
        // 过滤掉常见调味料
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
      // TheMealDB 独有信息
      instructions: mealDetail['strInstructions'],
      category: mealDetail['strCategory'],
      area: mealDetail['strArea'],
      tags: mealDetail['strTags'],
      youtubeUrl: mealDetail['strYoutube'],
    );
  }

  // 获取百度AI Access Token
  Future<String?> _getBaiduAccessToken() async {
    // 如果token存在且未过期，直接返回
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
        // Token有效期通常为30天，这里设置为29天以确保安全
        _tokenExpireTime = DateTime.now().add(const Duration(days: 29));
        return _baiduAccessToken;
      }
    } catch (e) {
      debugPrint('Error getting Baidu access token: $e');
    }
    return null;
  }

  // 生成MD5签名
  String _generateMD5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  // 使用百度翻译API将中文翻译为英文
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
        // 检查是否有错误
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

  // 识别图片中的食材
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
          'image': base64Image, // Dio 会自动进行 URL 编码
          'top_num': 20, // 获取更多结果以处理"非果蔬食材"情况
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // 检查是否有错误信息
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
          // 遍历结果，跳过"非果蔬食材"
          for (var item in result) {
            final ingredientName = item['name'] as String?;
            final score = item['score'];

            if (ingredientName != null && ingredientName != '非果蔬食材') {
              // 翻译成英文
              final englishName = await _translateToEnglish(ingredientName);

              return {
                'success': true,
                'name': englishName ?? ingredientName, // 如果翻译失败，使用原始中文名
                'original_name': ingredientName, // 保留原始中文名
                'score': score,
              };
            }
          }

          // 如果所有结果都是"非果蔬食材"
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
