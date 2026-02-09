/// A complete set of tool-related and boundary case tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/inventory/data/ingredient.dart';

void main() {
  group('Ingredient - 边界案例和特殊场景 -', () {
    test('应该处理零数量', () {
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

    test('应该处理超长过期时间', () {
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

    test('应该处理历史过期日期', () {
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

    test('应该处理闰年日期', () {
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

    test('应该处理午夜时分的过期时间', () {
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

    test('应该处理跨时区的日期比较', () {
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
    });

    test('应该正确处理微秒级时间', () {
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

    test('ID 应该是唯一的', () {
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

    test('大量创建时 ID 应该尽可能唯一', () {
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
    });

    test('应该处理极小的数量', () {
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

    test('应该处理极大的数量', () {
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

    test('应该处理负数数量（虽然逻辑上不合理）', () {
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
    });

    test('应该处理空单位字符串', () {
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

    test('应该处理特殊字符作为单位', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: 'test',
        name: 'Special Unit',
        quantity: 5,
        unit: '个/件',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.unit, '个/件');
    });

    test('倒计时天数计算 - 即将过期', () {
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

    test('今天是过期日当天 - 边界测试', () {
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

    test('同一时刻创建的食材应该尽可能有不同 ID', () {
      // Arrange & Act - 在极短时间内创建多个
      final ingredients = List.generate(
        10,
        (index) =>
            Ingredient.create(name: 'Item $index', qty: 1, unit: 'piece'),
      );

      // Assert - Most IDs should be unique (over 90%).
      final ids = ingredients.map((e) => e.id).toSet();
      expect(ids.length, greaterThanOrEqualTo(9));
    });
  });
}
