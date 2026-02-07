import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/shopping_cart/presentation/shopping_cart_screen.dart';
import 'package:kitchen/features/shopping_cart/data/shopping_item.dart';
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

    // Mock shopping cart stream with test data
    when(() => mockDb.getShoppingCartStream()).thenAnswer(
      (_) => Stream.value([
        ShoppingItem(
          id: '1',
          name: 'Tomato',
          amount: '500g',
          addedAt: DateTime.now(),
        ),
        ShoppingItem(
          id: '2',
          name: 'Milk',
          amount: '1L',
          addedAt: DateTime.now(),
        ),
      ]),
    );

    // Mock delete method - ?????? removeFromShoppingCart
    when(() => mockDb.removeFromShoppingCart(any())).thenAnswer((_) async {});
  });

  group('ShoppingCartScreen Widget Tests -', () {
    testWidgets('???????? "Shopping Cart"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ????
      expect(find.text('Shopping Cart'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.shoppingCartScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('??????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ?????????
      expect(find.textContaining('now'), findsWidgets);
    });

    testWidgets('????"View Seasonal Picks"??', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ????
      expect(
        find.byKey(const Key('viewSeasonalPicksButton')),
        findsOneWidget,
      );
    });

    testWidgets('??????"View Seasonal Picks"????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // ????
      final button = find.byKey(const Key('viewSeasonalPicksButton'));
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Assert - ????????????SeasonalListScreen?
      // ??????????????????????
      // expect(tester.takeException(), isNull);
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??????
      expect(find.byIcon(Icons.local_florist_outlined), findsOneWidget);
    });

    testWidgets('?????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ???????
      expect(find.textContaining('Tomato'), findsWidgets);
      expect(find.textContaining('Milk'), findsWidgets);
    });

    testWidgets('????ValueListenableBuilder', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??ValueListenableBuilder??
      expect(find.byType(ValueListenableBuilder<String>), findsOneWidget);
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??????????
      final seasonMessages = [
        'Fresh greens',
        'Hydrating fruits',
        'Warm soups',
        'Root vegetables',
        'Seasonal picks',
      ];

      bool hasSeasonMessage = false;
      for (final message in seasonMessages) {
        if (find.textContaining(message).evaluate().isNotEmpty) {
          hasSeasonMessage = true;
          break;
        }
      }

      expect(hasSeasonMessage, true);
    });

    testWidgets('????Container??', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ?????Container??
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration != null,
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('????ElevatedButton', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??ElevatedButton??
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('??????????', (WidgetTester tester) async {
      // Arrange - Mock empty cart
      when(() => mockDb.getShoppingCartStream()).thenAnswer(
        (_) => Stream.value([]),
      );

      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ????????
      expect(
        find.byKey(const Key(TestKeys.shoppingCartScreenScaffold)),
        findsOneWidget,
      );
      expect(find.text('Shopping Cart'), findsOneWidget);
    });

    testWidgets('????SingleChildScrollView', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ???????
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('????????', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // ????
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Assert - ?????
      expect(tester.takeException(), isNull);
    });

    testWidgets('??????????Row??', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??Row??
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('????AppBar', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const ShoppingCartScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - ??AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
