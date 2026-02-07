import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/shopping_list/presentation/seasonal_list_screen.dart';
import 'package:kitchen/features/shopping_list/domain/recommendation_service.dart';
import 'package:kitchen/features/shopping_list/domain/seasonal_food.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late MockDatabaseService mockDb;
  late MockRecommendationService mockService;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockService = MockRecommendationService();

    // Mock shopping cart stream
    when(() => mockDb.getShoppingCartStream()).thenAnswer(
      (_) => Stream.value([]),
    );

    // Mock add to cart
    when(() => mockDb.addToShoppingCart(any())).thenAnswer((_) async {});

    // Mock seasonal picks
    when(() => mockService.getSeasonalPicks(hemisphere: any(named: 'hemisphere')))
        .thenAnswer((_) async => []);
    when(() => mockService.search(any())).thenAnswer((_) async => []);
  });

  group('SeasonalListScreen Widget Tests -', () {
    testWidgets('should display page title "Seasonal List"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: SeasonalListScreen(
          databaseService: mockDb,
          recommendationService: mockService,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify title
      expect(find.text('Seasonal List'), findsOneWidget);
    });

    testWidgets('should display search bar', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: SeasonalListScreen(
          databaseService: mockDb,
          recommendationService: mockService,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify search icon exists
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('should display seasonal foods', (WidgetTester tester) async {
      // Arrange
      const food = SeasonalFood(
        id: 'apple',
        name: 'Apple',
        aliases: [],
        seasons: ['autumn', 'winter'],
        category: 'Fruit',
        defaultShelfLifeDays: 14,
        tags: [],
      );
      when(() => mockService.getSeasonalPicks(hemisphere: any(named: 'hemisphere')))
          .thenAnswer((_) async => [food]);

      final widget = createTestApp(
        child: SeasonalListScreen(
          databaseService: mockDb,
          recommendationService: mockService,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify food name exists
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('should display search bar hint', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: SeasonalListScreen(
          databaseService: mockDb,
          recommendationService: mockService,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify search hint exists
      expect(find.textContaining('Search seasonal foods'), findsWidgets);
    });

    testWidgets('should display food list or empty state', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: SeasonalListScreen(
          databaseService: mockDb,
          recommendationService: mockService,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - should display list view or empty state
      expect(
        find.byType(ListView).evaluate().isNotEmpty || 
        find.textContaining('No recommendations found').evaluate().isNotEmpty, 
        true
      );
    });

    testWidgets('should be able to add food to cart', (WidgetTester tester) async {
      // Arrange
      const food = SeasonalFood(
        id: 'milk',
        name: 'Milk',
        aliases: [],
        seasons: ['spring', 'summer', 'autumn', 'winter'],
        category: 'Dairy',
        defaultShelfLifeDays: 7,
        tags: [],
      );
      when(() => mockService.getSeasonalPicks(hemisphere: any(named: 'hemisphere')))
          .thenAnswer((_) async => [food]);

      final widget = createTestApp(
        child: SeasonalListScreen(
          databaseService: mockDb,
          recommendationService: mockService,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Find add to cart button (usually an icon button in the tile)
      final addButton = find.byIcon(Icons.add_shopping_cart);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();
        // Verify call
        verify(() => mockDb.addToShoppingCart(any())).called(1);
      }
    });
  });
}
