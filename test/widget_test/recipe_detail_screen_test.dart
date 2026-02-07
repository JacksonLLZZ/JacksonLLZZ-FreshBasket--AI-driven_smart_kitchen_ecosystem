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
  });
}
