import 'package:flutter/material.dart';
import '../../../services/nutrition_service.dart';
import '../../../services/database_service.dart';
import '../inventory/data/ingredient.dart';
import 'package:kitchen/features/shopping_list/presentation/shopping_list_screen.dart';
import '../../../core/utils/season_helper.dart';
import '../../../core/utils/food_validator.dart';

String _seasonLabel(String season) {
  switch (season) {
    case 'spring':
      return 'Spring';
    case 'summer':
      return 'Summer';
    case 'autumn':
      return 'Autumn';
    case 'winter':
      return 'Winter';
    default:
      return season;
  }
}

String _seasonMessage(String season) {
  switch (season) {
    case 'spring':
      return 'Fresh greens and light proteins are in season.';
    case 'summer':
      return 'Hydrating fruits and quick salads are perfect now.';
    case 'autumn':
      return 'Warm soups and hearty vegetables are great choices.';
    case 'winter':
      return 'Root vegetables and high-protein staples work well.';
    default:
      return 'Seasonal picks curated for you.';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NutritionService _nutrition = NutritionService();
  final DatabaseService _db = DatabaseService();

  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();

  String _selectedUnit = 'g';
  String _selectedCategory = 'Meat';
  List<String> _availableUnits = ['g']; // 动态更新
  DateTime _expirationDate = DateTime.now().add(
    const Duration(days: 7),
  ); // 默认7天

  // categories list
  final List<String> _categories = [
    'Meat',
    'Fruit',
    'Vegetable',
    'Dairy',
    'Grain',
    'Seafood',
    'Drink',
    'Snack',
  ];

  bool _isProcessing = false;
  Ingredient? _result;

  @override
  void initState() {
    super.initState();
    _updateAvailableUnits(); // 初始化单位选项
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  /// 根据分类更新可用单位
  void _updateAvailableUnits() {
    setState(() {
      _availableUnits = FoodValidator.getAllowedUnits(_selectedCategory);

      // 如果当前选择的单位不在允许列表中，切换到第一个允许的单位
      if (!_availableUnits.contains(_selectedUnit)) {
        _selectedUnit = _availableUnits.first;
      }
    });
  }

  /// 分类改变时的处理
  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      _selectedCategory = newCategory;
      _updateAvailableUnits();
    });
  }

  // calculate nutrition
  void _calculate() async {
    final name = _nameController.text.trim();
    final qty = double.tryParse(_qtyController.text) ?? 0.0;

    if (name.isEmpty) {
      _showMsg("Please enter food name");
      return;
    }
    if (qty <= 0) {
      _showMsg("Please enter valid quantity");
      return;
    }

    // 单位验证(额外保险,UI已限制)
    if (!FoodValidator.isUnitValid(_selectedCategory, _selectedUnit)) {
      _showMsg("Invalid unit for this category");
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    final calories = await _nutrition.calculateCalories(
      name,
      qty,
      _selectedUnit,
    );

    setState(() {
      _isProcessing = false;
      if (calories != null) {
        _result = Ingredient.fromApi(
          name: name,
          qty: qty,
          unit: _selectedUnit,
          category: _selectedCategory,
          calories: calories,
          expirationDate: _expirationDate, // 使用自定义过期日期
        );
      } else {
        _showMsg("Could not find nutrition data for this item.");
      }
    });
  }

  // execute save
  void _save() async {
    if (_result == null) {
      _showMsg("Please calculate nutrition first");
      return;
    }

    try {
      // 检查是否存在相似食材
      final existing = await _db.findSimilarIngredient(
        _result!.name,
        _result!.category,
      );

      if (existing != null && mounted) {
        // 对比过期时间（只比较日期部分，忽略时分秒）
        final existingDate = DateTime(
          existing.expirationDate.year,
          existing.expirationDate.month,
          existing.expirationDate.day,
        );
        final newDate = DateTime(
          _result!.expirationDate.year,
          _result!.expirationDate.month,
          _result!.expirationDate.day,
        );

        if (existingDate == newDate) {
          // 过期时间一致，自动合并
          await _db.mergeIngredient(existing, _result!.quantity);
          if (mounted) {
            _showMsg("Merged with existing item");
            _clearForm();
          }
        } else {
          // 过期时间不一致，添加为新条目
          await _db.saveIngredient(_result!);
          if (mounted) {
            _showMsg("Saved to your inventory");
            _clearForm();
          }
        }
      } else {
        await _db.saveIngredient(_result!);
        if (mounted) {
          _showMsg("Saved to your inventory");
          _clearForm();
        }
      }
    } catch (e) {
      if (mounted) {
        _showMsg("Error saving food: ${e.toString()}");
      }
    }
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _qtyController.clear();
      _result = null;
    });
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Smart Fridge",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seasonal recommendation card
            Builder(
              builder: (context) {
                final season = SeasonHelper.getCurrentSeason(
                  hemisphere: Hemisphere.northern,
                );
                final seasonText = _seasonLabel(season);
                final message = _seasonMessage(season);

                final theme = Theme.of(context);
                final primary = theme.colorScheme.primary;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface, // 比 Colors.white 更“主题化”
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.local_florist_outlined,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "It's $seasonText now",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Based on the season, we recommend in-season groceries for your shopping list.\n$message",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ShoppingListScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 18,
                                ),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "View seasonal picks",
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            const Text(
              "Add Food Item",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),

            // input form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 13),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Food Name",
                      hintText: "e.g. Chicken Breast",
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: _onCategoryChanged,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Quantity",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(labelText: "Unit"),
                          items: _availableUnits
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedUnit = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 过期日期选择器
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expirationDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _expirationDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Expiration Date",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _expirationDate.toString().split(' ')[0],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),

                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Calculate Calories",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (_result != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 77),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Analysis Result",
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result!.calories!,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      "for ${_result!.quantity} ${_result!.unit} of ${_result!.name}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Save to My Inventory"),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
