import 'package:flutter/material.dart';
import '../../../services/nutrition_service.dart';
import '../../inventory/data/ingredient.dart';
import '../data/recipe.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'recipe_info_screen.dart';
import '../../../core/constants/test_keys.dart';

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
  bool _loadedFromCache = false; //
  double _cacheOpacity = 0.0; //

  // Page numbering related
  int _currentPage =
      0; // Current page number (0-9 represent the 1st to 10th recipes)

  // Used for tracking the selected ingredients
  Map<String, bool> _selectedIngredients = {};

  // API Source Related
  String _currentApiSource = 'Spoonacular';

  // Master-Detail View: The selected recipe
  Recipe? _selectedRecipe;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Read the current API source
    final prefs = await SharedPreferences.getInstance();
    final apiSource = prefs.getString('api_source') ?? 'Spoonacular';

    // Initialize the ingredient selection status based on the API source.
    if (apiSource == 'Free') {
      // Free Recipe API: Default Select none of the options
      _selectedIngredients = {
        for (var ingredient in widget.ingredients) ingredient.id: false,
      };
    } else {
      // Spoonacular API: Default: Select All
      _selectedIngredients = {
        for (var ingredient in widget.ingredients) ingredient.id: true,
      };
    }

    setState(() {
      _currentApiSource = apiSource;
    });

    // Automatic loading of cache (if present)
    await _autoLoadCache();
  }

  // Generate cache key (based on API source and all ingredient IDs)
  String _getCacheKey() {
    final allIds = widget.ingredients.map((e) => e.id).toList()..sort();
    return 'recipes_cache_${_currentApiSource}_${allIds.join('_')}';
  }

  // Automatically load cache (if present)
  Future<void> _autoLoadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        // Cache found, automatically loaded
        final Map<String, dynamic> cacheMap = json.decode(cachedData);
        final List<dynamic> recipesJson = cacheMap['recipes'];
        final Map<String, dynamic> selectedIngredientsJson =
            cacheMap['selectedIngredients'] ?? {};

        final recipes = recipesJson
            .map((json) => Recipe.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _recipes = recipes;
            _currentPage = 0;
            _loadedFromCache = true;
            // In tablet mode, automatically select the first recipe
            _selectedRecipe = recipes.isNotEmpty ? recipes[0] : null;
            // Restore previously selected ingredient states
            if (selectedIngredientsJson.isNotEmpty) {
              _selectedIngredients = selectedIngredientsJson.map(
                (key, value) => MapEntry(key, value as bool),
              );
            }
          });

          // Fade-in animation
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _cacheOpacity = 1.0;
              });
            }
          });

          // Start fading out after 2 seconds
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (mounted) {
              setState(() {
                _cacheOpacity = 0.0;
              });
            }
          });

          // Completely hide after 2.5 seconds
          Future.delayed(const Duration(milliseconds: 3500), () {
            if (mounted) {
              setState(() {
                _loadedFromCache = false;
              });
            }
          });
        }
      }
      // If no cache, keep empty state, do nothing
    } catch (e) {
      debugPrint('Error loading cache: $e');
      // If cache loading fails, handle silently, keep empty state
    }
  }

  // Save to cache
  Future<void> _saveToCache(List<Recipe> recipes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey();
      final jsonList = recipes.map((recipe) => recipe.toJson()).toList();

      // Save both recipes and selected ingredient states
      final cacheData = {
        'recipes': jsonList,
        'selectedIngredients': _selectedIngredients,
      };

      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      debugPrint('Failed to save cache: $e');
    }
  }

  // Get selected ingredients list
  List<Ingredient> get _getSelectedIngredients {
    return widget.ingredients
        .where((ing) => _selectedIngredients[ing.id] == true)
        .toList();
  }

  // Search recipes
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
      _currentPage = 0; // Reset page number
      _loadedFromCache = false;
    });

    try {
      List<Recipe> recipes;

      // Call different APIs based on API source
      if (_currentApiSource == 'Free') {
        // Use TheMealDB API - only supports single ingredient
        if (selectedIngredients.length != 1) {
          throw Exception('Free Recipe API only supports ONE ingredient');
        }

        final ingredient = selectedIngredients.first.name;
        debugPrint('Using Free Recipe API with ingredient: $ingredient');
        recipes = await _service.generateRecipesFromMealDb(ingredient);
      } else if (_currentApiSource == 'Gemini') {
        // TODO: Call Gemini API
        debugPrint('Using Gemini API - Placeholder');
        recipes = await _service.generateCombinedRecipes(selectedIngredients);
      } else {
        // Spoonacular API (default)
        debugPrint('Using Spoonacular API');
        recipes = await _service.generateCombinedRecipes(selectedIngredients);
      }

      if (recipes.isEmpty) {
        setState(() {
          _recipes = [];
          _loading = false;
          _errorMessage = 'No recipes found for the selected ingredients.';
        });
      } else {
        // First save to cache
        await _saveToCache(recipes);
        // Then update UI
        setState(() {
          _recipes = recipes;
          _loading = false;
          _loadedFromCache = false; // Clearly mark this as new search result
          // In tablet mode, automatically select the first recipe
          _selectedRecipe = recipes.isNotEmpty ? recipes[0] : null;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Previous page
  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  // Next page
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
      key: const Key(TestKeys.recipeDetailScreenScaffold),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Recipe Finder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content area
          Column(
            children: [
              // Ingredient selection area
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
                        Icon(
                          Icons.kitchen,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select Ingredients (${_getSelectedIngredients.length}/${widget.ingredients.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // API source hint (if using Free Recipe API)
                    if (_currentApiSource == 'Free') ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Free API: Select only ONE main ingredient',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: () {
                        // Deduplicate by name, keep only the first occurrence for same name
                        final uniqueIngredients = <String, Ingredient>{};
                        for (var ingredient in widget.ingredients) {
                          if (!uniqueIngredients.containsKey(ingredient.name)) {
                            uniqueIngredients[ingredient.name] = ingredient;
                          }
                        }
                        return uniqueIngredients.values.map((ingredient) {
                          final isSelected =
                              _selectedIngredients[ingredient.id] ?? false;
                          return FilterChip(
                            label: Text(ingredient.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              // Free Recipe API limit: only one ingredient can be selected
                              if (_currentApiSource == 'Free' && selected) {
                                final selectedCount = _selectedIngredients
                                    .values
                                    .where((v) => v == true)
                                    .length;
                                if (selectedCount >= 1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Free Recipe API only allows ONE main ingredient',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() {
                                _selectedIngredients[ingredient.id] = selected;
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).primaryColor,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList();
                      }(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        key: const Key('findRecipesButton'),
                        onPressed: _loading ? null : _searchRecipes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                            : const Icon(Icons.search, size: 20),
                        label: Text(
                          _loading ? 'Searching...' : 'Find Recipes',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Results display area
              Expanded(child: _buildResultsArea()),
            ],
          ),

          // Top cache hint (floating layer)
          if (_loadedFromCache)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _cacheOpacity,
                duration: const Duration(milliseconds: 500),
                child: Material(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.15),
                          Theme.of(context).primaryColor.withOpacity(0.08),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.cached,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loaded from cache',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap "Find Recipes" to refresh',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    final isTablet = MediaQuery.of(context).size.width >= 600;

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
                key: const Key('tryAgainButton'),
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

    // Tablet mode: Master-Detail View
    if (isTablet) {
      return Row(
        children: [
          // Master: Left recipe list
          SizedBox(
            width: 400,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Found ${_recipes.length} recipes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      final isSelected = _selectedRecipe?.id == recipe.id;
                      return _buildRecipeListItem(recipe, isSelected, isTablet);
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Detail: Right recipe details
          Expanded(
            child: _selectedRecipe != null
                ? RecipeInfoScreen(recipe: _selectedRecipe!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a recipe to view details',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );
    }

    // Mobile mode: display single recipe card + page controls
    return Column(
      children: [
        // Recipe card area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildRecipeCard(_recipes[_currentPage]),
          ),
        ),

        // Page controls
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
              // Previous page button
              IconButton(
                key: const Key('previousPageButton'),
                onPressed: _currentPage > 0 ? _previousPage : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 32,
                color: _currentPage > 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),

              // Page number indicator
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

              // Next page button
              IconButton(
                key: const Key('nextPageButton'),
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

  Widget _buildRecipeListItem(Recipe recipe, bool isSelected, bool isTablet) {
    return GestureDetector(
      key: Key('recipeCard_${recipe.id}'),
      onTap: () {
        if (isTablet) {
          // Tablet mode: update selected recipe
          setState(() {
            _selectedRecipe = recipe;
          });
        } else {
          // Mobile mode: navigate to detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeInfoScreen(recipe: recipe),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: recipe.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.restaurant,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Recipe information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.usedIngredientCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.shopping_cart,
                          color: Colors.orange.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.missedIngredientCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return GestureDetector(
      key: Key('recipeCard_${recipe.id}'),
      onTap: () {
        if (!isTablet) {
          // Mobile mode: navigate to detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeInfoScreen(recipe: recipe),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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

            // Recipe information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Used ingredients
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

                  // Missing ingredients
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
      ),
    );
  }
}
