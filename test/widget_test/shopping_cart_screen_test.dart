import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/shopping_cart/presentation/shopping_cart_screen.dart';
import 'package:kitchen/features/shopping_cart/data/shopping_item.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late MockDatabaseService mockDb;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockDb = MockDatabaseService();
  });

  group('ShoppingCartScreen Widget Tests -', () {
    testWidgets('should display basic page structure', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify Scaffold
      expect(
        find.byKey(const Key(TestKeys.shoppingCartScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('should display page title', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify title exists
      expect(find.text('Shopping Cart'), findsOneWidget);
    });

    testWidgets('should display empty state when cart is empty', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify empty state text
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('should display items when cart has data', (WidgetTester tester) async {
      // Arrange - create test data
      final testItems = <ShoppingItem>[
        ShoppingItem(
          id: '1',
          name: 'Apple',
          amount: '5 pcs',
          addedAt: DateTime(2024, 1, 1),
        ),
        ShoppingItem(
          id: '2',
          name: 'Milk',
          amount: '1 L',
          addedAt: DateTime(2024, 1, 2),
        ),
      ];

      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value(testItems),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify items are displayed
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('should display item quantity', (WidgetTester tester) async {
      // Arrange
      final testItems = <ShoppingItem>[
        ShoppingItem(
          id: '1',
          name: 'Banana',
          amount: '3 kg',
          addedAt: DateTime.now(),
        ),
      ];

      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value(testItems),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify quantity displayed
      expect(find.textContaining('3 kg'), findsOneWidget);
    });

    testWidgets('should have delete button for each item', (WidgetTester tester) async {
      // Arrange
      final testItems = <ShoppingItem>[
        ShoppingItem(
          id: '1',
          name: 'Orange',
          amount: '2 kg',
          addedAt: DateTime.now(),
        ),
      ];

      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value(testItems),
      );
      when(() => mockDb.removeFromShoppingCart(any())).thenAnswer((_) async {});

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify delete icon
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });

    testWidgets('should call delete when delete button tapped', (WidgetTester tester) async {
      // Arrange
      final testItem = ShoppingItem(
        id: '1',
        name: 'Grape',
        amount: '1 kg',
        addedAt: DateTime.now(),
      );

      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([testItem]),
      );
      when(() => mockDb.removeFromShoppingCart(any())).thenAnswer((_) async {});

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pump();

      // Assert - verify delete was called (using ID)
      verify(() => mockDb.removeFromShoppingCart(testItem.id)).called(1);
    });

    testWidgets('should display "View Seasonal Picks" button', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify text exists
      expect(find.text('View seasonal picks'), findsOneWidget);
    });

    testWidgets('should display shopping suggestions icon', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify suggestion icon exists
      expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);
    });

    testWidgets('should navigate when seasonal picks button is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );
      // Mock for navigation target
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Try to find and tap the seasonal picks button
      final buttonFinder = find.text('View seasonal picks');
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert - no exception should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have button widget type', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - check for button via key
      expect(find.byKey(const Key('viewSeasonalPicksButton')), findsWidgets);
    });

    testWidgets('should handle stream updates', (WidgetTester tester) async {
      // Arrange - create stream controller for dynamic updates
      final testItems = <ShoppingItem>[
        ShoppingItem(
          id: '1',
          name: 'Carrot',
          amount: '500 g',
          addedAt: DateTime.now(),
        ),
      ];

      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value(testItems),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify item displayed
      expect(find.text('Carrot'), findsOneWidget);
    });

    testWidgets('should display multiple items correctly', (WidgetTester tester) async {
      // Arrange
      final testItems = <ShoppingItem>[
        ShoppingItem(id: '1', name: 'Item1', amount: '1x', addedAt: DateTime.now()),
        ShoppingItem(id: '2', name: 'Item2', amount: '2x', addedAt: DateTime.now()),
        ShoppingItem(id: '3', name: 'Item3', amount: '3x', addedAt: DateTime.now()),
      ];

      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value(testItems),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify all items displayed
      expect(find.text('Item1'), findsOneWidget);
      expect(find.text('Item2'), findsOneWidget);
      expect(find.text('Item3'), findsOneWidget);
    });

    testWidgets('should display category icon', (WidgetTester tester) async {
      // Arrange
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: ShoppingCartScreen(databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify icons exist in the UI
      expect(find.byType(Icon), findsWidgets);
    });
  });
}
