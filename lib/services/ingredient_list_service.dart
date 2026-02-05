import 'package:flutter/services.dart';

/// 食材列表服务 - 从CSV文件加载标准食材名称
class IngredientListService {
  static List<String>? _cachedIngredients;

  /// 加载食材列表（从assets/data/ingredients_list.csv）
  static Future<List<String>> loadIngredients() async {
    if (_cachedIngredients != null) {
      return _cachedIngredients!;
    }

    try {
      final csvString = await rootBundle.loadString(
        'assets/data/ingredients_list.csv',
      );
      final lines = csvString.split('\n');

      // 跳过第一行标题（IngredientName）
      _cachedIngredients = lines
          .skip(1)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return _cachedIngredients!;
    } catch (e) {
      print('Error loading ingredients: $e');
      return [];
    }
  }

  /// 根据输入文本过滤匹配的食材
  static List<String> filterIngredients(
    List<String> allIngredients,
    String query,
  ) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final matches = allIngredients
        .where((ingredient) => ingredient.toLowerCase().contains(lowerQuery))
        .toList();

    // 智能排序：完全匹配 > 开头匹配 > 包含匹配，同级别按字母排序
    matches.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();

      // 1. 完全匹配优先（忽略大小写）
      final aExact = aLower == lowerQuery;
      final bExact = bLower == lowerQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      // 2. 以查询词开头的优先
      final aStarts = aLower.startsWith(lowerQuery);
      final bStarts = bLower.startsWith(lowerQuery);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      // 3. 同级别内按字母排序
      return a.compareTo(b);
    });

    return matches;
  }
}
