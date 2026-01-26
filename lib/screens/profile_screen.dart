import 'package:flutter/material.dart';
import '../services/dummy_data_service.dart';
import '../theme/instagram_theme.dart';
import '../widgets/clay_container.dart';
import 'login_screen.dart';
import 'content_settings_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = DummyDataService().getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: InstagramTheme.textBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ClayContainer(
                    width: 100,
                    height: 100,
                    borderRadius: 50,
                    child: Center(
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: InstagramTheme.primaryPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (user.bio != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        user.bio!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(context, 'Posts', user.posts),
                      _buildStatColumn(context, 'Followers', user.followers),
                      _buildStatColumn(context, 'Following', user.following),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ClayButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          color: InstagramTheme.surfaceWhite,
                          child: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClayButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          child: const Text('Settings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: InstagramTheme.dividerGrey),

            // Profile Sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileSection(
                    context,
                    icon: Icons.photo_library_outlined,
                    title: 'Uploaded Videos & Images',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Media gallery coming soon')),
                      );
                    },
                  ),
                  _buildProfileSection(
                    context,
                    icon: Icons.ads_click,
                    title: 'Posted Ads',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Posted ads coming soon')),
                      );
                    },
                  ),
                  _buildProfileSection(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet & Coins',
                    subtitle: '${user.coins} coins',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const WalletScreen()),
                      );
                    },
                  ),
                  _buildProfileSection(
                    context,
                    icon: Icons.card_giftcard,
                    title: 'Redeem Rewards',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rewards coming soon')),
                      );
                    },
                  ),
                  _buildProfileSection(
                    context,
                    icon: Icons.build_outlined,
                    title: 'Tools',
                    subtitle: 'AI features, fonts, colors, auto reply, avatar',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tools coming soon')),
                      );
                    },
                  ),
                  _buildProfileSection(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text(
          _formatCount(value),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: InstagramTheme.primaryPink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildProfileSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClayContainer(
        borderRadius: 16,
        color: InstagramTheme.surfaceWhite,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: InstagramTheme.primaryPink),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: InstagramTheme.textBlack,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: InstagramTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = DummyDataService().getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: InstagramTheme.textBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  ClayContainer(
                    width: 100,
                    height: 100,
                    borderRadius: 50,
                    child: Center(
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: InstagramTheme.primaryPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo upload coming soon')),
                      );
                    },
                    child: const Text('Change Profile Photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField('Name', user.name),
            const SizedBox(height: 16),
            _buildTextField('Bio', user.bio, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField('Email', user.email),
            const SizedBox(height: 16),
            _buildTextField('Phone', user.phone),
            const SizedBox(height: 16),
            _buildTextField('Address', user.address, maxLines: 2),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ClayButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated')),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String? value, {int maxLines = 1}) {
    return TextFormField(
      initialValue: value,
      style: const TextStyle(color: InstagramTheme.textBlack),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: InstagramTheme.textGrey),
        prefixIcon: const Icon(Icons.edit_outlined, color: InstagramTheme.textGrey),
      ),
      maxLines: maxLines,
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: InstagramTheme.textBlack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context,
            'Preferences',
            [
              _buildSettingsTile(
                context,
                Icons.language,
                'Language / Region',
                'Default: English',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language settings coming soon')),
                  );
                },
              ),
              _buildSettingsTile(
                context,
                Icons.notifications_outlined,
                'Notifications',
                'Manage notifications',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings coming soon')),
                  );
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'Account',
            [
              _buildSettingsTile(
                context,
                Icons.privacy_tip_outlined,
                'Privacy',
                'Privacy settings',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings coming soon')),
                  );
                },
              ),
              _buildSettingsTile(
                context,
                Icons.security,
                'Security',
                'Password, 2FA',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Security settings coming soon')),
                  );
                },
              ),
              _buildSettingsTile(
                context,
                Icons.shield_outlined,
                'Content Settings',
                'Moderation & restrictions',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ContentSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            'About',
            [
              _buildSettingsTile(
                context,
                Icons.info_outline,
                'About b Smart',
                'Version 1.0.0',
                () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'b Smart',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
              _buildSettingsTile(
                context,
                Icons.help_outline,
                'Help & Support',
                'Get help',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ClayButton(
                  onPressed: () => _showLogoutDialog(context),
                  color: InstagramTheme.primaryPink,
                  child: const Text('Logout'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ClayButton(
                  onPressed: () => _showDeleteAccountDialog(context),
                  color: InstagramTheme.errorRed,
                  child: const Text('Delete Account'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: InstagramTheme.primaryPink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClayContainer(
        borderRadius: 16,
        color: InstagramTheme.surfaceWhite,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: InstagramTheme.textGrey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: InstagramTheme.textBlack,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: InstagramTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: InstagramTheme.surfaceWhite,
        title: const Text('Logout', style: TextStyle(color: InstagramTheme.textBlack)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: InstagramTheme.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: InstagramTheme.primaryPink)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: InstagramTheme.surfaceWhite,
        title: const Text('Delete Account', style: TextStyle(color: InstagramTheme.textBlack)),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: InstagramTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: InstagramTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}
