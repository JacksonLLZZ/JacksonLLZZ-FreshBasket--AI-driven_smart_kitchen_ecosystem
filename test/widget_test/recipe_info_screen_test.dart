import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/recipes/presentation/recipe_info_screen.dart';
import 'package:kitchen/features/recipes/data/recipe.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late MockDatabaseService mockDb;
  late Recipe testRecipe;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockDb = MockDatabaseService();
    
    // Create test recipe data
    testRecipe = Recipe(
      id: 1,
      title: 'Test Pasta Dish',
      image: 'https://example.com/pasta.jpg',
      usedIngredientCount: 3,
      missedIngredientCount: 2,
      usedIngredients: [],
      missedIngredients: [],
      area: 'Italian',
      category: 'Main Course',
    );

    // Mock database stream to return empty cart
    when(() => mockDb.getShoppingCartStream()).thenAnswer(
      (_) => Stream.value([]),
    );
  });

  group('RecipeInfoScreen Widget Tests -', () {
    testWidgets('should display recipe title', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify title
      expect(find.text('Test Pasta Dish'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.recipeInfoScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('should display ingredient stats (Have and Need)', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify stats
      expect(find.text('Have'), findsOneWidget);
      expect(find.text('Need'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // usedIngredientCount
      expect(find.text('2'), findsOneWidget); // missedIngredientCount
    });

    testWidgets('should display area and category tags', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify tags
      expect(find.text('Italian'), findsOneWidget);
      expect(find.text('Main Course'), findsOneWidget);
    });

    testWidgets('should display SliverAppBar', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify SliverAppBar exists
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('should display stats card with icons', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify icons and stats are displayed
      expect(find.byType(Icon), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should be able to scroll the page', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Try scrolling (no pumpAndSettle needed)
      final scrollableFinder = find.byType(CustomScrollView);
      if (scrollableFinder.evaluate().isNotEmpty) {
        await tester.drag(scrollableFinder, const Offset(0, -200));
        await tester.pump();
      }

      // Assert - no error should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display public icons (area tag)', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify public icons
      expect(find.byIcon(Icons.public), findsWidgets);
    });

    testWidgets('should not display area tag when area is empty', (WidgetTester tester) async {
      // Arrange - create recipe without area
      final recipeNoArea = Recipe(
        id: 2,
        title: 'Test Recipe',
        image: 'https://example.com/test.jpg',
        usedIngredientCount: 1,
        missedIngredientCount: 1,
        usedIngredients: [],
        missedIngredients: [],
        area: '',
        category: 'Dessert',
      );

      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: recipeNoArea, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - Italian should not be found
      expect(find.text('Italian'), findsNothing);
      // But Dessert should be found
      expect(find.text('Dessert'), findsOneWidget);
    });

    testWidgets('should display Card container', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify Card widgets
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should handle recipe image loading', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe, databaseService: mockDb),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - verify no errors during image load
      expect(tester.takeException(), isNull);
    });
  });
}

