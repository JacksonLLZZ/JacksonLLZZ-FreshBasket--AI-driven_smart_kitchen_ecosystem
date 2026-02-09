/// Test suite index file
///
/// Run all unit tests
library;

import 'package:flutter_test/flutter_test.dart';

// Data model testing
import 'ingredient_test.dart' as ingredient_test;
import 'shopping_item_test.dart' as shopping_item_test;
import 'recipe_test.dart' as recipe_test;
import 'seasonal_food_test.dart' as seasonal_food_test;

// Tool testing
import 'food_validator_test.dart' as food_validator_test;
import 'season_helper_test.dart' as season_helper_test;
import 'ingredient_list_service_test.dart' as ingredient_list_service_test;
import 'theme_test.dart' as theme_test;

// Service testing
import 'nutrition_service_test.dart' as nutrition_service_test;
import 'database_service_test.dart' as database_service_test;
import 'assistant_service_test.dart' as assistant_service_test;
import 'gemini_service_test.dart' as gemini_service_test;

// Boundary case testing
import 'ingredient_edge_cases_test.dart' as ingredient_edge_cases_test;

void main() {
  group('Data model testing', () {
    ingredient_test.main();
    shopping_item_test.main();
    recipe_test.main();
    seasonal_food_test.main();
  });

  group('Tool testing', () {
    food_validator_test.main();
    season_helper_test.main();
    ingredient_list_service_test.main();
    theme_test.main();
  });

  group('Service testing', () {
    nutrition_service_test.main();
    database_service_test.main();
    assistant_service_test.main();
    gemini_service_test.main();
  });

  group('Boundary case testing', () {
    ingredient_edge_cases_test.main();
  });
}
