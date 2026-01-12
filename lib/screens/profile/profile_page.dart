import 'package:ehr/screens/profile/setting_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ehr/constants/app_colors.dart';
import 'package:ehr/app/auth_services.dart';
import 'package:iconsax/iconsax.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser;

    Future<void> confirmLogout() async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Logout"),
            ),
          ],
        ),
      );

      if (shouldLogout ?? false) {
        try {
          await authService.value.signOut();
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(
            // ignore: use_build_context_synchronously
            context,
          ).showSnackBar(SnackBar(content: Text(e.message ?? "Logout failed")));
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: user == null
          ? _buildNoUserView()
          : CustomScrollView(
              slivers: [
                // App Bar only
                SliverAppBar(
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primaryDark,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryDark.withOpacity(0.9),
                            AppColors.primaryLight.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // User Profile Card
                      _buildProfileCard(user),
                      const SizedBox(height: 24),

                      // Settings Section
                      _buildSettingsSection(context, confirmLogout),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoUserView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No User Logged In',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please login to view your profile',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    final userInitials = user.displayName?.isNotEmpty == true
        ? user.displayName!.split(' ').map((n) => n[0]).take(2).join()
        : user.email?.substring(0, 2).toUpperCase() ?? 'DR';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with status
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User Info
          Text(
            user.displayName ?? 'Dr. ${user.email?.split('@').first ?? 'User'}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            user.email ?? 'No email provided',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Medical Professional',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to edit profile
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark.withOpacity(0.1),
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.primaryDark.withOpacity(0.2),
                  ),
                ),
              ),
              icon: const Icon(Iconsax.edit_2, size: 20),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    Future<void> Function() confirmLogout,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),

          ..._buildSettingItems(context, confirmLogout),
        ],
      ),
    );
  }
}

List<Widget> _buildSettingItems(BuildContext context, Future<void> Function() confirmLogout) {
    final List<SettingItem> items = [
      SettingItem(
        icon: Iconsax.profile_circle,
        title: 'Personal Information',
        subtitle: 'Update your personal details',
        trailing: Iconsax.arrow_right_3,
        color: AppColors.primaryDark,
        onTap: () {},
      ),
      SettingItem(
        icon: Iconsax.lock_1,
        title: 'Privacy & Security',
        subtitle: 'Manage passwords and security',
        trailing: Iconsax.arrow_right_3,
        color: const Color(0xFF4ECDC4),
        onTap: () {},
      ),
      SettingItem(
        icon: Iconsax.notification,
        title: 'Notifications',
        subtitle: 'Customize notification settings',
        trailing: Iconsax.arrow_right_3,
        color: const Color(0xFFFFA726),
        onTap: () {},
      ),
      SettingItem(
        icon: Iconsax.support,
        title: 'Help & Support',
        subtitle: 'Get help and contact support',
        trailing: Iconsax.arrow_right_3,
        color: const Color(0xFF6C63FF),
        onTap: () {},
      ),
      SettingItem(
        icon: Iconsax.logout,
        title: 'Logout',
        subtitle: 'Sign out of your account',
        trailing: Iconsax.arrow_right_3,
        color: Colors.red,
        onTap: confirmLogout,
      ),
    ];

    return items.map((item) {
      return Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 20,
                ),
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: item.color == Colors.red ? Colors.red : const Color(0xFF2D3142),
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: Icon(
              item.trailing,
              color: Colors.grey.shade400,
              size: 16,
            ),
            onTap: item.onTap,
          ),
          if (item != items.last)
            Divider(
              height: 20,
              color: Colors.grey.shade200,
            ),
        ],
      );
    }).toList();
  }