import 'package:flutter/material.dart';
import 'package:kitchen/core/utils/season_helper.dart';
import '../../recipes/data/seasonal_catalog_repository.dart'; // 按你实际文件名改
import '../domain/recommendation_service.dart';             // 按你实际文件名改
import '../domain/seasonal_food.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final SeasonalCatalogRepository _repo;
  late final RecommendationService _service;

  late Future<List<SeasonalFood>> _future;
  final TextEditingController _searchController = TextEditingController();

  final Hemisphere _hemisphere = Hemisphere.northern;

  @override
  void initState() {
    super.initState();

    // 关键：assetPath 和你 repo 默认一致即可；如果你想显式传参也可以
    _repo = SeasonalCatalogRepository(assetPath: 'assets/data/season_foods.json');
    _service = RecommendationService(_repo);

    _future = _service.getSeasonalPicks(hemisphere: _hemisphere);

    _searchController.addListener(_onSearchChanged);
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
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
                      message: 'Failed to load seasonal picks:\n${snapshot.error}',
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
                    itemBuilder: (context, index) => _SeasonalFoodTile(food: items[index]),
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
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search seasonal foods (e.g., tomato, milk)',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
  const _SeasonalFoodTile({required this.food});

  final SeasonalFood food;

  @override
  Widget build(BuildContext context) {
    final subtitle = '${food.category} • shelf life ${food.defaultShelfLifeDays} days';

    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            // MVP：先占位。下一步接入真正的 ShoppingListRepository 持久化。
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added "${food.name}" (TODO: persist)')),
            );
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
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
