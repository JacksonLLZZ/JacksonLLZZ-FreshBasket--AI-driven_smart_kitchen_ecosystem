import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../data/ingredient.dart';
import 'package:kitchen/core/constants/app_icons.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  final DatabaseService? databaseService;

  const InventoryScreen({super.key, this.databaseService});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final DatabaseService _db;
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _db = widget.databaseService ?? DatabaseService();
  }

  /// Delete a single ingredient
  Future<void> _deleteIngredient(BuildContext context, Ingredient item) async {
    try {
      await _db.deleteIngredient(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // TODO: Implement the undo function
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  /// Switch to multiple selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  /// Batch delete the selected ingredients
  Future<void> _deleteSelectedItems(BuildContext context) async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Items'),
        content: Text('Delete ${_selectedItems.length} selected item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _db.deleteMultipleIngredients(_selectedItems.toList());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted ${_selectedItems.length} item(s)')),
          );
          setState(() {
            _selectedItems.clear();
            _isSelectionMode = false;
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  /// Edit the ingredient information (quantity and expiration date)
  Future<void> _editIngredient(BuildContext context, Ingredient item) async {
    final qtyController = TextEditingController(text: item.quantity.toString());
    DateTime selectedDate = item.expirationDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key(TestKeys.ingredientNameField),
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (${item.unit})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiration Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    selectedDate.toString().split(' ')[0],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      final newQty = double.tryParse(qtyController.text);
      if (newQty == null || newQty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return;
      }

      try {
        await _db.updateIngredient(item.id, newQty, selectedDate);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    qtyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key(TestKeys.inventoryScreenScaffold),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedItems.length} selected'
              : 'My Fridge Inventory',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected',
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () => _deleteSelectedItems(context),
            )
          else
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select Items',
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      // Use StreamBuilder to achieve real-time data updates
      body: StreamBuilder<List<Ingredient>>(
        stream: _db.getInventoryStream(),
        builder: (context, snapshot) {
          // 1. Handling loading status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handling errors
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Handle null data
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          // 4. Display data list
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isExpired = item.isExpired;

                  final isSelected = _selectedItems.contains(item.id);

                  // Use Dismissible to implement swipe deletion (only in non-selection mode)
                  Widget cardWidget = Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isSelected ? Colors.blue.shade50 : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      key: Key(
                        TestKeys.listItem(TestKeys.inventoryItemTile, index),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      onTap: _isSelectionMode
                          ? () {
                              setState(() {
                                if (isSelected) {
                                  _selectedItems.remove(item.id);
                                } else {
                                  _selectedItems.add(item.id);
                                }
                              });
                            }
                          : null,
                      onLongPress: !_isSelectionMode
                          ? () {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedItems.add(item.id);
                              });
                            }
                          : null,
                      leading: _isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedItems.add(item.id);
                                  } else {
                                    _selectedItems.remove(item.id);
                                  }
                                });
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isExpired
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.kitchen,
                                color: isExpired ? Colors.red : Colors.green,
                              ),
                            ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            isExpired ? 'Expired' : 'Fresh',
                            style: TextStyle(
                              color: isExpired ? Colors.red : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: _isSelectionMode
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.quantity} ${item.unit}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Exp: ${item.expirationDate.toString().split(' ')[0]}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isExpired
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () =>
                                      _editIngredient(context, item),
                                  tooltip: 'Edit',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                    ),
                  );

                  // Only supports sliding deletion in non-select mode.
                  if (!_isSelectionMode) {
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Item'),
                            content: Text('Delete ${item.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteIngredient(context, item);
                      },
                      child: cardWidget,
                    );
                  }

                  return cardWidget;
                },
              ),
              // The floating "Explore" button (displayed only when not in selection mode)
              if (!_isSelectionMode)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      if (items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add some ingredients first!'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeDetailScreen(ingredients: items),
                        ),
                      );
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    icon: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Explore Recipes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppIcons.fridgeSvg,
            width: 96,
            height: 96,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 16),
          const Text(
            "Your fridge is empty",
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const Text(
            "Scan or add food from the home screen",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
