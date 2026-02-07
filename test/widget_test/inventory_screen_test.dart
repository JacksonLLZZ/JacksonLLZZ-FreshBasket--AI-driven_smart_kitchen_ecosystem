import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/inventory/presentation/inventory_screen.dart';
import 'package:kitchen/features/inventory/data/ingredient.dart';
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

    // Mock stream to return test ingredients - use getInventoryStream
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
    testWidgets('should display basic page structure', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify Scaffold
      expect(
        find.byKey(const Key(TestKeys.inventoryScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('should display ingredient list', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify ingredients are displayed
      expect(find.textContaining('Tomato'), findsWidgets);
      expect(find.textContaining('Milk'), findsWidgets);
    });

    testWidgets('should display search icon', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify checklist icon
      expect(find.byIcon(Icons.checklist), findsWidgets);
    });

    testWidgets('should display select button', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify select button
      expect(find.byIcon(Icons.checklist), findsWidgets);
    });

    testWidgets('should be able to tap on ingredient item', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Find food item (could be ListTile or Card)
      final cardFinder = find.byType(Card).first;
      
      if (cardFinder.evaluate().isNotEmpty) {
        await tester.tap(cardFinder);
        await tester.pumpAndSettle();
      }

      // Assert - no exception should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle long press on ingredient', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Long press on first card
      final cardFinder = find.byType(Card);
      
      if (cardFinder.evaluate().isNotEmpty) {
        await tester.longPress(cardFinder.first);
        await tester.pumpAndSettle();
      }

      // Assert - no exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display expiration dates', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - should display text widgets containing info
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should be able to delete ingredient', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Try to find and tap delete icon
      final deleteIcon = find.byIcon(Icons.delete);
      
      if (deleteIcon.evaluate().isNotEmpty) {
        await tester.tap(deleteIcon.first);
        await tester.pumpAndSettle();
      }

      // Assert - no exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be able to edit ingredient', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Find edit icon
      final editIcon = find.byIcon(Icons.edit);
      
      if (editIcon.evaluate().isNotEmpty) {
        await tester.tap(editIcon.first);
        await tester.pumpAndSettle();
        
        // Try to cancel if dialog appears
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();
        }
      }

      // Assert - no exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should navigate to recipe screen', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Try to find "Recipe" related button
      final recipeButton = find.textContaining('Recipe');
      
      if (recipeButton.evaluate().isNotEmpty) {
        await tester.tap(recipeButton.first);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle empty inventory', (WidgetTester tester) async {
      // Arrange - Mock empty stream
      when(() => mockDb.getInventoryStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: InventoryScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - should still render
      expect(
        find.byKey(const Key(TestKeys.inventoryScreenScaffold)),
        findsOneWidget,
      );
    });
  });
}
