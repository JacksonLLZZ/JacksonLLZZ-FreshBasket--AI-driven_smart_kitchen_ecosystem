import 'package:flutter/services.dart';

/// Ingredient list service - Load standard ingredient names from CSV file
class IngredientListService {
  static List<String>? _cachedIngredients;

  /// Load ingredient list (from assets/data/ingredients_list.csv)
  static Future<List<String>> loadIngredients() async {
    if (_cachedIngredients != null) {
      return _cachedIngredients!;
    }

    try {
      final csvString = await rootBundle.loadString(
        'assets/data/ingredients_list.csv',
      );
      final lines = csvString.split('\n');

      // Skip first header line (IngredientName)
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

  /// Filter matching ingredients based on input text
  static List<String> filterIngredients(
    List<String> allIngredients,
    String query,
  ) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final matches = allIngredients
        .where((ingredient) => ingredient.toLowerCase().contains(lowerQuery))
        .toList();

    // Smart sorting: exact match > prefix match > contains match, same level alphabetical order
    matches.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();

      // 1. Exact match priority (case insensitive)
      final aExact = aLower == lowerQuery;
      final bExact = bLower == lowerQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      // 2. Prefix match priority
      final aStarts = aLower.startsWith(lowerQuery);
      final bStarts = bLower.startsWith(lowerQuery);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      // 3. Alphabetical order within same level
      return a.compareTo(b);
    });

    return matches;
  }
}
