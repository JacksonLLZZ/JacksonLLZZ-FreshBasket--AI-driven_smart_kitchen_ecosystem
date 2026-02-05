/// Food validation utilities for category-unit matching and duplicate detection
class FoodValidator {
  /// 分类允许的单位映射
  static const Map<String, List<String>> categoryAllowedUnits = {
    'Drink': ['ml'], // 饮料只能用毫升
    'Dairy': ['ml', 'g'], // 奶制品两者都可
    'Meat': ['g'], // 固体食物用克
    'Fruit': ['g'],
    'Vegetable': ['g'],
    'Grain': ['g'],
    'Seafood': ['g'],
    'Snack': ['g', 'ml'], // 零食灵活
  };

  /// 获取指定分类允许的单位列表
  static List<String> getAllowedUnits(String category) {
    return categoryAllowedUnits[category] ?? ['g', 'ml'];
  }

  /// 验证单位是否适用于指定分类
  static bool isUnitValid(String category, String unit) {
    return getAllowedUnits(category).contains(unit);
  }

  /// 模糊匹配食材名称(忽略大小写和空格)
  static bool isSimilarName(String name1, String name2) {
    final clean1 = name1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    final clean2 = name2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    return clean1 == clean2;
  }
}
