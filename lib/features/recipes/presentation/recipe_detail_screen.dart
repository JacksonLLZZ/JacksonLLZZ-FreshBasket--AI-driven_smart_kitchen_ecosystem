import 'package:flutter/material.dart';
import '../../../services/nutrition_service.dart';
import '../../inventory/data/ingredient.dart';

class RecipeDetailScreen extends StatefulWidget {
  final List<Ingredient> ingredients;
  const RecipeDetailScreen({super.key, required this.ingredients});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final NutritionService _service = NutritionService();
  String _recipeContent = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
     _load();
  }

   Future<void> _load() async {
     try {
       final res = await _service.generateCombinedRecipes(widget.ingredients);
       setState(() { _recipeContent = res; _loading = false; });
     } catch (e) { setState(() => _loading = false); }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipes")),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: Text(_recipeContent)),
      ),
    );
  }
}