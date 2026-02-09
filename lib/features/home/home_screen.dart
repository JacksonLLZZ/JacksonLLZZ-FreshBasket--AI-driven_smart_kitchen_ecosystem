import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../../../services/nutrition_service.dart';
import '../../../services/database_service.dart';
import '../inventory/data/ingredient.dart';
import '../../../services/ingredient_list_service.dart';
import '../../../core/constants/test_keys.dart';
import 'barcode_scanner_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService? databaseService;
  final NutritionService? nutritionService;

  const HomeScreen({super.key, this.databaseService, this.nutritionService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final NutritionService _nutrition;
  late final DatabaseService _db;
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();

  String _selectedUnit = 'g';
  final List<String> _availableUnits = ['g', 'ml']; // List of supported units
  DateTime _expirationDate = DateTime.now().add(
    const Duration(days: 7),
  ); // default 7 days

  bool _isProcessing = false;
  int? _calculatedCalories; // The calorie result of the storage and calculation
  List<String> _ingredientsList = []; // List of ingredients

  @override
  void initState() {
    super.initState();
    _nutrition = widget.nutritionService ?? NutritionService();
    _db = widget.databaseService ?? DatabaseService();
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
      // Create a food ingredient object
      final ingredient = Ingredient.create(
        name: name,
        qty: qty,
        unit: _selectedUnit,
        expirationDate: _expirationDate,
      );

      // Check for the presence of similar ingredients
      final existing = await _db.findSimilarIngredient(ingredient.name);

      if (existing != null && mounted) {
        // Compare the expiration time (only compare the date part, ignoring the hours, minutes, and seconds)
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
          // The expiration times are the same, so they will be automatically merged.
          await _db.mergeIngredient(existing, ingredient.quantity);
          if (mounted) {
            _showMsg("Merged with existing item");
            _clearForm();
          }
        } else {
          // Expiry times are inconsistent. Add as a new entry.
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

  // Display the scanning options menu
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
                    // Display loading prompt
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Searching product...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Call the OpenFoodFacts API to obtain product information
                    final productInfo = await _nutrition.getProductByBarcode(
                      barcode,
                    );

                    if (productInfo != null && mounted) {
                      final foodName = productInfo['product_name'] ?? 'Unknown';

                      // Automatically fill in the "food name" column
                      setState(() {
                        _nameController.text = foodName;
                      });

                      // Copy to clipboard
                      await Clipboard.setData(ClipboardData(text: foodName));

                      // Display the bottom message box
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
                                      'Product found and filled!',
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
                    // Display loading prompt
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Recognizing ingredient...'),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    try {
                      // Read the image and convert it to base64
                      final bytes = await File(image.path).readAsBytes();
                      final base64Image = base64Encode(bytes);

                      // Call the Baidu AI recognition API
                      final result = await _nutrition
                          .recognizeIngredientFromImage(base64Image);

                      if (result['success'] == true && mounted) {
                        final ingredientName = result['name'] as String;

                        // Automatically fill in the "food name" column
                        setState(() {
                          _nameController.text = ingredientName;
                        });

                        // Copy to clipboard
                        await Clipboard.setData(
                          ClipboardData(text: ingredientName),
                        );

                        // Display the success message
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
                                        'Ingredient recognized and filled!',
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
      key: const Key(TestKeys.homeScreenScaffold),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "FreshBasket",
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
                      setState(() {
                        _nameController.text = selection;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          // Synchronize the value of _nameController to the controller of Autocomplete
                          if (_nameController.text != controller.text) {
                            controller.text = _nameController.text;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          }

                          // Synchronize two controllers
                          controller.addListener(() {
                            if (_nameController.text != controller.text) {
                              _nameController.text = controller.text;
                            }
                          });

                          return TextField(
                            key: const Key(TestKeys.ingredientNameField),
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
                          key: const Key(TestKeys.ingredientQuantityField),
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
                          initialValue: _selectedUnit,
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
                  // Expiry Date Selector
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
                  // Buttons are placed side by side horizontally.
                  Row(
                    children: [
                      // Save button (on the left, larger)
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            key: const Key(TestKeys.ingredientSaveButton),
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
                      // Calorie Calculation Button (on the right, just the icon)
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

            // Display calorie results - Fill the width
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
