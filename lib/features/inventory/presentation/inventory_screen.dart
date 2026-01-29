import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../data/ingredient.dart';
import 'package:kitchen/core/constants/app_icons.dart';
import 'package:kitchen/core/constants/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 实例化数据库服务
    final DatabaseService db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Fridge Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // 使用 StreamBuilder 实现实时数据更新
      body: StreamBuilder<List<Ingredient>>(
        stream: db.getInventoryStream(),
        builder: (context, snapshot) {
          // 1. 处理加载状态
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. 处理错误
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. 处理空数据
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          // 4. 展示数据列表
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
              final item = items[index];
              final isExpired = item.isExpired;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.kitchen,
                      color: isExpired ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      // 显示分类标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.category, style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(isExpired ? 'Expired' : 'Fresh', 
                           style: TextStyle(color: isExpired ? Colors.red : Colors.green, fontSize: 12)),
                      if (item.calories != null)
                        Text(item.calories!, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        "Exp: ${item.expirationDate.toString().split(' ')[0]}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // 悬浮的探索按钮
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                if (items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add some ingredients first!')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(ingredients: items),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text(
                'Explore Recipes',
                style: TextStyle(fontWeight: FontWeight.bold),
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
          const Text("Your fridge is empty", style: TextStyle(color: Colors.grey, fontSize: 18)),
          const Text("Scan or add food from the home screen", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}