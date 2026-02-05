# NutriScan - Smart Kitchen Management App

智能冰箱管理应用，帮助用户追踪食材、计算营养和发现食谱。

## 核心功能

### 1. 食材管理 (Add Food)
- 输入食材名称、分类、数量和单位
- 自动从 Edamam API 获取营养数据（卡路里）
- 保存到个人冰箱库存

**最新改进 (2026-02-05)**:
- ✅ **单位限制**: 根据食物分类自动限制可选单位
  - Drink（饮料）→ 只能选 `ml`
  - Dairy（奶制品）→ 可选 `g` 或 `ml`
  - Meat/Fruit/Vegetable/Grain/Seafood → 只能选 `g`
  - Snack（零食）→ 可选 `g` 或 `ml`
- ✅ **重复检测**: 保存前自动检测同分类下的相似食材
  - 模糊匹配（忽略大小写和空格）
  - 提供三种处理方式：取消、另存为新条目、合并数量

### 2. 库存查看 (Inventory)
- 实时查看冰箱内所有食材
- 显示数量、单位、分类和过期日期
- 过期食材红色标记提醒

**最新改进 (2026-02-05)**:
- ✅ **多选删除**: 点击右上角选择图标进入多选模式，批量删除食材
  - 长按任意食材也可进入多选模式
  - 选中项高亮显示，支持复选框操作
- ✅ **滑动删除**: 在非选择模式下向左滑动快速删除单个食材
- ✅ **编辑功能**: 点击食材右侧编辑按钮可同时修改数量和过期日期
  - 弹出对话框统一编辑
  - 输入验证确保数据有效性

### 3. 食谱推荐 (Recipes)
- 基于现有食材智能推荐食谱
- 使用 Spoonacular API 生成食谱
- 支持多种筛选和排序

### 4. 用户配置 (Profile)
- 主题切换
- 登录/注册/游客模式
- 个人偏好设置

## 技术栈

- **Framework**: Flutter
- **Backend**: Firebase (Auth + Firestore)
- **APIs**:
  - Edamam Nutrition API - 营养数据
  - Spoonacular API - 食谱推荐
  - TheMealDB API - 食谱详情

## 项目结构

```
lib/
├── core/
│   ├── constants/     # 主题、图标等常量
│   └── utils/         # 工具类
│       ├── food_validator.dart      # 食材验证（单位限制、重复检测）
│       └── season_helper.dart       # 季节性食材推荐
├── features/
│   ├── home/          # 添加食材界面
│   ├── inventory/     # 库存管理
│   ├── profile/       # 用户配置
│   └── recipes/       # 食谱推荐
├── services/
│   ├── database_service.dart        # Firestore 数据库操作
│   └── nutrition_service.dart       # 营养和食谱 API 调用
└── widgets/           # 可复用组件
```

## TODO - 待优化功能

### Category（分类）字段优化方案
目前 category 字段**不传给 API**，仅用于 UI 显示和重复检测范围限定。考虑以下优化：

**选项 1: 移除 Category，改用 API 自动识别**
- 让 Edamam API 返回食物类别
- 自动填充，不让用户手动选择
- 避免用户选错分类

**选项 2: 保留但改进逻辑**
- 重复检测**不限制分类**（只看名称）
- Category 仅用于 UI 分组和筛选
- 允许同一食材有多种形式（如 Apple vs Apple Juice）

**选项 3: 让 Category 有实际作用**
- 传给 API 作为搜索提示
- 用于推荐食谱时的优先级
- 影响营养计算的精确度

### 冰箱管理功能待完善
- [x] 添加删除食材功能（多选批量删除 + 滑动删除）
- [x] 允许用户手动设置过期日期（添加时选择 + 库存中编辑）
- [x] 编辑食材数量和过期日期
- [ ] 过期食材自动处理逻辑
- [ ] 过期提醒通知

## 开发说明

### 运行项目
```bash
flutter pub get
flutter run
```

### 环境配置
需要在项目中配置：
- Firebase 项目（Authentication + Firestore）
- Edamam API 密钥
- Spoonacular API 密钥

### 最近更新
- **2026-02-05**: 
  - 实现单位限制和重复检测功能
  - 添加多选删除和编辑功能
  - 支持自定义过期日期
  - 优化库存管理用户体验
- 添加 `FoodValidator` 工具类
- 扩展 `DatabaseService` 批量操作方法

## License
MIT License
