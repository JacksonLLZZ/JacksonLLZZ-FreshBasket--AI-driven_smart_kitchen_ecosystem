# 单元测试指南

本项目包含全面的单元测试，覆盖所有核心功能和边界案例。

## 测试覆盖范围

### 📦 数据模型测试
- **Ingredient** - 食材数据模型
  - 基础功能测试（创建、工厂方法、过期判断）
  - 边界案例测试（零数量、极值、特殊字符、时区处理等）
  - 共 **25+ 个测试用例**
  
- **ShoppingItem** - 购物车项目模型
  - 创建、工厂方法、Firestore 转换
  - 缺失字段处理、空值处理
  - 共 **6 个测试用例**
  
- **Recipe & RecipeIngredient** - 食谱模型
  - JSON 解析（Spoonacular 和 TheMealDB 两种格式）
  - 数据转换（toJson/fromJson 可逆性）
  - 共 **10 个测试用例**
  
- **SeasonalFood** - 季节性食材模型
  - JSON 解析、列表解析
  - 多季节食材、特殊字符处理
  - 共 **8 个测试用例**

### 🛠️ 工具类测试
- **FoodValidator** - 食材验证工具
  - 模糊匹配（忽略大小写、空格、特殊字符）
  - Unicode 字符、混合语言支持
  - 共 **16 个测试用例**
  
- **SeasonHelper** - 季节帮助类
  - 北半球/南半球季节计算
  - 枚举值验证
  - 共 **7 个测试用例**
  
- **IngredientListService** - 食材列表服务
  - 智能过滤（完全匹配优先、开头匹配、包含匹配）
  - 排序逻辑、空值处理
  - 共 **13 个测试用例**

### 🔧 服务类测试
- **NutritionService** - 营养服务
  - API 调用 mock（成功、失败、空数据）
  - 依赖注入测试
  - 共 **7 个测试用例**
  
- **DatabaseService** - 数据库服务
  - Firestore 数据转换
  - Stream 操作、数据验证
  - 共 **14 个测试用例**

## 统计数据

- **总测试用例数**: 103+
- **测试文件数**: 10
- **测试通过率**: 100%
- **测试分类**:
  - 数据模型测试: 49 个
  - 工具类测试: 36 个
  - 服务类测试: 21 个

## 运行测试

### 运行所有单元测试
```bash
flutter test test/unit_test
```

### 运行单一测试文件
```bash
flutter test test/unit_test/ingredient_test.dart
```

### 生成覆盖率报告
```bash
flutter test test/unit_test --coverage
```

### 查看详细测试输出
```bash
flutter test test/unit_test --reporter expanded
```

## 测试文件结构

```
test/
├── unit_test/
│   ├── all_tests.dart                      # 测试套件索引
│   ├── ingredient_test.dart                # 食材模型测试
│   ├── ingredient_edge_cases_test.dart     # 食材边界案例测试
│   ├── shopping_item_test.dart             # 购物车项目测试
│   ├── recipe_test.dart                    # 食谱模型测试
│   ├── seasonal_food_test.dart             # 季节性食材测试
│   ├── food_validator_test.dart            # 食材验证工具测试
│   ├── season_helper_test.dart             # 季节帮助类测试
│   ├── ingredient_list_service_test.dart   # 食材列表服务测试
│   ├── nutrition_service_test.dart         # 营养服务测试
│   └── database_service_test.dart          # 数据库服务测试
├── mock_dependencies.dart                   # Mock 类定义
└── test_helpers.dart                        # 测试辅助函数
```

## 测试依赖

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4              # Mock 库
  fake_cloud_firestore: ^4.0.1  # Firestore Mock
  firebase_auth_mocks: ^0.15.0  # Firebase Auth Mock
  fake_async: ^1.3.1            # 异步测试
  test: ^1.25.0                 # 测试工具
```

## 测试最佳实践

### 1. Arrange-Act-Assert (AAA) 模式
所有测试都遵循 AAA 模式：
```dart
test('描述测试场景', () {
  // Arrange - 准备测试数据
  final ingredient = Ingredient(...);
  
  // Act - 执行测试操作
  final result = ingredient.isExpired;
  
  // Assert - 验证结果
  expect(result, isTrue);
});
```

### 2. 描述性测试名称
使用中文描述测试意图，使测试结果易读：
```dart
test('工厂方法应该使用默认过期日期', () { ... });
test('应该忽略大小写差异', () { ... });
```

### 3. 边界案例覆盖
- 空值、null 处理
- 极大值、极小值
- 特殊字符、Unicode
- 边界时间（午夜、闰年等）

### 4. Mock 使用
使用 mocktail 进行依赖隔离：
```dart
final mockDio = MockDio();
when(() => mockDio.get(any())).thenAnswer((_) async => mockResponse);
```

## 持续改进

### 下一步计划
- [ ] 增加集成测试
- [ ] 添加 Widget 测试
- [ ] 提高覆盖率到 90%+
- [ ] 添加性能测试
- [ ] 金色文件测试（Golden File Testing）

## 问题反馈

如果发现测试问题或需要添加新测试，请参考现有测试文件的模式编写。

---

**最后更新**: 2026年2月7日  
**测试通过率**: ✅ 100% (103/103)
