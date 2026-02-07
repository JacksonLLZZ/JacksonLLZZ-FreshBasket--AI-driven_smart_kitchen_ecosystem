import 'package:flutter/material.dart';
import 'package:kitchen/core/utils/season_helper.dart';
import '../../recipes/data/seasonal_catalog_repository.dart'; // 按你实际文件名改
import '../domain/recommendation_service.dart'; // 按你实际文件名改
import '../domain/seasonal_food.dart';
import '../../../services/database_service.dart';
import '../../shopping_cart/data/shopping_item.dart';
import '../../../core/constants/test_keys.dart';

class SeasonalListScreen extends StatefulWidget {
  const SeasonalListScreen({super.key});

  @override
  State<SeasonalListScreen> createState() => _SeasonalListScreenState();
}

class _SeasonalListScreenState extends State<SeasonalListScreen> {
  late final SeasonalCatalogRepository _repo;
  late final RecommendationService _service;
  final DatabaseService _db = DatabaseService();

  late Future<List<SeasonalFood>> _future;
  final TextEditingController _searchController = TextEditingController();
  List<ShoppingItem> _cartItems = [];

  final Hemisphere _hemisphere = Hemisphere.northern;

  @override
  void initState() {
    super.initState();

    // 关键：assetPath 和你 repo 默认一致即可；如果你想显式传参也可以
    _repo = SeasonalCatalogRepository(
      assetPath: 'assets/data/season_foods.json',
    );
    _service = RecommendationService(_repo);

    _future = _service.getSeasonalPicks(hemisphere: _hemisphere);

    _searchController.addListener(_onSearchChanged);

    // 监听购物车变化
    _db.getShoppingCartStream().listen((items) {
      if (mounted) {
        setState(() {
          _cartItems = items;
        });
      }
    });
  }

  bool _isInCart(String foodName) {
    return _cartItems.any(
      (item) => item.name.toLowerCase() == foodName.toLowerCase(),
    );
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    setState(() {
      _future = q.isEmpty
          ? _service.getSeasonalPicks(hemisphere: _hemisphere)
          : _service.search(q);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      final q = _searchController.text.trim();
      _future = q.isEmpty
          ? _service.getSeasonalPicks(hemisphere: _hemisphere)
          : _service.search(q);
    });
    await _future;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key(TestKeys.seasonalListScreenScaffold),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Seasonal List'),
        actions: [
          IconButton(
            key: const Key('refreshButton'),
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchController),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<SeasonalFood>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message:
                          'Failed to load seasonal picks:\n${snapshot.error}',
                      onRetry: _refresh,
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _SeasonalFoodTile(
                      food: items[index],
                      isInCart: _isInCart(items[index].name),
                      db: _db,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        key: const Key('searchTextField'),
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search seasonal foods (e.g., tomato, milk)',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SeasonalFoodTile extends StatelessWidget {
  const _SeasonalFoodTile({
    required this.food,
    required this.isInCart,
    required this.db,
  });

  final SeasonalFood food;
  final bool isInCart;
  final DatabaseService db;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${food.category} • shelf life ${food.defaultShelfLifeDays} days';

    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        title: Text(
          food.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: isInCart
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              )
            : IconButton(
                key: Key('addToCartButton_${food.name}'),
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () async {
                  final item = ShoppingItem.create(
                    name: food.name,
                    amount: 'As needed',
                  );
                  try {
                    await db.addToShoppingCart(item);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${food.name}" added to cart'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add: ${e.toString()}'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No recommendations found.\nTry another search term.'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('retryButton'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
