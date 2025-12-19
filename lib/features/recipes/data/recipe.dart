class Recipe {
  final String title;
  final String summary;
  final String imageUrl; // 这里我们暂时用网络图片URL

  Recipe({
    required this.title,
    required this.summary,
    required this.imageUrl,
  });

  // 关键：这就是你之前一直缺少的 mock 方法
  factory Recipe.mock() {
    return Recipe(
      title: "经典番茄意面",
      summary: "这是一道简单又美味的意大利面，只需要番茄、大蒜和罗勒。",
      imageUrl: "https://spoonacular.com/recipeImages/716429-556x370.jpg",
    );
  }
}