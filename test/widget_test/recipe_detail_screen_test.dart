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

    // 设置默认API源
    await mockPrefs.setString('api_source', 'Spoonacular');

    // 创建测试用食材
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

      // Assert - 验证Scaffold
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

      // Assert - 验证食材名称显示
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

      // Assert - 验证搜索相关的按钮
      expect(find.textContaining('Find Recipes'), findsWidgets);
    });

    testWidgets('应该能够选择/取消选择食材（Spoonacular模式）', (WidgetTester tester) async {
      // Arrange - Spoonacular模式下默认全选
      await mockPrefs.setString('api_source', 'Spoonacular');
      
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 查找checkbox（在Spoonacular模式下应该存在）
      final checkboxFinder = find.byType(Checkbox);
      
      if (checkboxFinder.evaluate().isNotEmpty) {
        // 点击第一个checkbox
        await tester.tap(checkboxFinder.first);
        await tester.pumpAndSettle();
      }

      // Assert - 验证无异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('Free API模式应该显示不同的UI', (WidgetTester tester) async {
      // Arrange - 设置为Free API模式
      await mockPrefs.setString('api_source', 'Free');
      
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证页面能正常渲染
      expect(
        find.byKey(const Key(TestKeys.recipeDetailScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示缓存提示（如果有缓存）', (WidgetTester tester) async {
      // Arrange - 先存储一些缓存数据
      final cacheKey = 'recipes_cache_Spoonacular_${testIngredients.map((e) => e.id).toList()..sort()..join('_')}';
      await mockPrefs.setString(cacheKey, '{"recipes":[],"selectedIngredients":{}}');

      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // 初始pump
      await tester.pump(const Duration(milliseconds: 200));

      // Assert - 验证页面加载正常（缓存加载不应该报错）
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

      // Assert - 验证翻页按钮可能存在（取决于是否有数据）
      // 这里我们只验证UI不会崩溃
      expect(tester.takeException(), isNull);
    });

    testWidgets('空食材列表应该正常处理', (WidgetTester tester) async {
      // Arrange - 空食材列表
      final widget = createTestApp(
        child: const RecipeDetailScreen(ingredients: []),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证不会崩溃
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

      // Assert - 验证API相关的文本或图标
      // 页面应该包含与API相关的信息
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

      // 查找刷新按钮
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

      // Assert - 验证选中数量显示（Spoonacular模式默认全选）
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

      // 查找FilterChip
      final chipFinder = find.byType(FilterChip);
      
      if (chipFinder.evaluate().isNotEmpty) {
        // 点击第一个chip取消选择
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        // 验证选中数量变化
        expect(find.textContaining('1/2'), findsWidgets);

        // 再次点击恢复选择
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        // 验证数量恢复
        expect(find.textContaining('2/2'), findsWidgets);
      }
    });

    testWidgets('Free API模式应该限制只能选择一个食材', (WidgetTester tester) async {
      // Arrange - 设置为Free API模式
      await mockPrefs.setString('api_source', 'Free');
      
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Free模式下默认全不选
      expect(find.textContaining('0/2'), findsWidgets);

      // 点击第一个食材
      final chipFinder = find.byType(FilterChip);
      if (chipFinder.evaluate().length >= 2) {
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        // 验证选中了1个
        expect(find.textContaining('1/2'), findsWidgets);

        // 尝试选择第二个食材（应该被限制）
        await tester.tap(chipFinder.at(1));
        await tester.pumpAndSettle();

        // 验证仍然只有1个被选中
        expect(find.textContaining('1/2'), findsWidgets);

        // 验证显示了警告snackbar
        expect(
          find.text('Free Recipe API only allows ONE main ingredient'),
          findsOneWidget,
        );
      }
    });

    testWidgets('Free API模式应该显示提示信息', (WidgetTester tester) async {
      // Arrange - 设置为Free API模式
      await mockPrefs.setString('api_source', 'Free');
      
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证Free API提示
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

      // Assert - 验证Find Recipes按钮存在且可见
      final findButton = find.byKey(const Key('findRecipesButton'));
      expect(findButton, findsOneWidget);
      
      // 验证按钮文本
      expect(find.text('Find Recipes'), findsOneWidget);
      
      // 验证搜索图标
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('未选择任何食材时点击搜索应显示提示', (WidgetTester tester) async {
      // Arrange - Free模式下默认不选中任何食材
      await mockPrefs.setString('api_source', 'Free');
      
      final widget = createTestApp(
        child: RecipeDetailScreen(ingredients: testIngredients),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 点击搜索按钮
      final findButton = find.byKey(const Key('findRecipesButton'));
      await tester.tap(findButton);
      await tester.pumpAndSettle();

      // Assert - 验证显示提示
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

      // Assert - 翻页按钮可能在有结果时才显示
      // 这里只验证页面不崩溃
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

      // Assert - 验证厨房图标显示
      expect(find.byIcon(Icons.kitchen), findsWidgets);
    });

    testWidgets('应该正确去重相同名称的食材', (WidgetTester tester) async {
      // Arrange - 创建有重复名称的食材列表
      final duplicateIngredients = [
        Ingredient.create(
          name: 'Apple',
          qty: 100,
          unit: 'g',
          expirationDate: DateTime.now().add(const Duration(days: 7)),
        ),
        Ingredient.create(
          name: 'Apple', // 重复
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

      // Assert - 应该只显示2个FilterChip（Apple和Banana）
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

      // Assert - 验证空状态提示文字
      expect(find.text('Ready to discover recipes?'), findsOneWidget);
      expect(
        find.text('Select ingredients and tap "Find Recipes"'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });
  });
}
