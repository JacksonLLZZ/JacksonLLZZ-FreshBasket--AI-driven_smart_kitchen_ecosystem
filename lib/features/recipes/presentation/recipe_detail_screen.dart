import 'package:flutter/material.dart';
import '../../../services/nutrition_service.dart';
import '../../inventory/data/ingredient.dart';
import '../data/recipe.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'recipe_info_screen.dart';
import '../../../core/constants/test_keys.dart';

class RecipeDetailScreen extends StatefulWidget {
  final List<Ingredient> ingredients;
  const RecipeDetailScreen({super.key, required this.ingredients});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final NutritionService _service = NutritionService();
  List<Recipe> _recipes = [];
  bool _loading = false;
  String? _errorMessage;
  bool _loadedFromCache = false; // 是否从缓存加载
  double _cacheOpacity = 0.0; // 缓存提示的透明度

  // 分页相关
  int _currentPage = 0; // 当前页码（0-9代表第1-10个食谱）

  // 用于跟踪选中的食材
  Map<String, bool> _selectedIngredients = {};

  // API 源相关
  String _currentApiSource = 'Spoonacular';

  // Master-Detail View: 选中的食谱
  Recipe? _selectedRecipe;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // 读取当前 API 源
    final prefs = await SharedPreferences.getInstance();
    final apiSource = prefs.getString('api_source') ?? 'Spoonacular';

    // 根据 API 源初始化食材选择状态
    if (apiSource == 'Free') {
      // Free Recipe API: 默认全不选
      _selectedIngredients = {
        for (var ingredient in widget.ingredients) ingredient.id: false,
      };
    } else {
      // Spoonacular API: 默认全选
      _selectedIngredients = {
        for (var ingredient in widget.ingredients) ingredient.id: true,
      };
    }

    setState(() {
      _currentApiSource = apiSource;
    });

    // 自动加载缓存（如果存在）
    await _autoLoadCache();
  }

  // 生成缓存key（基于 API 源和所有食材ID）
  String _getCacheKey() {
    final allIds = widget.ingredients.map((e) => e.id).toList()..sort();
    return 'recipes_cache_${_currentApiSource}_${allIds.join('_')}';
  }

  // 自动加载缓存（如果存在）
  Future<void> _autoLoadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        // 发现缓存，自动加载
        final Map<String, dynamic> cacheMap = json.decode(cachedData);
        final List<dynamic> recipesJson = cacheMap['recipes'];
        final Map<String, dynamic> selectedIngredientsJson =
            cacheMap['selectedIngredients'] ?? {};

        final recipes = recipesJson
            .map((json) => Recipe.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _recipes = recipes;
            _currentPage = 0;
            _loadedFromCache = true;
            // 在平板模式下，自动选中第一个食谱
            _selectedRecipe = recipes.isNotEmpty ? recipes[0] : null;
            // 恢复之前选中的食材状态
            if (selectedIngredientsJson.isNotEmpty) {
              _selectedIngredients = selectedIngredientsJson.map(
                (key, value) => MapEntry(key, value as bool),
              );
            }
          });

          // 渐入动画
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _cacheOpacity = 1.0;
              });
            }
          });

          // 2秒后开始渐出
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (mounted) {
              setState(() {
                _cacheOpacity = 0.0;
              });
            }
          });

          // 2.5秒后完全隐藏
          Future.delayed(const Duration(milliseconds: 3500), () {
            if (mounted) {
              setState(() {
                _loadedFromCache = false;
              });
            }
          });
        }
      }
      // 如果没有缓存，保持空状态，不做任何处理
    } catch (e) {
      debugPrint('Error loading cache: $e');
      // 如果加载缓存失败，静默处理，保持空状态
    }
  }

  // 保存到缓存
  Future<void> _saveToCache(List<Recipe> recipes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      final jsonList = recipes.map((recipe) => recipe.toJson()).toList();

      // 同时保存食谱和选中的食材状态
      final cacheData = {
        'recipes': jsonList,
        'selectedIngredients': _selectedIngredients,
      };

      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      debugPrint('Failed to save cache: $e');
    }
  }

  // 获取选中的食材列表
  List<Ingredient> get _getSelectedIngredients {
    return widget.ingredients
        .where((ing) => _selectedIngredients[ing.id] == true)
        .toList();
  }

  // 搜索食谱
  Future<void> _searchRecipes() async {
    final selectedIngredients = _getSelectedIngredients;

    if (selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one ingredient')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _recipes = [];
      _currentPage = 0; // 重置页码
      _loadedFromCache = false;
    });

    try {
      List<Recipe> recipes;

      // 根据 API 源调用不同的接口
      if (_currentApiSource == 'Free') {
        // 使用 TheMealDB API - 只支持单个食材
        if (selectedIngredients.length != 1) {
          throw Exception('Free Recipe API only supports ONE ingredient');
        }

        final ingredient = selectedIngredients.first.name;
        debugPrint('Using Free Recipe API with ingredient: $ingredient');
        recipes = await _service.generateRecipesFromMealDb(ingredient);
      } else if (_currentApiSource == 'Gemini') {
        // TODO: 调用 Gemini API
        debugPrint('Using Gemini API - Placeholder');
        recipes = await _service.generateCombinedRecipes(selectedIngredients);
      } else {
        // Spoonacular API（默认）
        debugPrint('Using Spoonacular API');
        recipes = await _service.generateCombinedRecipes(selectedIngredients);
      }

      if (recipes.isEmpty) {
        setState(() {
          _recipes = [];
          _loading = false;
          _errorMessage = 'No recipes found for the selected ingredients.';
        });
      } else {
        // 先保存到缓存
        await _saveToCache(recipes);
        // 然后更新 UI
        setState(() {
          _recipes = recipes;
          _loading = false;
          _loadedFromCache = false; // 明确标记这是新搜索的结果
          // 在平板模式下，自动选中第一个食谱
          _selectedRecipe = recipes.isNotEmpty ? recipes[0] : null;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // 上一页
  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  // 下一页
  void _nextPage() {
    if (_currentPage < _recipes.length - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key(TestKeys.recipeDetailScreenScaffold),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Recipe Finder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 主要内容区域
          Column(
            children: [
              // 食材选择区域
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.kitchen,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select Ingredients (${_getSelectedIngredients.length}/${widget.ingredients.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // API 源提示（如果是 Free Recipe API）
                    if (_currentApiSource == 'Free') ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Free API: Select only ONE main ingredient',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: () {
                        // 按名称去重，相同名称只保留第一个
                        final uniqueIngredients = <String, Ingredient>{};
                        for (var ingredient in widget.ingredients) {
                          if (!uniqueIngredients.containsKey(ingredient.name)) {
                            uniqueIngredients[ingredient.name] = ingredient;
                          }
                        }
                        return uniqueIngredients.values.map((ingredient) {
                          final isSelected =
                              _selectedIngredients[ingredient.id] ?? false;
                          return FilterChip(
                            label: Text(ingredient.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              // Free Recipe API 限制：最多只能选择一个
                              if (_currentApiSource == 'Free' && selected) {
                                final selectedCount = _selectedIngredients
                                    .values
                                    .where((v) => v == true)
                                    .length;
                                if (selectedCount >= 1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Free Recipe API only allows ONE main ingredient',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() {
                                _selectedIngredients[ingredient.id] = selected;
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).primaryColor,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList();
                      }(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        key: const Key('findRecipesButton'),
                        onPressed: _loading ? null : _searchRecipes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, size: 20),
                        label: Text(
                          _loading ? 'Searching...' : 'Find Recipes',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 结果展示区域
              Expanded(child: _buildResultsArea()),
            ],
          ),

          // 顶部缓存提示（悬浮层）
          if (_loadedFromCache)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _cacheOpacity,
                duration: const Duration(milliseconds: 500),
                child: Material(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.15),
                          Theme.of(context).primaryColor.withOpacity(0.08),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.cached,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loaded from cache',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap "Find Recipes" to refresh',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('tryAgainButton'),
                onPressed: _searchRecipes,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipes.isEmpty && !_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Ready to discover recipes?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select ingredients and tap "Find Recipes"',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_recipes.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 平板模式：Master-Detail View
    if (isTablet) {
      return Row(
        children: [
          // Master: 左侧食谱列表
          SizedBox(
            width: 400,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Found ${_recipes.length} recipes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      final isSelected = _selectedRecipe?.id == recipe.id;
                      return _buildRecipeListItem(recipe, isSelected, isTablet);
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Detail: 右侧食谱详情
          Expanded(
            child: _selectedRecipe != null
                ? RecipeInfoScreen(recipe: _selectedRecipe!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a recipe to view details',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );
    }

    // 手机模式：显示单个食谱卡片 + 翻页控件
    return Column(
      children: [
        // 食谱卡片区域
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildRecipeCard(_recipes[_currentPage]),
          ),
        ),

        // 翻页控件
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 上一页按钮
              IconButton(
                key: const Key('previousPageButton'),
                onPressed: _currentPage > 0 ? _previousPage : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 32,
                color: _currentPage > 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),

              // 页码指示器
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_recipes.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),

              // 下一页按钮
              IconButton(
                key: const Key('nextPageButton'),
                onPressed: _currentPage < _recipes.length - 1
                    ? _nextPage
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 32,
                color: _currentPage < _recipes.length - 1
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeListItem(Recipe recipe, bool isSelected, bool isTablet) {
    return GestureDetector(
      key: Key('recipeCard_${recipe.id}'),
      onTap: () {
        if (isTablet) {
          // 平板模式：更新选中的食谱
          setState(() {
            _selectedRecipe = recipe;
          });
        } else {
          // 手机模式：导航到详情页
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeInfoScreen(recipe: recipe),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: recipe.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.restaurant,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 食谱信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.usedIngredientCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.shopping_cart,
                          color: Colors.orange.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.missedIngredientCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return GestureDetector(
      key: Key('recipeCard_${recipe.id}'),
      onTap: () {
        if (!isTablet) {
          // 手机模式：导航到详情页
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeInfoScreen(recipe: recipe),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 食谱图片
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: recipe.image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // 食谱信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 使用的食材
                  if (recipe.usedIngredients.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Using ${recipe.usedIngredientCount} ingredient${recipe.usedIngredientCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...recipe.usedIngredients.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(
                          '• ${ing.name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 缺少的食材
                  if (recipe.missedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Colors.orange.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Need ${recipe.missedIngredientCount} more ingredient${recipe.missedIngredientCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...recipe.missedIngredients.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(
                          '• ${ing.name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
