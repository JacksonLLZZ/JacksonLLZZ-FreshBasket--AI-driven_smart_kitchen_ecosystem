import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/recipe.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipeInfoScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeInfoScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // 顶部图片与标题
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recipe.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              background: CachedNetworkImage(
                imageUrl: recipe.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 统计信息卡片
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            Icons.check_circle,
                            '${recipe.usedIngredientCount}',
                            'Have',
                            Colors.green,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _buildStatItem(
                            context,
                            Icons.shopping_cart,
                            '${recipe.missedIngredientCount}',
                            'Need',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 显示地区标签（TheMealDB 独有）
                  if (recipe.area != null || recipe.category != null) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (recipe.area != null)
                          _buildTag(
                            Icons.public,
                            recipe.area!,
                            Colors.blue,
                          ),
                        if (recipe.category != null)
                          _buildTag(
                            Icons.restaurant_menu,
                            recipe.category!,
                            Colors.purple,
                          ),
                        if (recipe.tags != null && recipe.tags!.isNotEmpty)
                          ..._buildTagsFromString(recipe.tags!),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 使用的食材
                  if (recipe.usedIngredients.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      Icons.check_circle,
                      'Ingredients You Have',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    ...recipe.usedIngredients.map(
                      (ing) => _buildIngredientTile(
                        ing,
                        Colors.green.shade50,
                        Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 缺少的食材
                  if (recipe.missedIngredients.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      Icons.shopping_cart,
                      'Ingredients to Buy',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    ...recipe.missedIngredients.map(
                      (ing) => _buildIngredientTile(
                        ing,
                        Colors.orange.shade50,
                        Colors.orange.shade600,
                      ),
                    ),
                  ],

                  // 烹饪说明（TheMealDB 独有）
                  if (recipe.instructions != null &&
                      recipe.instructions!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      context,
                      Icons.menu_book,
                      'Cooking Instructions',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          recipe.instructions!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // YouTube 视频链接（TheMealDB 独有）
                  if (recipe.youtubeUrl != null &&
                      recipe.youtubeUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      context,
                      Icons.video_library,
                      'Video Tutorial',
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: recipe.youtubeUrl!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.red.shade600,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Watch on YouTube',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Click to copy link',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.copy,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建标签
  Widget _buildTag(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // 从逗号分隔的字符串构建标签列表
  List<Widget> _buildTagsFromString(String tagsString) {
    final tags = tagsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    return tags.map((tag) => _buildTag(Icons.local_offer, tag, Colors.teal)).toList();
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    MaterialColor color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color.shade600, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    IconData icon,
    String title,
    MaterialColor color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color.shade600, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientTile(
    RecipeIngredient ingredient,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // 食材图片（如果有）
          if (ingredient.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl:
                    'https://spoonacular.com/cdn/ingredients_100x100/${ingredient.image}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.food_bank,
                    color: Colors.grey.shade500,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // 食材信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ingredient.original,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
