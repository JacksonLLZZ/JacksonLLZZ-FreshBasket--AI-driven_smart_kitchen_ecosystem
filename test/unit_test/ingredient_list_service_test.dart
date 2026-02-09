/// IngredientListService Tool testing
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

      test('The empty query should return an empty list.', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          '',
        );

        // Assert
        expect(result, isEmpty);
      });

      test(
        'All the ingredients should be returned along with the query string.',
        () {
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
        },
      );

      test('The capitalization should be ignored.', () {
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

      test('A perfect match should be ranked first.', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'apple',
        );

        // Assert
        expect(result.isNotEmpty, isTrue);
        expect(result.first.toLowerCase(), 'apple');
      });

      test(
        'Queries that start with the search term should take precedence over other matches.',
        () {
          // Act
          final result = IngredientListService.filterIngredients(
            testIngredients,
            'ap',
          );

          // Assert
          // Apple, Applesauce, Apricot should be placed before Grape, Grapefruit, Pineapple.
          final appleIndex = result.indexOf('Apple');
          final apricotIndex = result.indexOf('Apricot');
          final grapeIndex = result.indexOf('Grape');
          final pineappleIndex = result.indexOf('Pineapple');

          expect(appleIndex, lessThan(grapeIndex));
          expect(appleIndex, lessThan(pineappleIndex));
          expect(apricotIndex, lessThan(grapeIndex));
        },
      );

      test('Within the same category, it should be sorted alphabetically.', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'berry',
        );

        // Assert - Both Blueberry and Strawberry contain the word "berry"
        expect(result.length, 2);
        expect(result[0], 'Blueberry'); // B is in front of S
        expect(result[1], 'Strawberry');
      });

      test('The partial matching should be handled.', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'ato',
        );

        // Assert
        expect(result, contains('Tomato'));
        expect(result, contains('Potato'));
      });

      test('When there is no match, an empty list should be returned.', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'xyz',
        );

        // Assert
        expect(result, isEmpty);
      });

      test('Single-character queries should be processed', () {
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

      test('An empty list of ingredients should be handled', () {
        // Act
        final result = IngredientListService.filterIngredients([], 'apple');

        // Assert
        expect(result, isEmpty);
      });

      test(
        'Sort precedence: full matches > beginning matches > including matches',
        () {
          // Arrange
          final ingredients = [
            'Pineapple', // contain apple
            'Apple', // Perfect match apple
            'Applesauce', // head matching apple
            'Green Apple', // contain apple
          ];

          // Act
          final result = IngredientListService.filterIngredients(
            ingredients,
            'apple',
          );

          // Assert
          expect(result.length, 4);
          expect(result[0].toLowerCase(), 'apple'); // Perfect match first
          expect(
            result[1],
            'Applesauce',
          ); // The beginning matches the second one.
          // Green Apple and Pineapple are both included in the match and are sorted alphabetically.
          expect(result[2], 'Green Apple');
          expect(result[3], 'Pineapple');
        },
      );

      test('Queries with Spaces should be processed', () {
        // Arrange
        final ingredients = ['Red Apple', 'Green Apple', 'Apple'];

        // Act
        final result = IngredientListService.filterIngredients(
          ingredients,
          'red apple',
        );

        // Assert
        expect(result.length, 1);
        expect(result[0], 'Red Apple');
      });

      test('The original case should be kept.', () {
        // Act
        final result = IngredientListService.filterIngredients(
          testIngredients,
          'apple',
        );

        // Assert
        // The result should maintain the capitalization as it is in the original list.
        expect(result, contains('Apple')); // not 'apple'
        expect(result, contains('Applesauce'));
        expect(result, contains('Pineapple'));
      });
    });
  });
}
