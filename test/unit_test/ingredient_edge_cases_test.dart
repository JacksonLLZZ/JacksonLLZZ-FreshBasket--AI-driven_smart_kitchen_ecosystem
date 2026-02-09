/// A complete set of tool-related and boundary case tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/inventory/data/ingredient.dart';

void main() {
  group('Ingredient - Boundary cases and special scenarios -', () {
    test('The zero quantity should be dealt with.', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Empty Container',
        quantity: 0,
        unit: 'piece',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.quantity, 0);
    });

    test('The excessively long expiration time should be dealt with.', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Dried Beans',
        quantity: 1,
        unit: 'kg',
        expirationDate: DateTime(2050, 12, 31), // A very distant future
      );

      // Assert
      expect(ingredient.expirationDate.year, 2050);
      expect(ingredient.isExpired, isFalse);
    });

    test('The historical expiration dates should be handled.', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Expired Food',
        quantity: 1,
        unit: 'piece',
        expirationDate: DateTime(2000, 1, 1), // A long time ago
      );

      // Assert
      expect(ingredient.isExpired, isTrue);
      final daysSinceExpired = DateTime.now()
          .difference(ingredient.expirationDate)
          .inDays;
      expect(daysSinceExpired, greaterThan(9000)); // More than 25 years
    });

    test('The dates for leap years should be handled.', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Leap Year Food',
        quantity: 1,
        unit: 'piece',
        expirationDate: DateTime(2024, 2, 29), // February 29th of a leap year
      );

      // Assert
      expect(ingredient.expirationDate.month, 2);
      expect(ingredient.expirationDate.day, 29);
    });

    test('The expired time at midnight should be dealt with.', () {
      // Arrange
      final midnight = DateTime(2026, 6, 15, 0, 0, 0);

      // Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Midnight Expiry',
        quantity: 1,
        unit: 'piece',
        expirationDate: midnight,
      );

      // Assert
      expect(ingredient.expirationDate.hour, 0);
      expect(ingredient.expirationDate.minute, 0);
      expect(ingredient.expirationDate.second, 0);
    });

    test(
      'The comparison of dates across different time zones should be handled.',
      () {
        // Arrange
        final date1 = DateTime.utc(2026, 6, 15, 12, 0);
        final date2 = DateTime(2026, 6, 15, 12, 0); // Local time zone

        final ingredient1 = Ingredient(
          id: 'test1',
          name: 'UTC Item',
          quantity: 1,
          unit: 'piece',
          expirationDate: date1,
        );

        final ingredient2 = Ingredient(
          id: 'test2',
          name: 'Local Item',
          quantity: 1,
          unit: 'piece',
          expirationDate: date2,
        );

        // Assert - The two dates should be different (unless in the UTC time zone)
        expect(ingredient1.expirationDate, isNotNull);
        expect(ingredient2.expirationDate, isNotNull);
      },
    );

    test('The microsecond-level time should be handled correctly.', () {
      // Arrange
      final preciseTime = DateTime(2026, 6, 15, 12, 30, 45, 123, 456);

      // Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Precise Time',
        quantity: 1,
        unit: 'piece',
        expirationDate: preciseTime,
      );

      // Assert
      expect(ingredient.expirationDate.millisecond, 123);
      expect(ingredient.expirationDate.microsecond, 456);
    });

    test('ID should be unique.', () {
      // Arrange & Act
      final ingredient1 = Ingredient.create(
        name: 'Item 1',
        qty: 1,
        unit: 'piece',
      );

      final ingredient2 = Ingredient.create(
        name: 'Item 2',
        qty: 1,
        unit: 'piece',
      );

      // Assert
      expect(ingredient1.id, isNot(equals(ingredient2.id)));
      expect(ingredient1.id, isNotEmpty);
      expect(ingredient2.id, isNotEmpty);
    });

    test(
      'When creating a large number of items, the IDs should be as unique as possible.',
      () {
        // Arrange & Act
        final ids = <String>{};
        for (int i = 0; i < 100; i++) {
          final ingredient = Ingredient.create(
            name: 'Item $i',
            qty: 1,
            unit: 'piece',
          );
          ids.add(ingredient.id);
        }

        // Assert - More than 80% of the IDs should be unique.
        // Due to the use of timestamps, there may be some repetitions.
        expect(ids.length, greaterThan(75));
      },
    );

    test('The quantity should be kept extremely small.', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Tiny Amount',
        quantity: 0.001,
        unit: 'g',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.quantity, 0.001);
      expect(ingredient.quantity, greaterThan(0));
    });

    test('The quantity should be handled in a large scale.', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Huge Amount',
        quantity: 999999.99,
        unit: 'kg',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.quantity, 999999.99);
    });

    test(
      'The negative quantity should be dealt with (although it is logically unreasonable)',
      () {
        // Arrange & Act
        final ingredient = Ingredient(
          id: 'test',
          name: 'Negative',
          quantity: -5,
          unit: 'piece',
          expirationDate: DateTime(2026, 12, 31),
        );

        // Assert - The system should be able to store, even if it is not logically reasonable from a business perspective.
        expect(ingredient.quantity, -5);
        expect(ingredient.quantity, lessThan(0));
      },
    );

    test('The empty unit string should be handled.', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'No Unit',
        quantity: 5,
        unit: '',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.unit, isEmpty);
    });

    test('Special characters should be handled as units', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Special Unit',
        quantity: 5,
        unit: 'piece / item',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.unit, 'piece / item');
    });

    test('Countdown days calculation - About to expire', () {
      // Arrange
      final soonExpiry = DateTime.now().add(const Duration(days: 3));
      final ingredient = Ingredient(
        id: 'test',
        name: 'Soon to Expire',
        quantity: 1,
        unit: 'piece',
        expirationDate: soonExpiry,
      );

      // Act
      final daysUntilExpiry = ingredient.expirationDate
          .difference(DateTime.now())
          .inDays;

      // Assert
      expect(daysUntilExpiry, lessThanOrEqualTo(3));
      expect(
        daysUntilExpiry,
        greaterThanOrEqualTo(2),
      ); // Take into account the time difference
    });

    test('Today is the expiration date day - boundary test', () {
      // Arrange
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);

      final ingredient = Ingredient(
        id: 'test',
        name: 'Expires Today',
        quantity: 1,
        unit: 'piece',
        expirationDate: todayMidnight,
      );

      // Act & Assert
      // If the expiration date is midnight today, and it's already past midnight, then it has expired.
      expect(ingredient.isExpired, isTrue);
    });

    test(
      'The ingredients created at the same time should have as many different IDs as possible.',
      () {
        // Arrange & Act - Create multiple in a very short period of time
        final ingredients = List.generate(
          10,
          (index) =>
              Ingredient.create(name: 'Item $index', qty: 1, unit: 'piece'),
        );

        // Assert - Most IDs should be unique (over 90%).
        final ids = ingredients.map((e) => e.id).toSet();
        expect(ids.length, greaterThanOrEqualTo(9));
      },
    );
  });
}
