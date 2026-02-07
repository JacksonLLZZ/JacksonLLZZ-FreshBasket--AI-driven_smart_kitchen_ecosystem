/// IngredientListService 工具类测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/services/ingredient_list_service.dart';

void main() {
  group('IngredientListService -', () {
    group('filterIngredients', () {
      final testIngredients = [
        'Apple',
        'Applesauce',
        'Apricot',
        'Banana',
        'Blueberry',
        'Cherry',
        'Grape',
        'Grapefruit',
        'Pineapple',
        'Strawberry',
        'Tomato',
        'Potato',
      ];

      test('空查询应该返回空列表', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          '',
        );

        // Assert
        expect(result, isEmpty);
      });

      test('应该返回包含查询字符串的所有食材', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'apple',
        );

        // Assert
        expect(result.length, 3); // Apple, Applesauce, Pineapple
        expect(result, contains('Apple'));
        expect(result, contains('Applesauce'));
        expect(result, contains('Pineapple'));
      });

      test('应该忽略大小写', () {
        // Act
        final lowerResult = IngredientListService.filterIngredients(
          testIngredients,
          'apple',
        );
        final upperResult = IngredientListService.filterIngredients(
          testIngredients,
          'APPLE',
        );
        final mixedResult = IngredientListService.filterIngredients(
          testIngredients,
          'ApPle',
        );

        // Assert
        expect(lowerResult, upperResult);
        expect(lowerResult, mixedResult);
      });

      test('完全匹配应该排在第一位', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'apple',
        );

        // Assert
        expect(result.isNotEmpty, isTrue);
        expect(result.first.toLowerCase(), 'apple');
      });

      test('以查询词开头的应该优先于其他匹配', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'ap',
        );

        // Assert
        // Apple, Applesauce, Apricot 应该排在 Grape, Grapefruit, Pineapple 前面
        final appleIndex = result.indexOf('Apple');
        final apricotIndex = result.indexOf('Apricot');
        final grapeIndex = result.indexOf('Grape');
        final pineappleIndex = result.indexOf('Pineapple');

        expect(appleIndex, lessThan(grapeIndex));
        expect(appleIndex, lessThan(pineappleIndex));
        expect(apricotIndex, lessThan(grapeIndex));
      });

      test('同级别内应该按字母排序', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'berry',
        );

        // Assert - Blueberry 和 Strawberry 都包含 berry
        expect(result.length, 2);
        expect(result[0], 'Blueberry'); // B 在 S 前面
        expect(result[1], 'Strawberry');
      });

      test('应该处理部分匹配', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'ato',
        );

        // Assert
        expect(result, contains('Tomato'));
        expect(result, contains('Potato'));
      });

      test('没有匹配时应该返回空列表', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'xyz',
        );

        // Assert
        expect(result, isEmpty);
      });

      test('应该处理单字符查询', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'a',
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, contains('Apple'));
        expect(result, contains('Banana'));
        expect(result, contains('Grape'));
      });

      test('应该处理空的食材列表', () {
        // Act
        final result = IngredientListService.filterIngredients(
          [],
          'apple',
        );

        // Assert
        expect(result, isEmpty);
      });

      test('排序优先级：完全匹配 > 开头匹配 > 包含匹配', () {
        // Arrange
        final ingredients = [
          'Pineapple',      // 包含 apple
          'Apple',          // 完全匹配 apple
          'Applesauce',     // 开头匹配 apple
          'Green Apple',    // 包含 apple
        ];

        // Act
        final result = IngredientListService.filterIngredients(
          ingredients,
          'apple',
        );

        // Assert
        expect(result.length, 4);
        expect(result[0].toLowerCase(), 'apple'); // 完全匹配第一
        expect(result[1], 'Applesauce');          // 开头匹配第二
        // Green Apple 和 Pineapple 都是包含匹配，按字母排序
        expect(result[2], 'Green Apple');
        expect(result[3], 'Pineapple');
      });

      test('应该处理带空格的查询', () {
        // Arrange
        final ingredients = [
          'Red Apple',
          'Green Apple',
          'Apple',
        ];

        // Act
        final result = IngredientListService.filterIngredients(
          ingredients,
          'red apple',
        );

        // Assert
        expect(result.length, 1);
        expect(result[0], 'Red Apple');
      });

      test('应该保持原始大小写', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'apple',
        );

        // Assert
        // 结果应该保持原始列表中的大小写
        expect(result, contains('Apple')); // 不是 'apple'
        expect(result, contains('Applesauce'));
        expect(result, contains('Pineapple'));
      });
    });
  });
}
