/// SeasonalFood 数据模型测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/shopping_list/domain/seasonal_food.dart';

void main() {
  group('SeasonalFood Model -', () {
    test('应该正确创建 SeasonalFood 实例', () {
      // Arrange & Act
      const food = SeasonalFood(
        id: 'apple_001',
        name: 'Apple',
        aliases: ['Malus', 'Pomme'],
        seasons: ['autumn', 'winter'],
        category: 'fruit',
        defaultShelfLifeDays: 30,
        tags: ['fresh', 'vitamin-c'],
      );

      // Assert
      expect(food.id, 'apple_001');
      expect(food.name, 'Apple');
      expect(food.aliases, ['Malus', 'Pomme']);
      expect(food.seasons, ['autumn', 'winter']);
      expect(food.category, 'fruit');
      expect(food.defaultShelfLifeDays, 30);
      expect(food.tags, ['fresh', 'vitamin-c']);
    });

    test('应该从 JSON 正确解析', () {
      // Arrange
      final json = {
        'id': 'tomato_001',
        'name': 'Tomato',
        'aliases': ['Solanum lycopersicum'],
        'seasons': ['summer', 'autumn'],
        'category': 'vegetable',
        'default_shelf_life_days': 14,
        'tags': ['red', 'juicy'],
      };

      // Act
      final food = SeasonalFood.fromJson(json);

      // Assert
      expect(food.id, 'tomato_001');
      expect(food.name, 'Tomato');
      expect(food.aliases, ['Solanum lycopersicum']);
      expect(food.seasons, ['summer', 'autumn']);
      expect(food.category, 'vegetable');
      expect(food.defaultShelfLifeDays, 14);
      expect(food.tags, ['red', 'juicy']);
    });

    test('应该从 JSON 字符串解析列表', () {
      // Arrange
      const jsonString = '''
      [
        {
          "id": "carrot_001",
          "name": "Carrot",
          "aliases": ["Daucus carota"],
          "seasons": ["autumn", "winter"],
          "category": "vegetable",
          "default_shelf_life_days": 30,
          "tags": ["root", "orange"]
        },
        {
          "id": "strawberry_001",
          "name": "Strawberry",
          "aliases": ["Fragaria"],
          "seasons": ["spring", "summer"],
          "category": "fruit",
          "default_shelf_life_days": 7,
          "tags": ["berry", "sweet"]
        }
      ]
      ''';

      // Act
      final foods = SeasonalFood.listFromJsonString(jsonString);

      // Assert
      expect(foods.length, 2);
      expect(foods[0].id, 'carrot_001');
      expect(foods[0].name, 'Carrot');
      expect(foods[0].seasons, ['autumn', 'winter']);
      expect(foods[1].id, 'strawberry_001');
      expect(foods[1].name, 'Strawberry');
      expect(foods[1].seasons, ['spring', 'summer']);
    });

    test('应该处理空列表 JSON', () {
      // Arrange
      const jsonString = '[]';

      // Act
      final foods = SeasonalFood.listFromJsonString(jsonString);

      // Assert
      expect(foods, isEmpty);
    });

    test('应该处理多季节食材', () {
      // Arrange
      final json = {
        'id': 'lettuce_001',
        'name': 'Lettuce',
        'aliases': ['Lactuca sativa'],
        'seasons': ['spring', 'summer', 'autumn', 'winter'],
        'category': 'vegetable',
        'default_shelf_life_days': 5,
        'tags': ['green', 'leafy'],
      };

      // Act
      final food = SeasonalFood.fromJson(json);

      // Assert
      expect(food.seasons.length, 4);
      expect(food.seasons, containsAll(['spring', 'summer', 'autumn', 'winter']));
    });

    test('应该处理空别名列表', () {
      // Arrange
      final json = {
        'id': 'potato_001',
        'name': 'Potato',
        'aliases': [],
        'seasons': ['autumn'],
        'category': 'vegetable',
        'default_shelf_life_days': 60,
        'tags': ['starch'],
      };

      // Act
      final food = SeasonalFood.fromJson(json);

      // Assert
      expect(food.aliases, isEmpty);
    });

    test('应该处理不同类型的 shelf life days', () {
      // Arrange - 测试 int
      final jsonInt = {
        'id': 'test_001',
        'name': 'Test',
        'aliases': [],
        'seasons': ['spring'],
        'category': 'test',
        'default_shelf_life_days': 20,
        'tags': [],
      };

      // Arrange - 测试 double
      final jsonDouble = {
        'id': 'test_002',
        'name': 'Test2',
        'aliases': [],
        'seasons': ['spring'],
        'category': 'test',
        'default_shelf_life_days': 25.0,
        'tags': [],
      };

      // Act
      final food1 = SeasonalFood.fromJson(jsonInt);
      final food2 = SeasonalFood.fromJson(jsonDouble);

      // Assert
      expect(food1.defaultShelfLifeDays, 20);
      expect(food2.defaultShelfLifeDays, 25);
    });

    test('应该正确处理包含特殊字符的名称', () {
      // Arrange
      final json = {
        'id': 'special_001',
        'name': 'Jalapeño Pepper',
        'aliases': ['Capsicum annuum'],
        'seasons': ['summer'],
        'category': 'vegetable',
        'default_shelf_life_days': 10,
        'tags': ['spicy', 'hot'],
      };

      // Act
      final food = SeasonalFood.fromJson(json);

      // Assert
      expect(food.name, 'Jalapeño Pepper');
    });
  });
}
