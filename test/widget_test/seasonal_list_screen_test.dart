import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/shopping_list/presentation/seasonal_list_screen.dart';
import 'package:kitchen/features/shopping_list/domain/seasonal_food.dart';
import 'package:kitchen/services/database_service.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import 'package:kitchen/core/utils/season_helper.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late MockDatabaseService mockDb;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockDb = MockDatabaseService();

    // Mock shopping cart stream
    when(() => mockDb.getShoppingCartStream()).thenAnswer(
      (_) => Stream.value([]),
    );

    // Mock add to cart
    when(() => mockDb.addToShoppingCart(any())).thenAnswer((_) async {});
  });

  group('SeasonalListScreen Widget Tests -', () {
    testWidgets('应该显示页面标题 "Seasonal List"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // 初始pump
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - 验证标题
      expect(find.text('Seasonal List'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.seasonalListScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示搜索栏', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - 验证搜索框
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('应该显示刷新按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - 验证刷新按钮
      expect(find.byKey(const Key('refreshButton')), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('应该能够输入搜索文本', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // 输入搜索文本
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'tomato');
      await tester.pump();

      // Assert - 验证文本已输入
      expect(find.text('tomato'), findsOneWidget);
    });

    testWidgets('应该能够点击刷新按钮', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // 点击刷新按钮
      final refreshButton = find.byKey(const Key('refreshButton'));
      await tester.tap(refreshButton);
      await tester.pump();

      // Assert - 验证无异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示加载指示器', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // 只pump一次，此时应该在加载状态

      // Assert - 验证加载指示器存在
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('加载完成后应该显示列表', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // 初始pump
      await tester.pumpAndSettle(); // 等待异步操作完成

      // Assert - 验证ListView存在（无论是否有数据）
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ListView || widget is RefreshIndicator,
        ),
        findsWidgets,
      );
    });

    testWidgets('应该支持下拉刷新', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证RefreshIndicator存在
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('应该能够执行下拉刷新', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 执行下拉刷新手势
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
      );
      await tester.pump();

      // Assert - 验证无异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示FutureBuilder', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - 验证FutureBuilder存在
      expect(find.byType(FutureBuilder<List<SeasonalFood>>), findsOneWidget);
    });

    testWidgets('清空搜索应该重置列表', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 输入搜索文本
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.pump();

      // 清空搜索
      await tester.enterText(searchField, '');
      await tester.pump();

      // Assert - 验证无异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示搜索图标', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - 验证搜索图标
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('页面应该包含Column布局', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: const SeasonalListScreen(),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - 验证Column布局
      expect(find.byType(Column), findsWidgets);
    });
  });
}
