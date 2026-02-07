import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/database_service.dart';
import '../../../core/constants/theme.dart';
import '../../../core/constants/test_keys.dart';
// 导入 main.dart 以访问 allowAnonymousLogin 全局变量
import '../../../main.dart';
import 'package:kitchen/core/constants/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService();

  final List<String> _allAllergens = [
    'Gluten-Free',
    'Peanut-Free',
    'Tree-Nut-Free',
    'Dairy-Free',
    'Egg-Free',
    'Soy-Free',
    'Fish-Free',
    'Shellfish-Free',
    'Pork-Free',
    'Vegan',
    'Vegetarian',
    'Low-Sugar',
  ];

  final Map<String, Color> _seasonalThemes = {
    'Spring': AppTheme.springColor,
    'Summer': AppTheme.summerColor,
    'Autumn': AppTheme.autumnColor,
    'Winter': AppTheme.winterColor,
  };

  String _geminiApiKey = '';
  bool _isApiKeyValid = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key');
    if (key != null) {
      setState(() {
        _geminiApiKey = key;
        _isApiKeyValid = key.isNotEmpty;
      });
    }
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    setState(() {
      _geminiApiKey = key;
      _isApiKeyValid = key.isNotEmpty;
    });
  }

  String _seasonIconPath(String season) {
    switch (season) {
      case 'Spring':
        return AppIcons.spring;
      case 'Summer':
        return AppIcons.summer;
      case 'Autumn':
        return AppIcons.autumn;
      case 'Winter':
        return AppIcons.winter;
      default:
        return AppIcons.summer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user?.isAnonymous ?? true;

    return Scaffold(
      key: const Key(TestKeys.profileScreenScaffold),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Account & Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _db.getUserProfileStream().map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data() as Map<String, dynamic>? ?? {};
          }
          return {};
        }),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final currentTheme = data['theme'] ?? 'Default';
          final List<String> userAllergens = List<String>.from(
            data['allergens'] ?? [],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Identity Area
                isGuest ? _buildGuestLoginCard() : _buildHeader(user, data),

                const SizedBox(height: 32),

                // 2. Seasonal Themes
                const Text(
                  "App Appearance",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildThemeSelector(currentTheme),
                const SizedBox(height: 32),

                // 3. Fridge Statistics
                _buildStatsSection(_db),
                const SizedBox(height: 32),

                // 4. Dietary Profile
                const Text(
                  "Health Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAllergySection(userAllergens),
                const SizedBox(height: 32),

                // 5. Advanced Options
                _buildAdvancedOptions(),
                const SizedBox(height: 48),

                // 6. Logout Button (Only for registered users)
                if (!isGuest) _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Guest mode card with login trigger
  Widget _buildGuestLoginCard() {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 204)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 76),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text(
            "Guest Mode",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Sign in to manage and sync your fridge across all your devices.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key(TestKeys.loginButton),
            onPressed: () async {
              // Important: Break the guest loop before signing out
              allowAnonymousLogin.value = false;
              await FirebaseAuth.instance.signOut();
              // AuthWrapper in main.dart will now show AuthPage instead of AutoLoginSplash
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text(
              "Sign In / Register",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(String currentTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _seasonalThemes.entries.map((entry) {
          final isSelected = currentTheme == entry.key;
          return GestureDetector(
            onTap: () => _db.updateTheme(entry.key),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? entry.value
                          : Colors.grey.withValues(alpha: 73),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 13),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        _seasonIconPath(entry.key),
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          isSelected
                              ? entry.value
                              : Colors.grey.withValues(alpha: 77),
                          BlendMode.srcIn,
                        ),
                      ),

                      if (isSelected)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? entry.value : Colors.grey[600],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader(User? user, Map<String, dynamic> profile) {
    final primaryColor = Theme.of(context).primaryColor;
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: primaryColor.withValues(alpha: 26),
          child: ClipOval(
            child: Image.asset(
              'lib/core/constants/icon/chef_profile.png',
              width: 450,
              height: 450,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile['username'] ?? "Nutri User",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? "Email account",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(DatabaseService db) {
    return StreamBuilder(
      stream: db.getInventoryStream(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Row(
          children: [
            _buildStatCard(
              "Fridge Items",
              count.toString(),
              Icons.kitchen_outlined,
            ),
            const SizedBox(width: 16),
            _buildStatCard("Kitchen Status", "Active", Icons.eco_outlined),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergySection(List<String> allergens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allergens.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "No allergies set.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: allergens
                  .map(
                    (a) => Chip(
                      label: Text(
                        a,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.orangeAccent,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          TextButton.icon(
            onPressed: () => _showAllergenPicker(allergens),
            icon: const Icon(Icons.edit_note, size: 20),
            label: const Text("Update Health Preferences"),
          ),
        ],
      ),
    );
  }

  void _showAllergenPicker(List<String> current) {
    List<String> temp = List.from(current);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Health & Allergies",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    children: _allAllergens
                        .map(
                          (a) => FilterChip(
                            label: Text(a),
                            selected: temp.contains(a),
                            onSelected: (s) => setModalState(
                              () => s ? temp.add(a) : temp.remove(a),
                            ),
                            selectedColor: Colors.orangeAccent.withValues(
                              alpha: 55,
                            ),
                            checkmarkColor: Colors.orangeAccent,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _db.updateAllergens(temp);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Save Preferences",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return FutureBuilder<String>(
      future: _getApiSource(),
      builder: (context, snapshot) {
        final currentSource = snapshot.data ?? 'Spoonacular';
        return ExpansionTile(
          title: const Text(
            "Advanced Options",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(Icons.settings, color: Theme.of(context).primaryColor),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recipe API Source",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildApiSourceOption('Spoonacular', currentSource),
                  _buildApiSourceOption('Free Recipe', currentSource),
                  const SizedBox(height: 8),
                  Text(
                    "Current: $currentSource API",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "AI Assistant API",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: const Text('Gemini API Configuration'),
                    subtitle: _isApiKeyValid
                        ? const Text('API key is configured ✓', style: TextStyle(color: Colors.green))
                        : const Text('API key not configured', style: TextStyle(color: Colors.orange)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Gemini API Key'),
                          content: TextField(
                            key: const Key(TestKeys.profileGeminiApiField),
                            controller: TextEditingController(text: _geminiApiKey),
                            decoration: const InputDecoration(
                              hintText: 'Enter your Gemini API key',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _geminiApiKey = value;
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              key: const Key(TestKeys.profileSaveApiButton),
                              onPressed: () {
                                _saveApiKey(_geminiApiKey);
                                Navigator.pop(context);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildApiSourceOption(String source, String currentSource) {
    final isSelected = currentSource == source.split(' ')[0];
    final isComingSoon = source.contains('Coming Soon');

    return ListTile(
      dense: true,
      title: Text(
        source,
        style: TextStyle(
          fontSize: 14,
          color: isComingSoon ? Colors.grey : null,
        ),
      ),
      leading: Radio<String>(
        value: source.split(' ')[0],
        groupValue: currentSource,
        onChanged: isComingSoon
            ? null
            : (value) async {
                if (value != null) {
                  await _setApiSource(value);
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched to $value API'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : null,
    );
  }

  Future<String> _getApiSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_source') ?? 'Spoonacular';
  }

  Future<void> _setApiSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_source', source);
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          // Logic: When signing out of a REAL account, reset to Guest mode
          allowAnonymousLogin.value = true;
          await FirebaseAuth.instance.signOut();
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          "Sign Out",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withValues(alpha: 77)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
