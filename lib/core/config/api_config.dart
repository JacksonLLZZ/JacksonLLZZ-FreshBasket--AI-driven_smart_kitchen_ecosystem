/// API 密钥配置文件
/// 
/// 集中管理所有第三方 API 的密钥和配置
class ApiConfig {
  // Edamam API 凭据
  // 注册地址：https://developer.edamam.com/
  static const String edamamAppId = 'd40c3d5b';
  static const String edamamAppKey = '14e8ae86c83914498144d64886f25484';

  // Spoonacular API 凭据
  // 注册地址：https://spoonacular.com/food-api
  static const String spoonacularApiKey = 'cb85e29952744463a42f1e69d51a234a';

  // 百度 AI 凭据
  // 注册地址：https://ai.baidu.com/
  static const String baiduApiKey = 'GyFqwrowPr1KvLxnKgbx5OAT';
  static const String baiduSecretKey = 'xcJuRquUcNOmT89otQUeKJwlxzr0OqRK';

  // 百度翻译 API 凭据
  // 注册地址：http://api.fanyi.baidu.com/
  static const String baiduTranslateAppId = '20240925002160847';
  static const String baiduTranslateSecretKey = 'H2BTnS1u61HgQPFZTegW';

  // TheMealDB API 基础 URL (公开 API，无需密钥)
  static const String mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
}
