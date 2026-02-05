import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../../../services/nutrition_service.dart';
import '../../../services/database_service.dart';
import '../inventory/data/ingredient.dart';
import '../../../services/ingredient_list_service.dart';
import 'barcode_scanner_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NutritionService _nutrition = NutritionService();
  final DatabaseService _db = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();

  String _selectedUnit = 'g';
  final List<String> _availableUnits = ['g', 'ml']; // 支持的单位列表
  DateTime _expirationDate = DateTime.now().add(
    const Duration(days: 7),
  ); // 默认7天

  bool _isProcessing = false;
  int? _calculatedCalories; // 存储计算的卡路里结果
  List<String> _ingredientsList = []; // 食材列表

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final ingredients = await IngredientListService.loadIngredients();
    setState(() {
      _ingredientsList = ingredients;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
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

    setState(() {
      _isProcessing = true;
      _calculatedCalories = null;
    });

    final calories = await _nutrition.calculateCalories(
      name,
      qty,
      _selectedUnit,
    );

    setState(() {
      _isProcessing = false;
      if (calories != null) {
        _calculatedCalories = calories;
      } else {
        _showMsg("Could not find nutrition data for this item.");
      }
    });
  }

  // execute save
  void _save() async {
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

    try {
      // 创建食材对象
      final ingredient = Ingredient.create(
        name: name,
        qty: qty,
        unit: _selectedUnit,
        expirationDate: _expirationDate,
      );

      // 检查是否存在相似食材
      final existing = await _db.findSimilarIngredient(ingredient.name);

      if (existing != null && mounted) {
        // 对比过期时间（只比较日期部分，忽略时分秒）
        final existingDate = DateTime(
          existing.expirationDate.year,
          existing.expirationDate.month,
          existing.expirationDate.day,
        );
        final newDate = DateTime(
          ingredient.expirationDate.year,
          ingredient.expirationDate.month,
          ingredient.expirationDate.day,
        );

        if (existingDate == newDate) {
          // 过期时间一致，自动合并
          await _db.mergeIngredient(existing, ingredient.quantity);
          if (mounted) {
            _showMsg("Merged with existing item");
            _clearForm();
          }
        } else {
          // 过期时间不一致，添加为新条目
          await _db.saveIngredient(ingredient);
          if (mounted) {
            _showMsg("Saved to your inventory");
            _clearForm();
          }
        }
      } else {
        await _db.saveIngredient(ingredient);
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
      _calculatedCalories = null;
    });
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 显示扫描选项菜单
  void _showScanOptions() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, size: 28),
                title: const Text(
                  'Scan Barcode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Use camera to scan product barcode'),
                onTap: () async {
                  Navigator.pop(context);
                  final barcode = await navigator.push<String>(
                    MaterialPageRoute(
                      builder: (context) => const BarcodeScannerScreen(),
                    ),
                  );
                  if (barcode != null && mounted) {
                    // 显示加载提示
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Searching product...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // 调用 OpenFoodFacts API 获取产品信息
                    final productInfo = await _nutrition.getProductByBarcode(
                      barcode,
                    );

                    if (productInfo != null && mounted) {
                      final foodName = productInfo['product_name'] ?? 'Unknown';

                      // 自动填充到 food name 栏
                      setState(() {
                        _nameController.text = foodName;
                      });

                      // 复制到剪贴板
                      await Clipboard.setData(ClipboardData(text: foodName));

                      // 显示底部消息框
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Product found and copied!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      foodName,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green[700],
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } else if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Product not found in OpenFoodFacts database',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library, size: 28),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Select an image from your gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null && mounted) {
                    // 显示加载提示
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Recognizing ingredient...'),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    try {
                      // 读取图片并转换为base64
                      final bytes = await File(image.path).readAsBytes();
                      final base64Image = base64Encode(bytes);

                      // 调用百度AI识别API
                      final result = await _nutrition
                          .recognizeIngredientFromImage(base64Image);

                      if (result['success'] == true && mounted) {
                        final ingredientName = result['name'] as String;

                        // 自动填充到 food name 栏
                        setState(() {
                          _nameController.text = ingredientName;
                        });

                        // 复制到剪贴板
                        await Clipboard.setData(
                          ClipboardData(text: ingredientName),
                        );

                        // 显示成功消息
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Ingredient recognized and copied!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ingredientName,
                                        style: const TextStyle(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green[700],
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } else if (mounted) {
                        final errorMsg =
                            result['error'] ?? 'Could not recognize ingredient';
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(errorMsg)),
                              ],
                            ),
                            backgroundColor: Colors.red[700],
                            duration: const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan or Upload',
            onPressed: _showScanOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seasonal recommendation card
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
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return IngredientListService.filterIngredients(
                        _ingredientsList,
                        textEditingValue.text,
                      );
                    },
                    onSelected: (String selection) {
                      _nameController.text = selection;
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          // 同步两个controller
                          controller.addListener(() {
                            _nameController.text = controller.text;
                          });
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: "Food Name",
                              hintText: "e.g. Chicken Breast",
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          );
                        },
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
                  // 按钮横向并排
                  Row(
                    children: [
                      // 保存按钮（左侧，更大）
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text(
                              "Save to My Inventory",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 计算卡路里按钮（右侧，仅图标）
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : _calculate,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primary, width: 2),
                            foregroundColor: primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.calculate_outlined, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 显示卡路里结果 - 占满宽度
            if (_calculatedCalories != null)
              SizedBox(
                width: double.infinity,
                child: Container(
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
                        "Nutrition Information",
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "$_calculatedCalories kcal",
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        "for ${_qtyController.text} $_selectedUnit of ${_nameController.text}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
