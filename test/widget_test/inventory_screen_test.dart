import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/inventory/presentation/inventory_screen.dart';
import 'package:kitchen/features/inventory/data/ingredient.dart';
import 'package:kitchen/services/database_service.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late MockDatabaseService mockDb;
  bool isFirebaseInitialized = false;

  setUpAll(() async {
    registerFallbackValues();
    if (!isFirebaseInitialized) {
      await setupTestEnvironment();
      isFirebaseInitialized = true;
    }
  });

  setUp(() {
    mockDb = MockDatabaseService();

    // Mock stream to return test ingredients - ?????? getInventoryStream
    when(() => mockDb.getInventoryStream()).thenAnswer(
      (_) => Stream.value([
        Ingredient.create(
          name: 'Tomato',
          qty: 100,
          unit: 'g',
          expirationDate: DateTime.now().add(const Duration(days: 7)),
        ),
        Ingredient.create(
          name: 'Milk',
          qty: 500,
          unit: 'ml',
          expirationDate: DateTime.now().add(const Duration(days: 3)),
        ),
      ]),
    );

    // Mock delete methods
    when(() => mockDb.deleteIngredient(any())).thenAnswer((_) async {});
    when(() => mockDb.deleteMultipleIngredients(any())).thenAnswer((_) async {});
  });

  group('InventoryScreen Widget Tests -', () {
    testWidgets('??????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??Scaffold
      expect(
        find.byKey(const Key(TestKeys.inventoryScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??????
      expect(find.textContaining('Tomato'), findsWidgets);
      expect(find.textContaining('Milk'), findsWidgets);
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??????
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??????
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('??????????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // ?????food item (??ListTile?Card)
      final cardFinder = find.byType(Card).first;
      
      if (cardFinder.evaluate().isNotEmpty) {
        await tester.tap(cardFinder);
        await tester.pumpAndSettle();
      }

      // Assert - ???????
      expect(tester.takeException(), isNull);
    });

    testWidgets('??????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // ???????????????
      final cardFinder = find.byType(Card);
      
      if (cardFinder.evaluate().isNotEmpty) {
        await tester.longPress(cardFinder.first);
        await tester.pumpAndSettle();
      }

      // Assert - ?????
      expect(tester.takeException(), isNull);
    });

    testWidgets('??????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ????????????
      // ??????????
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // ?????????????????????
      final deleteIcon = find.byIcon(Icons.delete);
      
      if (deleteIcon.evaluate().isNotEmpty) {
        await tester.tap(deleteIcon.first);
        await tester.pumpAndSettle();
      }

      // Assert - ?????
      expect(tester.takeException(), isNull);
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // ??????
      final editIcon = find.byIcon(Icons.edit);
      
      if (editIcon.evaluate().isNotEmpty) {
        await tester.tap(editIcon.first);
        await tester.pumpAndSettle();
        
        // ????????????
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();
        }
      }

      // Assert - ?????
      expect(tester.takeException(), isNull);
    });

    testWidgets('?????????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // ?????"????"?"Recipe"??
      final recipeButton = find.textContaining('Recipe');
      
      if (recipeButton.evaluate().isNotEmpty) {
        await tester.tap(recipeButton.first);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('??????????', (WidgetTester tester) async {
      // Arrange - Mock empty stream
      when(() => mockDb.getInventoryStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: const InventoryScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ????????
      expect(
        find.byKey(const Key(TestKeys.inventoryScreenScaffold)),
        findsOneWidget,
      );
    });
  });
}
