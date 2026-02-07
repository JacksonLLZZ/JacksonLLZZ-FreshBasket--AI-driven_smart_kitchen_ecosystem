# API 密钥配置说明

## 📋 概述

本项目已将所有 API 密钥独立到配置文件中，以提高安全性和可维护性。

## 🔐 配置步骤

### 1. API 配置文件位置
- **配置文件**: `lib/core/config/api_config.dart`
- **示例文件**: `.env.example`

### 2. 如何设置 API Keys

API 密钥已经在 `api_config.dart` 中配置好。如果您需要使用自己的 API 密钥，请按照以下步骤操作：

1. 打开 `lib/core/config/api_config.dart` 文件
2. 将对应的 API key 值替换为您自己的密钥
3. 保存文件

> ⚠️ **重要提示**: `api_config.dart` 文件已添加到 `.gitignore`，不会被提交到版本控制系统。

## 🔑 所需 API 服务

### 1. Edamam API (营养信息查询)
- **用途**: 食材营养信息计算
- **注册地址**: https://developer.edamam.com/
- **配置项**:
  - `edamamAppId`: 应用 ID
  - `edamamAppKey`: 应用密钥

### 2. Spoonacular API (食谱搜索)
- **用途**: 根据食材推荐食谱
- **注册地址**: https://spoonacular.com/food-api
- **配置项**:
  - `spoonacularApiKey`: API 密钥

### 3. 百度 AI (图像识别)
- **用途**: 食材图像识别功能
- **注册地址**: https://ai.baidu.com/
- **配置项**:
  - `baiduApiKey`: API Key
  - `baiduSecretKey`: Secret Key

### 4. 百度翻译 API (多语言翻译)
- **用途**: 中英文食材名称翻译
- **注册地址**: http://api.fanyi.baidu.com/
- **配置项**:
  - `baiduTranslateAppId`: 应用 ID
  - `baiduTranslateSecretKey`: 密钥

### 5. TheMealDB API
- **用途**: 食谱数据库查询
- **说明**: 免费公开 API，无需密钥
- **官网**: https://www.themealdb.com/

### 6. Firebase
- **用途**: 用户认证、云存储
- **说明**: Firebase 配置位于 `lib/firebase_options.dart`，由 FlutterFire CLI 自动生成
- **官网**: https://firebase.google.com/

### 7. Google Gemini API (可选)
- **用途**: AI 生成内容
- **说明**: 由用户在应用设置中输入，存储在 SharedPreferences
- **注册地址**: https://makersuite.google.com/app/apikey

## 📁 文件结构

```
kitchenapp-draft/
├── lib/
│   └── core/
│       └── config/
│           └── api_config.dart        # API 密钥配置 (已在 .gitignore 中)
├── .env.example                       # 配置示例文件
└── .gitignore                         # 忽略敏感配置文件
```

## 🛡️ 安全建议

1. ✅ **不要将 `api_config.dart` 提交到版本控制**（已在 .gitignore 中配置）
2. ✅ **定期更新 API 密钥**以提高安全性
3. ✅ **使用环境变量或密钥管理服务**在生产环境中管理密钥
4. ✅ **限制 API 密钥的使用范围**（如域名限制、IP 白名单等）
5. ✅ **监控 API 使用情况**以防止滥用

## 🔄 如何更新 API Keys

如果您需要更新 API 密钥：

1. 打开 `lib/core/config/api_config.dart`
2. 找到对应的配置项
3. 替换为新的 API 密钥
4. 保存文件并重新运行应用

## ❓ 常见问题

**Q: 为什么我的代码中看不到 `api_config.dart` 文件？**  
A: 该文件已添加到 `.gitignore`。首次使用时，您需要根据 `.env.example` 创建该文件。

**Q: 如何获取免费的 API 密钥？**  
A: 大多数服务提供免费试用或有限额度的免费计划。请访问各服务的官网注册。

**Q: Firebase 配置在哪里？**  
A: Firebase 配置在 `lib/firebase_options.dart`，由 FlutterFire CLI 自动生成，无需手动配置。

## 📝 更新日志

- **2026-02-07**: 将所有 API 密钥独立到配置文件中
  - 创建 `api_config.dart` 统一管理
  - 更新 `.gitignore` 保护敏感信息
  - 提供 `.env.example` 作为配置模板
