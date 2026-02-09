/// API Key Configuration File
/// 
/// Centralized management of all third-party API keys and configurations
class ApiConfig {
  // Edamam API credentials
  // Registration URL: https://developer.edamam.com/
  static const String edamamAppId = 'd40c3d5b';
  static const String edamamAppKey = '14e8ae86c83914498144d64886f25484';

  // Spoonacular API credentials
  // Registration URL: https://spoonacular.com/food-api
  static const String spoonacularApiKey = 'cb85e29952744463a42f1e69d51a234a';

  // Baidu AI credentials
  // Registration URL: https://ai.baidu.com/
  static const String baiduApiKey = 'GyFqwrowPr1KvLxnKgbx5OAT';
  static const String baiduSecretKey = 'xcJuRquUcNOmT89otQUeKJwlxzr0OqRK';

  // Baidu Translation API credentials
  // Registration URL: http://api.fanyi.baidu.com/
  static const String baiduTranslateAppId = '20240925002160847';
  static const String baiduTranslateSecretKey = 'H2BTnS1u61HgQPFZTegW';

  // TheMealDB API base URL (public API, no key required)
  static const String mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
}
