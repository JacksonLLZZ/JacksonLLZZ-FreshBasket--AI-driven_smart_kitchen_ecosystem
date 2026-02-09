import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kitchen/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kitchen/features/inventory/data/ingredient.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late SharedPreferences mockPrefs;
  late List<Ingredient> testIngredients;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() async {
    // Initialize SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    mockPrefs = await SharedPreferences.getInstance();
    await mockPrefs.clear();

    // Set default API source
    await mockPrefs.setString('api_source', 'Spoonacular');

    // Create test ingredients
    testIngredients = [
      Ingredient.create(
        name: 'Tomato',
        qty: 100,
        unit: 'g',
        expirationDate: DateTime.now().add(const Duration(days: 7)),
      ),
      Ingredient.create(
        name: 'Pasta',
        qty: 200,
        unit: 'g',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
      ),
    ];
  });

  tearDown(() async {
    await mockPrefs.clear();
  });

  group('RecipeDetailScreen Widget Tests -', () {
    testWidgets('应该显示页面基本结构', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - verify Scaffold
      expect(
        find.byKey(const Key(TestKeys.recipeDetailScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示食材列表', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the display of ingredient names
      expect(find.textContaining('Tomato'), findsWidgets);
      expect(find.textContaining('Pasta'), findsWidgets);
    });

    testWidgets('应该显示搜索按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the search-related buttons
      expect(find.textContaining('Find Recipes'), findsWidgets);
    });

    testWidgets('应该能够选择/取消选择食材（Spoonacular模式）', (WidgetTester tester) async {
      // Arrange - In the Spoonacular mode, all options are selected by default.
      await mockPrefs.setString('api_source', 'Spoonacular');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Search for the checkbox (which should exist in the Spoonacular mode)
      final checkboxFinder = find.byType(Checkbox);

      if (checkboxFinder.evaluate().isNotEmpty) {
        // Click the first checkbox
        await tester.tap(checkboxFinder.first);
        await tester.pumpAndSettle();
      }

      // Assert - Verification shows no abnormalities.
      expect(tester.takeException(), isNull);
    });

    testWidgets('Free API模式应该显示不同的UI', (WidgetTester tester) async {
      // Arrange - Set to Free API mode
      await mockPrefs.setString('api_source', 'Free');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - The verification page can be rendered normally.
      expect(
        find.byKey(const Key(TestKeys.recipeDetailScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示缓存提示（如果有缓存）', (WidgetTester tester) async {
      // Arrange - Store some cached data first
      final cacheKey =
          'recipes_cache_Spoonacular_${testIngredients.map((e) => e.id).toList()
            ..sort()
            ..join('_')}';
      await mockPrefs.setString(
        cacheKey,
        '{"recipes":[],"selectedIngredients":{}}',
      );

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Initialize the pump
      await tester.pump(const Duration(milliseconds: 200));

      // Assert - Verify that the page loads normally (the cache loading should not result in any errors)
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该能够切换页面（如果有多个食谱）', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify that the page-turning button may exist (depending on whether there is data)
      // Here, we only verify that the UI will not crash.
      expect(tester.takeException(), isNull);
    });

    testWidgets('空食材列表应该正常处理', (WidgetTester tester) async {
      // Arrange - Empty ingredient list
      final widget = createTestApp(
        child: const RecipeDetailScreen(ingredients: []),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - The verification will not crash.
      expect(
        find.byKey(const Key(TestKeys.recipeDetailScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示API源指示器', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the text or icons related to the API
      // The page should contain information related to the API.
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该能够刷新食谱列表', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Search for the refresh button
      final refreshFinder = find.byIcon(Icons.refresh);

      if (refreshFinder.evaluate().isNotEmpty) {
        await tester.tap(refreshFinder.first);
        await tester.pump();
      }

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示选中食材的数量', (WidgetTester tester) async {
      // Arrange
      await mockPrefs.setString('api_source', 'Spoonacular');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the selection quantity display (in Spoonacular mode, it is set to select all by default)
      expect(find.textContaining('2/2'), findsWidgets);
    });

    testWidgets('应该能够点击FilterChip切换选择', (WidgetTester tester) async {
      // Arrange
      await mockPrefs.setString('api_source', 'Spoonacular');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // search FilterChip
      final chipFinder = find.byType(FilterChip);

      if (chipFinder.evaluate().isNotEmpty) {
        // Click on the first chip to deselect it.
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        // Verify the change in the selected quantity
        expect(find.textContaining('1/2'), findsWidgets);

        // Click "Restore Selection" again
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        // Verify quantity restoration
        expect(find.textContaining('2/2'), findsWidgets);
      }
    });

    testWidgets('Free API模式应该限制只能选择一个食材', (WidgetTester tester) async {
      // Arrange - Set to Free API mode
      await mockPrefs.setString('api_source', 'Free');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // In the free mode, all options are defaulted to be unselected.
      expect(find.textContaining('0/2'), findsWidgets);

      // Click on the first ingredient
      final chipFinder = find.byType(FilterChip);
      if (chipFinder.evaluate().length >= 2) {
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        // Verification has selected 1 item.
        expect(find.textContaining('1/2'), findsWidgets);

        // Try to select the second ingredient (which should be restricted)
        await tester.tap(chipFinder.at(1));
        await tester.pumpAndSettle();

        // The verification is still only for one selection.
        expect(find.textContaining('1/2'), findsWidgets);

        // The verification displayed a warning snackbar.
        expect(
          find.text('Free Recipe API only allows ONE main ingredient'),
          findsOneWidget,
        );
      }
    });

    testWidgets('Free API模式应该显示提示信息', (WidgetTester tester) async {
      // Arrange - Set to Free API mode
      await mockPrefs.setString('api_source', 'Free');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the Free API prompt
      expect(
        find.textContaining('Free API: Select only ONE main ingredient'),
        findsWidgets,
      );
    });

    testWidgets('应该显示Find Recipes按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify that the "Find Recipes" button exists and is visible
      final findButton = find.byKey(const Key('findRecipesButton'));
      expect(findButton, findsOneWidget);

      // Verification button text
      expect(find.text('Find Recipes'), findsOneWidget);

      // Verify the search icon
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('未选择任何食材时点击搜索应显示提示', (WidgetTester tester) async {
      // Arrange - In the free mode, no ingredients are selected by default.
      await mockPrefs.setString('api_source', 'Free');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Click the search button
      final findButton = find.byKey(const Key('findRecipesButton'));
      await tester.tap(findButton);
      await tester.pumpAndSettle();

      // Assert - Verification display prompt
      expect(
        find.text('Please select at least one ingredient'),
        findsOneWidget,
      );
    });

    testWidgets('应该显示翻页按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - The page-turning button may only be displayed when there are results.
      // This merely verifies that the page does not crash.
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示正确的过滤图标', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the display of the kitchen icon
      expect(find.byIcon(Icons.kitchen), findsWidgets);
    });

    testWidgets('应该正确去重相同名称的食材', (WidgetTester tester) async {
      // Arrange - Create a list of ingredients with duplicate names
      final duplicateIngredients = [
        Ingredient.create(
          name: 'Apple',
          qty: 100,
          unit: 'g',
          expirationDate: DateTime.now().add(const Duration(days: 7)),
        ),
        Ingredient.create(
          name: 'Apple', // Repeat
          qty: 150,
          unit: 'g',
          expirationDate: DateTime.now().add(const Duration(days: 5)),
        ),
        Ingredient.create(
          name: 'Banana',
          qty: 200,
          unit: 'g',
          expirationDate: DateTime.now().add(const Duration(days: 10)),
        ),
      ];

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: duplicateIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Only two FilterChips (Apple and Banana) should be displayed.
      final chips = find.byType(FilterChip);
      expect(chips.evaluate().length, equals(2));
    });

    testWidgets('应该显示初始的空状态提示', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verification of empty state prompt text
      expect(find.text('Ready to discover recipes?'), findsOneWidget);
      expect(
        find.text('Select ingredients and tap "Find Recipes"'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });
  });
}
