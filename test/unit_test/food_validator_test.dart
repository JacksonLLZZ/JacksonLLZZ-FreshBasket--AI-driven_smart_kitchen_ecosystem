/// FoodValidator Tool testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/utils/food_validator.dart';

void main() {
  group('FoodValidator -', () {
    group('isSimilarName', () {
      test('应该识别完全相同的名称', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('Tomato', 'Tomato'), isTrue);
      });

      test('应该忽略大小写差异', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('Apple', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('TOMATO', 'tomato'), isTrue);
        expect(FoodValidator.isSimilarName('BaNaNa', 'banana'), isTrue);
        expect(FoodValidator.isSimilarName('ChIcKeN', 'CHICKEN'), isTrue);
      });

      test('应该忽略首尾空格', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('  apple', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('apple  ', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('  apple  ', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('  apple  ', '  apple  '), isTrue);
      });

      test('应该忽略中间的多个空格', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('red   apple', 'red apple'), isTrue);
        expect(FoodValidator.isSimilarName('green  bean', 'greenbean'), isTrue);
        expect(
          FoodValidator.isSimilarName('sweet    potato', 'sweetpotato'),
          isTrue,
        );
      });

      test('应该组合处理：忽略大小写和空格', () {
        // Act & Assert
        expect(
          FoodValidator.isSimilarName('  Red Apple  ', 'red apple'),
          isTrue,
        );
        expect(
          FoodValidator.isSimilarName('GREEN   BEAN', 'green bean'),
          isTrue,
        );
        expect(
          FoodValidator.isSimilarName('Sweet Potato', 'sweetpotato'),
          isTrue,
        );
        expect(
          FoodValidator.isSimilarName('  CHERRY   TOMATO  ', 'cherrytomato'),
          isTrue,
        );
      });

      test('应该区分不同的名称', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple', 'orange'), isFalse);
        expect(FoodValidator.isSimilarName('tomato', 'potato'), isFalse);
        expect(FoodValidator.isSimilarName('chicken', 'beef'), isFalse);
      });

      test('应该处理空字符串', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('', ''), isTrue);
        expect(FoodValidator.isSimilarName('apple', ''), isFalse);
        expect(FoodValidator.isSimilarName('', 'apple'), isFalse);
      });

      test('应该处理只包含空格的字符串', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('   ', '   '), isTrue);
        expect(FoodValidator.isSimilarName('   ', ''), isTrue);
        expect(FoodValidator.isSimilarName('apple', '   '), isFalse);
      });

      test('应该处理特殊字符（不被删除）', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple-pie', 'apple-pie'), isTrue);
        expect(FoodValidator.isSimilarName('apple-pie', 'applepie'), isFalse);
        expect(FoodValidator.isSimilarName('apple_pie', 'apple-pie'), isFalse);
      });

      test('应该处理数字', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple123', 'apple123'), isTrue);
        expect(FoodValidator.isSimilarName('Apple 123', 'apple123'), isTrue);
        expect(FoodValidator.isSimilarName('apple123', 'apple456'), isFalse);
      });

      test('应该处理 Unicode 字符', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('苹果', '苹果'), isTrue);
        expect(FoodValidator.isSimilarName('西红柿', '西红柿'), isTrue);
        expect(FoodValidator.isSimilarName('苹果', '西红柿'), isFalse);
        expect(FoodValidator.isSimilarName('  苹果  ', '苹果'), isTrue);
      });

      test('应该处理混合语言', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('Apple 苹果', 'apple 苹果'), isTrue);
        expect(FoodValidator.isSimilarName('Red Apple', 'red apple'), isTrue);
      });

      test('应该处理长字符串', () {
        // Act & Assert
        const long1 = 'This is a very long ingredient name with many words';
        const long2 = 'THIS IS A VERY LONG INGREDIENT NAME WITH MANY WORDS';
        const long3 =
            'this  is  a  very  long  ingredient  name  with  many  words';

        expect(FoodValidator.isSimilarName(long1, long2), isTrue);
        expect(FoodValidator.isSimilarName(long1, long3), isTrue);
      });
    });
  });
}
