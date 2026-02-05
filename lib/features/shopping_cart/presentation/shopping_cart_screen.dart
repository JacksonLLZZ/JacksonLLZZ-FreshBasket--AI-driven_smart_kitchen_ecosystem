import 'package:flutter/material.dart';
import '../../shopping_list/presentation/seasonal_list_screen.dart';
import '../../../core/utils/season_helper.dart';
import '../../../main.dart'; // 导入以访问 currentTheme

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

class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Shopping Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seasonal recommendation card
            ValueListenableBuilder<String>(
              valueListenable: currentTheme,
              builder: (context, userTheme, child) {
                // 从全局主题状态获取季节
                String season;

                // 用户主题优先（Spring/Summer/Autumn/Winter）
                if (userTheme != 'Default' &&
                    [
                      'Spring',
                      'Summer',
                      'Autumn',
                      'Winter',
                    ].contains(userTheme)) {
                  season = userTheme.toLowerCase();
                } else {
                  // 回退到实际季节
                  season = SeasonHelper.getCurrentSeason(
                    hemisphere: Hemisphere.northern,
                  );
                }

                final seasonText = _seasonLabel(season);
                final message = _seasonMessage(season);

                final theme = Theme.of(context);
                final primary = theme.colorScheme.primary;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
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
                                          const SeasonalListScreen(),
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
          ],
        ),
      ),
    );
  }
}
