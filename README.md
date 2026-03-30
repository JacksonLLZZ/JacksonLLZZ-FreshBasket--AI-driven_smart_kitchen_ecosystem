# FreshBasket 🥗

> Smart Kitchen & Pantry Management Assistant / 智能厨房与食材管理助手
### 📖 Introduction

**FreshBasket** is a cross-platform smart kitchen assistant built with Flutter. It helps users easily manage their fridge inventory, track ingredient expiration dates, discover recipes based on what they already have, and interact with an AI culinary assistant. Whether you want to reduce food waste or find cooking inspiration, FreshBasket is your ultimate digital sous-chef.

### ✨ Product Design & Core Features

The app is designed around the user's daily kitchen lifecycle: **Restock -\> Manage -\> Cook -\> Plan**.

1.  **Smart Inventory Management (Fridge)**
      * Add ingredients with custom quantities and expiration dates.
      * Auto-calculates shelf life and sends local push notifications for items expiring within 3 days.
      * Supports swipe-to-delete and batch management.
2.  **Multi-modal Ingredient Input (Home)**
      * **Manual Input**: Smart autocomplete for standard ingredient names.
      * **Barcode Scanning**: Scan product barcodes to instantly fetch product names (via OpenFoodFacts).
      * **AI Image Recognition**: Snap a photo of an ingredient to automatically recognize it and translate it to English (Powered by Baidu AI).
      * **Nutrition Calculation**: Instantly calculate the calories of the added ingredient.
3.  **Intelligent Recipe Engine (Recipes)**
      * Recommends recipes based strictly on the ingredients currently in your fridge.
      * Automatically calculates which ingredients you "Have" and which you "Need".
      * One-click to add missing ingredients to your Shopping Cart.
      * Supports switching between different Recipe API sources (Spoonacular / TheMealDB).
4.  **Shopping Cart & Seasonal Picks**
      * Manage grocery lists effortlessly.
      * Recommends seasonal foods based on your hemisphere and the current season, which can be added to the cart instantly.
5.  **AI Kitchen Assistant**
      * Built-in chat interface powered by Google Gemini (gemini-2.5-flash).
      * Ask for meal prep advice, dietary substitutions, or step-by-step cooking guides.
6.  **Personalization & Sync**
      * Cloud sync via Firebase (Supports Email, Google Sign-in, and Guest Mode).
      * Customizable UI with four seasonal themes (Spring, Summer, Autumn, Winter).

### 🛠 Technical Solution & Architecture

FreshBasket follows a feature-driven architecture, separating presentation, domain, and data layers for high maintainability.

  * **Frontend Framework**: Flutter (Dart)
  * **Backend / BaaS**: Firebase
      * *Firebase Auth* for user authentication (Google, Email, Anonymous).
      * *Cloud Firestore* for real-time NoSQL database (syncing inventory, cart, user profiles).
  * **Local Storage & State**: `SharedPreferences` for caching recipes and user settings. `ValueNotifier` for global lightweight state management.
  * **Notifications**: `flutter_local_notifications` for scheduled expiration reminders.
  * **Third-Party API Matrix**:
      * **Recipes**: Spoonacular API / TheMealDB API
      * **Nutrition/Calories**: Edamam API
      * **Barcode DB**: OpenFoodFacts API
      * **Computer Vision**: Baidu AI Image Classification + Baidu Translate API
      * **LLM**: Google Generative AI (Gemini API)

### 🚀 Getting Started

1.  Clone the repository: `git clone https://github.com/yourusername/FreshBasket.git`
2.  Install dependencies: `flutter pub get`
3.  Configure APIs: Add your API keys in `lib/core/config/api_config.dart`. (Note: Configure your Gemini API key directly inside the app's Profile -\> Advanced Options).
4.  Run the app: `flutter run`

--------**中文版**

### 📖 项目简介

**FreshBasket** 是一款基于 Flutter 开发的跨平台智能厨房助手。它旨在帮助用户轻松管理冰箱库存、追踪食材保质期、根据现有食材智能推荐菜谱，并提供强大的 AI 烹饪问答服务。无论是为了减少食物浪费，还是寻找烹饪灵感，FreshBasket 都是您得力的数字化厨师长。

### ✨ 产品设计与核心功能

产品的交互逻辑围绕用户在厨房的日常生命周期设计：**采购 -\> 管理 -\> 烹饪 -\> 规划**。
<img width="4079" height="2538" alt="Product_Architecture" src="https://github.com/user-attachments/assets/08790798-fc89-48a8-be31-0fb1f47312c9" />
1.  **智能库存管理（Fridge）**
      * 记录食材数量、单位及过期时间。
      * 自动计算保质期，并针对 3 天内过期的食材发送本地 Push 通知提醒。
      * 支持左滑删除食材及批量勾选管理。
2.  **多模态食材录入（Home）**
      * **文本录入**：支持标准食材名称的模糊搜索与联想输入。
      * **条形码扫描**：通过扫描商品条形码自动获取食品名称（基于 OpenFoodFacts）。
      * **AI 图像识别**：拍照或上传图片，AI 自动识别果蔬食材并翻译为英文（基于百度 AI 图像识别）。
      * **营养计算**：录入食材时一键计算该分量的卡路里（基于 Edamam）。
3.  **智能菜谱推荐引擎（Recipes）**
      * 根据用户冰箱中现有的食材，智能搜索并匹配相关菜谱。
      * 自动分析菜谱成分，对比库存，直观展示“已有食材”和“缺失食材”。
      * 一键将缺失食材加入购物清单。
      * 支持多数据源切换（Spoonacular API / 免费的 TheMealDB API）。
4.  **购物车与应季推荐（Shopping Cart）**
      * 轻松管理待采买的食材清单。
      * 内置基于南北半球和当前月份的“应季食材推荐”（Seasonal Picks），支持一键加入购物车。
5.  **AI 厨房助手（Assistant）**
      * 接入 Google Gemini 大语言模型（gemini-2.5-flash）。
      * 用户可直接与 AI 对话，获取菜谱调整、食材替换方案、营养建议及分步烹饪指导。
6.  **个性化与多端同步（Profile）**
      * 基于 Firebase 的云端同步（支持邮箱、Google 账号登录及游客模式）。
      * 提供春夏秋冬（Spring, Summer, Autumn, Winter）四种专属应用主题色一键切换。

### 🛠 技术方案与架构设计

项目采用按功能模块划分（Feature-first）的目录架构，严格分离 UI 层、数据层与业务逻辑层。
<img width="1178" height="975" alt="Frame 1" src="https://github.com/user-attachments/assets/393079b3-b816-4b1e-9ed3-0924b0b8656d" />

  * **前端框架**：Flutter (Dart)
  * **后端服务 / BaaS**：Firebase
      * *Firebase Auth*：处理用户鉴权登录（包含匿名登录逻辑平滑过渡）。
      * *Cloud Firestore*：NoSQL 云数据库，实时同步用户的库存、购物车及偏好设置。
  * **本地存储与状态管理**：使用 `SharedPreferences` 实现菜谱数据的本地缓存及设置持久化；使用 `ValueNotifier` 进行轻量级全局状态响应（如主题切换、鉴权状态拦截）。
  * **本地通知机制**：集成 `flutter_local_notifications` 配合时间戳计算，实现临期食材的后台定时提醒。
  * **第三方 API 矩阵集成**：
      * **菜谱数据**：Spoonacular API / TheMealDB API
      * **营养成分**：Edamam API
      * **条码数据库**：OpenFoodFacts API
      * **计算机视觉**：百度 AI 图像分类 API + 百度翻译 API（解决中文识别转英文检索的问题）
      * **大语言模型**：Google Generative AI (Gemini API，支持流式输出响应)

### 🚀 运行指南
1.  配置 API 密钥：在 `lib/core/config/api_config.dart` 文件中填入相应的第三方 API Key。（注：Gemini 的 API Key 可直接在 App 内部的 Profile -\> Advanced Options 中配置）。
2.  需要提前下载Android Studio软件并配置好安卓模拟器
3.  本项目配置的有手机和平板两种模式

