import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization.dart';
import 'scan_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Function(int) onNavTap;
  const ProfileScreen({super.key, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.currentUser != null && !provider.historyLoaded) {
        provider.fetchHistory();
      }
    });

    final lang = provider.appLanguage;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(Localized.tr(lang, 'Profile & Dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              provider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          )
        ],
      ),
      body: SafeArea(
        child: user == null
            ? Center(child: Text(Localized.tr(lang, 'Not logged in')))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        user['name'].toString().substring(0, 1).toUpperCase(),
                        style: AppTheme.displayMedium.copyWith(color: AppTheme.background),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user['name'], style: AppTheme.headlineMedium),
                    Text(user['email'], style: AppTheme.bodyMedium),
                    const SizedBox(height: 28),

                    // ── Settings List ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [

                          // Language selection
                          _SettingsTile(
                            icon: Icons.language_rounded,
                            title: 'Language / भाषा',
                            trailing: DropdownButton<String>(
                              value: provider.appLanguage,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English')),
                                DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                                DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                              ],
                              onChanged: (val) {
                                if (val != null) provider.setLanguage(val);
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Dark Mode Toggle
                          _SettingsTile(
                            icon: Icons.dark_mode_rounded,
                            title: Localized.tr(lang, 'Dark Mode'),
                            trailing: Switch(
                              value: provider.isDarkMode,
                              activeColor: AppTheme.primary,
                              onChanged: (val) => provider.toggleDarkMode(val),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Scan History → navigates to separate screen
                          _SettingsTile(
                            icon: Icons.history_rounded,
                            title: Localized.tr(lang, 'Scan History'),
                            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: Localized.tr(lang, 'Home'), active: false, onTap: () => onNavTap(0)),
                _NavItem(icon: Icons.camera_alt_rounded, label: Localized.tr(lang, 'Scan'), active: false, onTap: () => onNavTap(1)),
                _NavItem(icon: Icons.chat_bubble_rounded, label: Localized.tr(lang, 'Chatbot'), active: false, onTap: () => onNavTap(2)),
                _NavItem(icon: Icons.person_rounded, label: Localized.tr(lang, 'Profile'), active: true, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable settings row tile ────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.title, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryLight, size: 22),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppTheme.primary : AppTheme.textMuted, size: 26),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.bodySmall.copyWith(color: active ? AppTheme.primary : AppTheme.textMuted, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}
