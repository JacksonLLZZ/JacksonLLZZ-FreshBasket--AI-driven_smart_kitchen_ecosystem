import 'package:flutter/material.dart';
import '../../../services/nutrition_service.dart';
import '../../inventory/data/ingredient.dart';
import '../data/recipe.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  // 分页相关
  int _currentPage = 0; // 当前页码（0-9代表第1-10个食谱）

  // 用于跟踪选中的食材
  late Map<String, bool> _selectedIngredients;

  @override
  void initState() {
    super.initState();
    // 初始化所有食材为选中状态
    _selectedIngredients = {
      for (var ingredient in widget.ingredients) ingredient.id: true,
    };
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
    });

    try {
      final recipes = await _service.generateCombinedRecipes(
        selectedIngredients,
      );
      setState(() {
        _recipes = recipes;
        _loading = false;
      });

      if (recipes.isEmpty) {
        setState(() {
          _errorMessage = 'No recipes found for the selected ingredients.';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Recipe Finder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
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
                    Icon(Icons.kitchen, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Select Ingredients (${_getSelectedIngredients.length}/${widget.ingredients.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.ingredients.map((ingredient) {
                    final isSelected =
                        _selectedIngredients[ingredient.id] ?? false;
                    return FilterChip(
                      label: Text(ingredient.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedIngredients[ingredient.id] = selected;
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                      backgroundColor: Colors.grey.shade100,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _searchRecipes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                        : const Icon(Icons.search),
                    label: Text(
                      _loading ? 'Searching...' : 'Find Recipes',
                      style: const TextStyle(
                        fontSize: 16,
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
    );
  }

  Widget _buildResultsArea() {
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

    // 显示单个食谱卡片 + 翻页控件
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

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 食谱图片
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
    );
  }
}
