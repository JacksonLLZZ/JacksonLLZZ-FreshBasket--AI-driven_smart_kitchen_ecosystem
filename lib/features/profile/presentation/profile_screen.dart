import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService();
  
  // Edamam 支持的常见健康标签/过敏原列表
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artifacts')
            .doc("nutriscan-app-v1") 
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profileData = snapshot.data?.data() as Map<String, dynamic>?;
          final List<String> userAllergens = List<String>.from(profileData?['allergens'] ?? []);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 个人基本信息展示
                _buildHeader(user, profileData),
                const SizedBox(height: 32),
                
                // 数据统计展示 (冰箱库存数量等)
                _buildStatsSection(_db),
                const SizedBox(height: 32),

                // 过敏原与饮食偏好设置
                const Text("Dietary & Allergies", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                _buildAllergySection(userAllergens),
                const SizedBox(height: 48),
                
                // 退出登录按钮
                _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(User? user, Map<String, dynamic>? profile) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            child: const Icon(Icons.person, size: 50, color: Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          Text(
            profile?['username'] ?? "NutriScan User",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(user?.email ?? "no-email@provided.com", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DatabaseService db) {
    return StreamBuilder(
      stream: db.getInventoryStream(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("In Fridge", count.toString()),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildStatItem("Health Labels", "Active"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildAllergySection(List<String> userAllergens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: userAllergens.isEmpty 
              ? [const Text("No specific allergies set.", style: TextStyle(color: Colors.grey, fontSize: 14))]
              : userAllergens.map((label) => Chip(
                  label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                )).toList(),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showAllergenPicker(userAllergens),
            icon: const Icon(Icons.edit_note, size: 20),
            label: const Text("Manage Allergens"),
          ),
        ],
      ),
    );
  }

  void _showAllergenPicker(List<String> currentAllergens) {
    List<String> tempSelected = List.from(currentAllergens);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Manage Your Allergies", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        children: _allAllergens.map((allergen) {
                          final isSelected = tempSelected.contains(allergen);
                          return FilterChip(
                            label: Text(allergen),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  tempSelected.add(allergen);
                                } else {
                                  tempSelected.remove(allergen);
                                
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _db.updateAllergens(tempSelected);
                        if (mounted) {
                          Navigator.of(modalContext).pop(); 
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Save Preferences", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => FirebaseAuth.instance.signOut(),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("Logout", style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}