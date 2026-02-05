# Smart Kitchen Management App

智能冰箱管理应用，帮助用户追踪食材、计算营养、发现食谱和管理购物清单。

---

## 页面架构

### 主要界面 (8个屏幕)

#### 1. **HomeScreen** - 添加食材界面 
路径: `lib/features/home/home_screen.dart`

**功能**:
- 手动输入食材信息（名称、数量、单位、过期日期）
- 智能输入辅助：
  - CSV自动补全
  - 条形码扫描 (OpenFoodFacts API)
  - 图片识别 (百度AI + 百度翻译)
- 实时卡路里计算（Edamam API）
- 保存到Firestore数据库
- 重复食材检测与合并

**API调用**:
- Edamam Nutrition API - 营养数据计算
- OpenFoodFacts API - 条形码产品查询
- 百度AI图像识别 API - 食材识别
- 百度翻译API - 中英文翻译

---

#### 2. **BarcodeScannerScreen** - 条形码扫描
路径: `lib/features/home/barcode_scanner_screen.dart`

**功能**:
- 调用摄像头扫描条形码
- 手电筒开关
- 返回条形码数据给HomeScreen

---

#### 3. **InventoryScreen** - 冰箱库存管理
路径: `lib/features/inventory/presentation/inventory_screen.dart`

**功能**:
- 实时显示所有食材 (StreamBuilder)
- 过期状态标记（红色/绿色）
- 多选批量删除
- 滑动删除单个食材
- 编辑数量和过期日期
- "Explore Recipes"按钮跳转到食谱推荐

---

#### 4. **RecipeDetailScreen** - 食谱查找界面
路径: `lib/features/recipes/presentation/recipe_detail_screen.dart`

**功能**:
- 显示库存食材选择器
- 支持单/多食材搜索
- API源切换（Spoonacular / Free Recipe）
- 缓存机制（SharedPreferences）
- 翻页浏览食谱（1/10格式）
- 点击食谱卡片查看详情

**API调用**:
- Spoonacular API - 多食材食谱搜索
- TheMealDB API - 单食材免费食谱

---

#### 5. **RecipeInfoScreen** - 食谱详情页
路径: `lib/features/recipes/presentation/recipe_info_screen.dart`

**功能**:
- 显示食谱完整信息：
  - 标题、图片、统计数据
  - 已有食材列表
  - 缺失食材列表（带购物车按钮）
  - 烹饪步骤（TheMealDB专有）
  - YouTube视频链接（可复制）
- 缺失食材一键加入购物车
- 实时检测购物车状态（已添加显示绿色勾号）

---

#### 6. **ShoppingCartScreen** - 购物车界面
路径: `lib/features/shopping_cart/presentation/shopping_cart_screen.dart`

**功能**:
- 显示所有购物清单商品（名称+数量）
- 季节性食材推荐卡片
- 单个删除/批量清空

**数据来源**:
1. 菜谱缺失食材（RecipeInfoScreen）
2. 季节性推荐食材（SeasonalListScreen）

---

#### 7. **SeasonalListScreen** - 季节性食材推荐
路径: `lib/features/shopping_list/presentation/seasonal_list_screen.dart`

**功能**:
- 根据当前季节推荐食材
- 搜索功能（名称/别名模糊匹配）
- 显示类别、保质期
- 一键加入购物车
- 实时购物车状态同步

**数据来源**: `assets/data/season_foods.json`

---

#### 8. **ProfileScreen** - 用户配置
路径: `lib/features/profile/presentation/profile_screen.dart`

**功能**:
- 主题切换（Spring/Summer/Autumn/Winter/Default）
- Firebase登录/注册
- 游客模式
- API源选择（Settings界面）

---

## API调用总结

### Edamam Nutrition API
**用途**: 计算食材卡路里  
**端点**: `https://api.edamam.com/api/nutrition-data`  
**调用位置**: `HomeScreen._calculate()`  
**参数**: `app_id`, `app_key`, `ingr` (食材描述)  
**返回**: 营养数据（卡路里、蛋白质等）

---

### OpenFoodFacts API
**用途**: 条形码产品信息查询  
**端点**: `https://world.openfoodfacts.net/api/v2/product/{barcode}`  
**调用位置**: `HomeScreen._showScanOptions()`  
**返回**: 产品名称、营养数据（kJ转kcal）

---

### 百度AI图像识别 API
**用途**: 食材图片识别  
**端点**: `https://aip.baidubce.com/rest/2.0/image-classify/v1/classify/ingredient`  
**调用位置**: `HomeScreen._showScanOptions()` (选择图片)  
**参数**: Base64编码图片、`top_num: 20`  
**特殊处理**: 过滤"非果蔬食材"结果

---

### 百度翻译 API
**用途**: 中文食材名翻译为英文  
**端点**: `https://fanyi-api.baidu.com/api/trans/vip/translate`  
**调用位置**: `NutritionService._translateToEnglish()`  
**签名**: MD5(appid+q+salt+key)

---

### Spoonacular API
**用途**: 多食材食谱搜索  
**端点**: `https://api.spoonacular.com/recipes/findByIngredients`  
**调用位置**: `RecipeDetailScreen._searchRecipes()`  
**参数**: `ingredients` (逗号分隔), `number: 2`, `ranking: 1`, `ignorePantry: true`  
**返回**: 食谱列表（已有/缺失食材）

---

### TheMealDB API
**用途**: 单食材食谱搜索  
**端点**: 
- `https://www.themealdb.com/api/json/v1/1/filter.php?i={ingredient}`
- `https://www.themealdb.com/api/json/v1/1/lookup.php?i={mealId}`

**调用位置**: `RecipeDetailScreen._searchRecipes()` (Free API模式)  
**返回**: 食谱详情（含烹饪步骤、YouTube链接）

---

## 数据库架构 (Firebase Firestore)

### 集合路径
```
/artifacts/nutriscan-app-v1/users/{userId}/
  ├── inventory/{ingredientId}         # 冰箱库存
  │   ├── name: string
  │   ├── quantity: number
  │   ├── unit: string
  │   ├── expiration_date: timestamp
  │   └── updated_at: timestamp
  │
  └── shopping_cart/{itemId}           # 购物车
      ├── name: string
      ├── amount: string
      └── addedAt: timestamp
```

---

## 项目结构

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_icons.dart          # SVG图标路径
│   │   └── theme.dart              # 主题配置
│   └── utils/
│       ├── food_validator.dart     # 食材名称相似度检测
│       └── season_helper.dart      # 季节判断工具
│
├── features/
│   ├── home/                       # 添加食材模块
│   │   ├── home_screen.dart
│   │   └── barcode_scanner_screen.dart
│   │
│   ├── inventory/                  # 库存管理模块
│   │   ├── data/
│   │   │   └── ingredient.dart    # 食材数据模型
│   │   └── presentation/
│   │       └── inventory_screen.dart
│   │
│   ├── recipes/                    # 食谱推荐模块
│   │   ├── data/
│   │   │   ├── recipe.dart        # 食谱数据模型
│   │   │   └── seasonal_catalog_repository.dart
│   │   └── presentation/
│   │       ├── recipe_detail_screen.dart
│   │       └── recipe_info_screen.dart
│   │
│   ├── shopping_cart/              # 购物车模块
│   │   ├── data/
│   │   │   └── shopping_item.dart
│   │   └── presentation/
│   │       └── shopping_cart_screen.dart
│   │
│   ├── shopping_list/              # 季节性推荐模块
│   │   ├── domain/
│   │   │   ├── seasonal_food.dart
│   │   │   └── recommendation_service.dart
│   │   └── presentation/
│   │       └── seasonal_list_screen.dart
│   │
│   └── profile/                    # 用户配置模块
│       └── presentation/
│           └── profile_screen.dart
│
├── services/
│   ├── database_service.dart       # Firestore数据库操作
│   ├── nutrition_service.dart      # 外部API调用
│   └── ingredient_list_service.dart # CSV食材列表加载
│
└── main.dart                       # 应用入口
```

---

## 核心功能

### 食材管理
- 多种输入方式：手动/扫码/拍照识别
- 自动补全
- 重复检测与智能合并
- 实时卡路里计算

### 库存追踪
- 过期状态实时监控
- 批量/单个删除
- 数量和日期编辑
- 空库存友好提示

### 食谱推荐
- 基于现有食材智能匹配
- 双API源（有限Spoonacular + 免费MealDB）
- 缓存机制减少API调用
- 完整食谱详情（步骤、视频）

### 购物清单
- 从食谱自动添加缺失食材
- 季节性健康食材推荐
- 实时同步状态（已添加标记）
- 批量管理功能


---

## 数据流图

```
用户输入 → HomeScreen
    ├─→ 手动输入 → Edamam API → 卡路里
    ├─→ 扫条形码 → OpenFoodFacts → 产品信息
    └─→ 拍照识别 → 百度AI → 中文名 → 百度翻译 → 英文名
           ↓
    DatabaseService.saveIngredient()
           ↓
    Firestore /inventory/{id}
           ↓
    InventoryScreen (StreamBuilder实时显示)
           ↓
    RecipeDetailScreen (选择食材)
           ↓
    Spoonacular/MealDB API → 食谱列表
           ↓
    RecipeInfoScreen (显示详情)
           ↓
    缺失食材 → ShoppingCart → Firestore /shopping_cart/{id}
```

## 可优化功能

- [ ] 过期食材自动提醒通知
- [ ] 撤销删除功能（Undo）
- [ ] 食谱收藏功能
- [ ] 离线模式支持

- [ ] 营养成分详细显示（蛋白质、脂肪等）
- [ ] 食谱评分和评论
- [ ] 购物清单分享功能