/// Food validation utilities for duplicate detection
class FoodValidator {
  /// Fuzzy match ingredient names (ignore case and spaces)
  static bool isSimilarName(String name1, String name2) {
    final clean1 = name1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    final clean2 = name2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '');
    return clean1 == clean2;
  }
}
