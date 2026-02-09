/// FoodValidator Tool testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/core/utils/food_validator.dart';

void main() {
  group('FoodValidator -', () {
    group('isSimilarName', () {
      test('The exact same names should be identified.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('Tomato', 'Tomato'), isTrue);
      });

      test('The differences in capitalization should be ignored.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('Apple', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('TOMATO', 'tomato'), isTrue);
        expect(FoodValidator.isSimilarName('BaNaNa', 'banana'), isTrue);
        expect(FoodValidator.isSimilarName('ChIcKeN', 'CHICKEN'), isTrue);
      });

      test('The leading and trailing spaces should be ignored.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('  apple', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('apple  ', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('  apple  ', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('  apple  ', '  apple  '), isTrue);
      });

      test('The multiple spaces in the middle should be ignored.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('red   apple', 'red apple'), isTrue);
        expect(FoodValidator.isSimilarName('green  bean', 'greenbean'), isTrue);
        expect(
          FoodValidator.isSimilarName('sweet    potato', 'sweetpotato'),
          isTrue,
        );
      });

      test('It should be processed together: ignore case and spaces.', () {
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

      test('Different names should be distinguished.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple', 'orange'), isFalse);
        expect(FoodValidator.isSimilarName('tomato', 'potato'), isFalse);
        expect(FoodValidator.isSimilarName('chicken', 'beef'), isFalse);
      });

      test('The empty string should be handled.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('', ''), isTrue);
        expect(FoodValidator.isSimilarName('apple', ''), isFalse);
        expect(FoodValidator.isSimilarName('', 'apple'), isFalse);
      });

      test('Strings that contain only spaces should be handled.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('   ', '   '), isTrue);
        expect(FoodValidator.isSimilarName('   ', ''), isTrue);
        expect(FoodValidator.isSimilarName('apple', '   '), isFalse);
      });

      test('Special characters should be handled (and not be deleted).', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple-pie', 'apple-pie'), isTrue);
        expect(FoodValidator.isSimilarName('apple-pie', 'applepie'), isFalse);
        expect(FoodValidator.isSimilarName('apple_pie', 'apple-pie'), isFalse);
      });

      test('The numbers should be dealt with.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('apple123', 'apple123'), isTrue);
        expect(FoodValidator.isSimilarName('Apple 123', 'apple123'), isTrue);
        expect(FoodValidator.isSimilarName('apple123', 'apple456'), isFalse);
      });

      test('Unicode characters should be handled.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('Apple', 'Apple'), isTrue);
        expect(FoodValidator.isSimilarName('Tomato', 'Tomato'), isTrue);
        expect(FoodValidator.isSimilarName('Apple', 'Tomato'), isFalse);
        expect(FoodValidator.isSimilarName('  Apple  ', 'Apple'), isTrue);
      });

      test('The mixed language should be dealt with.', () {
        // Act & Assert
        expect(FoodValidator.isSimilarName('Apple', 'apple'), isTrue);
        expect(FoodValidator.isSimilarName('Red Apple', 'red apple'), isTrue);
      });

      test('Long strings should be handled.', () {
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
