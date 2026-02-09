/// Ingredient data model test
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen/features/inventory/data/ingredient.dart';

void main() {
  group('Ingredient Model -', () {
    test('应该正确创建 Ingredient 实例', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: '1',
        name: 'Apple',
        quantity: 5,
        unit: 'pieces',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.id, '1');
      expect(ingredient.name, 'Apple');
      expect(ingredient.quantity, 5);
      expect(ingredient.unit, 'pieces');
      expect(ingredient.expirationDate, DateTime(2026, 12, 31));
    });

    test('应该通过工厂方法创建 Ingredient', () {
      // Arrange & Act
      final ingredient = Ingredient.create(
        name: 'Milk',
        qty: 1,
        unit: 'liter',
        expirationDate: DateTime(2026, 2, 15),
      );

      // Assert
      expect(ingredient.name, 'Milk');
      expect(ingredient.quantity, 1);
      expect(ingredient.unit, 'liter');
      expect(ingredient.expirationDate, DateTime(2026, 2, 15));
      expect(ingredient.id, isNotEmpty);
    });

    test('工厂方法应该使用默认过期日期', () {
      // Arrange & Act
      final ingredient = Ingredient.create(name: 'Bread', qty: 1, unit: 'loaf');

      // Assert
      final now = DateTime.now();
      final expectedDate = now.add(const Duration(days: 7));
      expect(ingredient.expirationDate.isAfter(now), isTrue);
      // 允许一些时间差异（1天内）
      final difference = ingredient.expirationDate.difference(expectedDate);
      expect(difference.inHours.abs(), lessThan(24));
    });

    test('应该正确判断是否过期', () {
      // Arrange
      final expiredIngredient = Ingredient(
        id: '3',
        name: 'Old Bread',
        quantity: 1,
        unit: 'loaf',
        expirationDate: DateTime(2020, 1, 1),
      );

      final freshIngredient = Ingredient(
        id: '4',
        name: 'Fresh Bread',
        quantity: 1,
        unit: 'loaf',
        expirationDate: DateTime(2030, 1, 1),
      );

      // Act & Assert
      expect(expiredIngredient.isExpired, isTrue);
      expect(freshIngredient.isExpired, isFalse);
    });

    test('应该正确判断今天过期的食材', () {
      // Arrange
      final todayIngredient = Ingredient(
        id: '5',
        name: 'Today Expiring',
        quantity: 1,
        unit: 'piece',
        expirationDate: DateTime.now().subtract(const Duration(hours: 1)),
      );

      // Act & Assert
      expect(todayIngredient.isExpired, isTrue);
    });

    test('quantity 应该支持小数', () {
      // Arrange & Act
      final ingredient = Ingredient(
        id: '6',
        name: 'Flour',
        quantity: 2.5,
        unit: 'kg',
        expirationDate: DateTime(2026, 12, 31),
      );

      // Assert
      expect(ingredient.quantity, 2.5);
      expect(ingredient.quantity, isA<double>());
    });
  });
}
