/// Food validation utilities for duplicate detection
class FoodValidator {
  /// 模糊匹配食材名称(忽略大小写和空格)
  static bool isSimilarName(String name1, String name2) {
    final clean1 = name1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    final clean2 = name2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    return clean1 == clean2;
  }
}
