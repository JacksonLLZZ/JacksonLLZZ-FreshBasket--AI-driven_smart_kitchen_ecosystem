/// 测试用的 Key 常量
/// 
/// 用于 Widget 测试时定位和操作 UI 元素
class TestKeys {
  TestKeys._();

  // ==================== Home Screen ====================
  static const String homeBottomNavBar = 'home_bottom_nav_bar';
  static const String homeTabInventory = 'home_tab_inventory';
  static const String homeTabRecipes = 'home_tab_recipes';
  static const String homeTabShoppingCart = 'home_tab_shopping_cart';
  static const String homeTabProfile = 'home_tab_profile';
  static const String homeAddIngredientButton = 'home_add_ingredient_button';
  static const String homeScanBarcodeButton = 'home_scan_barcode_button';

  // ==================== Inventory Screen ====================
  static const String inventorySearchField = 'inventory_search_field';
  static const String inventoryAddButton = 'inventory_add_button';
  static const String inventoryList = 'inventory_list';
  static const String inventoryItemTile = 'inventory_item_tile';
  static const String inventoryItemName = 'inventory_item_name';
  static const String inventoryItemQuantity = 'inventory_item_quantity';
  static const String inventoryItemExpiry = 'inventory_item_expiry';
  static const String inventoryDeleteButton = 'inventory_delete_button';

  // ==================== Add/Edit Ingredient Dialog ====================
  static const String ingredientNameField = 'ingredient_name_field';
  static const String ingredientQuantityField = 'ingredient_quantity_field';
  static const String ingredientUnitField = 'ingredient_unit_field';
  static const String ingredientExpiryField = 'ingredient_expiry_field';
  static const String ingredientSaveButton = 'ingredient_save_button';
  static const String ingredientCancelButton = 'ingredient_cancel_button';

  // ==================== Recipe Screens ====================
  static const String recipeSearchField = 'recipe_search_field';
  static const String recipeList = 'recipe_list';
  static const String recipeCard = 'recipe_card';
  static const String recipeTitle = 'recipe_title';
  static const String recipeImage = 'recipe_image';
  static const String recipeCookButton = 'recipe_cook_button';
  static const String recipeDetailBackButton = 'recipe_detail_back_button';
  static const String recipeIngredientsTab = 'recipe_ingredients_tab';
  static const String recipeInstructionsTab = 'recipe_instructions_tab';

  // ==================== Shopping Cart Screen ====================
  static const String shoppingCartList = 'shopping_cart_list';
  static const String shoppingCartItemTile = 'shopping_cart_item_tile';
  static const String shoppingCartAddButton = 'shopping_cart_add_button';
  static const String shoppingCartCheckbox = 'shopping_cart_checkbox';
  static const String shoppingCartDeleteButton = 'shopping_cart_delete_button';
  static const String shoppingCartClearButton = 'shopping_cart_clear_button';

  // ==================== Profile Screen ====================
  static const String profileEmailDisplay = 'profile_email_display';
  static const String profileNameDisplay = 'profile_name_display';
  static const String profileLogoutButton = 'profile_logout_button';
  static const String profileGeminiApiField = 'profile_gemini_api_field';
  static const String profileSaveApiButton = 'profile_save_api_button';
  static const String profileThemeToggle = 'profile_theme_toggle';

  // ==================== Assistant Screen ====================
  static const String assistantMessageField = 'assistant_message_field';
  static const String assistantSendButton = 'assistant_send_button';
  static const String assistantMessageList = 'assistant_message_list';

  // ==================== Seasonal List Screen ====================
  static const String seasonalListView = 'seasonal_list_view';
  static const String seasonalItemTile = 'seasonal_item_tile';
  static const String seasonalAddToCartButton = 'seasonal_add_to_cart_button';

  // ==================== Barcode Scanner Screen ====================
  static const String barcodeScannerView = 'barcode_scanner_view';
  static const String barcodeResultText = 'barcode_result_text';
  static const String barcodeConfirmButton = 'barcode_confirm_button';

  // ==================== Login/Auth Screens ====================
  static const String loginEmailField = 'login_email_field';
  static const String loginPasswordField = 'login_password_field';
  static const String loginButton = 'login_button';
  static const String loginGoogleButton = 'login_google_button';
  static const String signupButton = 'signup_button';
  static const String signupEmailField = 'signup_email_field';
  static const String signupPasswordField = 'signup_password_field';
  static const String signupConfirmPasswordField = 'signup_confirm_password_field';

  // ==================== Common Elements ====================
  static const String confirmDialogYesButton = 'confirm_dialog_yes_button';
  static const String confirmDialogNoButton = 'confirm_dialog_no_button';
  static const String loadingIndicator = 'loading_indicator';
  static const String errorMessage = 'error_message';
  static const String successMessage = 'success_message';

  // ==================== Scaffold Keys ====================
  static const String homeScreenScaffold = 'home_screen_scaffold';
  static const String inventoryScreenScaffold = 'inventory_screen_scaffold';
  static const String profileScreenScaffold = 'profile_screen_scaffold';
  static const String shoppingCartScreenScaffold = 'shopping_cart_screen_scaffold';
  static const String seasonalListScreenScaffold = 'seasonal_list_screen_scaffold';
  static const String recipeDetailScreenScaffold = 'recipe_detail_screen_scaffold';
  static const String recipeInfoScreenScaffold = 'recipe_info_screen_scaffold';
  static const String barcodeScannerScreenScaffold = 'barcode_scanner_screen_scaffold';

  // ==================== Helper Methods ====================
  
  /// 为列表项生成索引 key
  static String listItem(String prefix, int index) => '${prefix}_$index';
  
  /// 为带 ID 的项生成 key
  static String itemWithId(String prefix, String id) => '${prefix}_$id';
}
