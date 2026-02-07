/// 测试套件索引文件
/// 
/// 运行所有单元测试
library;

import 'package:flutter_test/flutter_test.dart';

// 数据模型测试
import 'ingredient_test.dart' as ingredient_test;
import 'shopping_item_test.dart' as shopping_item_test;
import 'recipe_test.dart' as recipe_test;
import 'seasonal_food_test.dart' as seasonal_food_test;

// 工具类测试
import 'food_validator_test.dart' as food_validator_test;
import 'season_helper_test.dart' as season_helper_test;
import 'ingredient_list_service_test.dart' as ingredient_list_service_test;

// 服务类测试
import 'nutrition_service_test.dart' as nutrition_service_test;
import 'database_service_test.dart' as database_service_test;

// 边界案例测试
import 'ingredient_edge_cases_test.dart' as ingredient_edge_cases_test;

void main() {
  group('数据模型测试', () {
    ingredient_test.main();
    shopping_item_test.main();
    recipe_test.main();
    seasonal_food_test.main();
  });

  group('工具类测试', () {
    food_validator_test.main();
    season_helper_test.main();
    ingredient_list_service_test.main();
  });

  group('服务类测试', () {
    nutrition_service_test.main();
    database_service_test.main();
  });

  group('边界案例测试', () {
    ingredient_edge_cases_test.main();
  });
}
