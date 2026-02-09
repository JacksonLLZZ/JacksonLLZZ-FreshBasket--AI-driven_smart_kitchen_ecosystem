/// Recipe 和 RecipeIngredient data model test
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/recipes/data/recipe.dart';

void main() {
  group('RecipeIngredient Model -', () {
    test('应该正确创建 RecipeIngredient 实例', () {
      // Arrange & Act
      final ingredient = RecipeIngredient(
        name: 'tomato',
        original: '2 medium tomatoes',
        image: 'tomato.jpg',
      );

      // Assert
      expect(ingredient.name, 'tomato');
      expect(ingredient.original, '2 medium tomatoes');
      expect(ingredient.image, 'tomato.jpg');
    });

    test('应该从 JSON 正确解析', () {
      // Arrange
      final json = {
        'name': 'onion',
        'original': '1 large onion, chopped',
        'image': 'onion.png',
      };

      // Act
      final ingredient = RecipeIngredient.fromJson(json);

      // Assert
      expect(ingredient.name, 'onion');
      expect(ingredient.original, '1 large onion, chopped');
      expect(ingredient.image, 'onion.png');
    });

    test('应该处理缺失的 image 字段', () {
      // Arrange
      final json = {'name': 'garlic', 'original': '3 cloves garlic'};

      // Act
      final ingredient = RecipeIngredient.fromJson(json);

      // Assert
      expect(ingredient.name, 'garlic');
      expect(ingredient.original, '3 cloves garlic');
      expect(ingredient.image, isNull);
    });

    test('应该正确转换为 JSON', () {
      // Arrange
      final ingredient = RecipeIngredient(
        name: 'salt',
        original: '1 tsp salt',
        image: null,
      );

      // Act
      final json = ingredient.toJson();

      // Assert
      expect(json['name'], 'salt');
      expect(json['original'], '1 tsp salt');
      expect(json['image'], isNull);
    });
  });

  group('Recipe Model -', () {
    test('应该正确创建 Recipe 实例', () {
      // Arrange & Act
      final recipe = Recipe(
        id: 12345,
        title: 'Tomato Pasta',
        image: 'pasta.jpg',
        usedIngredientCount: 3,
        missedIngredientCount: 2,
        usedIngredients: [
          RecipeIngredient(name: 'pasta', original: '200g pasta'),
          RecipeIngredient(name: 'tomato', original: '2 tomatoes'),
        ],
        missedIngredients: [
          RecipeIngredient(name: 'basil', original: '5 basil leaves'),
        ],
      );

      // Assert
      expect(recipe.id, 12345);
      expect(recipe.title, 'Tomato Pasta');
      expect(recipe.image, 'pasta.jpg');
      expect(recipe.usedIngredientCount, 3);
      expect(recipe.missedIngredientCount, 2);
      expect(recipe.usedIngredients.length, 2);
      expect(recipe.missedIngredients.length, 1);
      expect(recipe.instructions, isNull);
      expect(recipe.category, isNull);
    });

    test('应该从 JSON 正确解析（Spoonacular 格式）', () {
      // Arrange
      final json = {
        'id': 678,
        'title': 'Chicken Curry',
        'image': 'curry.jpg',
        'usedIngredientCount': 5,
        'missedIngredientCount': 1,
        'usedIngredients': [
          {'name': 'chicken', 'original': '500g chicken breast', 'image': null},
          {'name': 'curry', 'original': '2 tbsp curry powder'},
        ],
        'missedIngredients': [
          {'name': 'coconut milk', 'original': '400ml coconut milk'},
        ],
      };

      // Act
      final recipe = Recipe.fromJson(json);

      // Assert
      expect(recipe.id, 678);
      expect(recipe.title, 'Chicken Curry');
      expect(recipe.image, 'curry.jpg');
      expect(recipe.usedIngredientCount, 5);
      expect(recipe.missedIngredientCount, 1);
      expect(recipe.usedIngredients.length, 2);
      expect(recipe.missedIngredients.length, 1);
      expect(recipe.usedIngredients[0].name, 'chicken');
      expect(recipe.missedIngredients[0].name, 'coconut milk');
    });

    test('应该从 JSON 正确解析（TheMealDB 格式）', () {
      // Arrange
      final json = {
        'id': 999,
        'title': 'Japanese Teriyaki',
        'image': 'teriyaki.jpg',
        'usedIngredientCount': 4,
        'missedIngredientCount': 0,
        'usedIngredients': [],
        'missedIngredients': [],
        'instructions': 'Step 1: Cook rice. Step 2: Prepare sauce...',
        'category': 'Chicken',
        'area': 'Japanese',
        'tags': 'Sweet,Savory',
        'youtubeUrl': 'https://youtube.com/watch?v=abc123',
      };

      // Act
      final recipe = Recipe.fromJson(json);

      // Assert
      expect(recipe.id, 999);
      expect(recipe.title, 'Japanese Teriyaki');
      expect(
        recipe.instructions,
        'Step 1: Cook rice. Step 2: Prepare sauce...',
      );
      expect(recipe.category, 'Chicken');
      expect(recipe.area, 'Japanese');
      expect(recipe.tags, 'Sweet,Savory');
      expect(recipe.youtubeUrl, 'https://youtube.com/watch?v=abc123');
    });

    test('应该处理缺失的字段', () {
      // Arrange
      final json = {'id': 111, 'title': 'Simple Recipe'};

      // Act
      final recipe = Recipe.fromJson(json);

      // Assert
      expect(recipe.id, 111);
      expect(recipe.title, 'Simple Recipe');
      expect(recipe.image, '');
      expect(recipe.usedIngredientCount, 0);
      expect(recipe.missedIngredientCount, 0);
      expect(recipe.usedIngredients, isEmpty);
      expect(recipe.missedIngredients, isEmpty);
      expect(recipe.instructions, isNull);
    });

    test('应该正确转换为 JSON', () {
      // Arrange
      final recipe = Recipe(
        id: 555,
        title: 'Test Recipe',
        image: 'test.jpg',
        usedIngredientCount: 2,
        missedIngredientCount: 1,
        usedIngredients: [RecipeIngredient(name: 'egg', original: '2 eggs')],
        missedIngredients: [],
        instructions: 'Mix and cook',
        category: 'Breakfast',
        area: 'American',
        tags: 'Quick,Easy',
        youtubeUrl: null,
      );

      // Act
      final json = recipe.toJson();

      // Assert
      expect(json['id'], 555);
      expect(json['title'], 'Test Recipe');
      expect(json['image'], 'test.jpg');
      expect(json['usedIngredientCount'], 2);
      expect(json['missedIngredientCount'], 1);
      expect(json['usedIngredients'], isA<List>());
      expect((json['usedIngredients'] as List).length, 1);
      expect(json['instructions'], 'Mix and cook');
      expect(json['category'], 'Breakfast');
      expect(json['area'], 'American');
      expect(json['tags'], 'Quick,Easy');
      expect(json['youtubeUrl'], isNull);
    });

    test('toJson 和 fromJson 应该是可逆的', () {
      // Arrange
      final original = Recipe(
        id: 777,
        title: 'Round Trip Test',
        image: 'test.jpg',
        usedIngredientCount: 3,
        missedIngredientCount: 2,
        usedIngredients: [
          RecipeIngredient(
            name: 'flour',
            original: '200g flour',
            image: 'flour.jpg',
          ),
        ],
        missedIngredients: [
          RecipeIngredient(name: 'sugar', original: '100g sugar'),
        ],
        instructions: 'Test instructions',
        category: 'Dessert',
        area: 'French',
        tags: 'Sweet',
        youtubeUrl: 'https://youtube.com/test',
      );

      // Act
      final json = original.toJson();
      final reconstructed = Recipe.fromJson(json);

      // Assert
      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.image, original.image);
      expect(reconstructed.usedIngredientCount, original.usedIngredientCount);
      expect(
        reconstructed.missedIngredientCount,
        original.missedIngredientCount,
      );
      expect(
        reconstructed.usedIngredients.length,
        original.usedIngredients.length,
      );
      expect(
        reconstructed.missedIngredients.length,
        original.missedIngredients.length,
      );
      expect(reconstructed.instructions, original.instructions);
      expect(reconstructed.category, original.category);
      expect(reconstructed.area, original.area);
      expect(reconstructed.tags, original.tags);
      expect(reconstructed.youtubeUrl, original.youtubeUrl);
    });
  });
}
