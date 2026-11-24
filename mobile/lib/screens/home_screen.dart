import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../utils/localization.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart';
import 'blog_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchHistory();
    });
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xFile != null && context.mounted) {
      await _analyze(context, xFile);
    }
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    if (kIsWeb) {
      Navigator.of(context).pushNamed('/scan');
      return;
    }
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (xFile != null && context.mounted) {
      await _analyze(context, xFile);
    }
  }

  Future<void> _analyze(BuildContext context, XFile file) async {
    final provider = context.read<AppProvider>();
    Navigator.of(context).pushNamed('/result');
    await provider.analyzeImage(file);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 3) {
      return ProfileScreen(
        onNavTap: (index) {
          if (index == 1) _pickFromCamera(context);
          else setState(() => _currentIndex = index);
        },
      );
    } else if (_currentIndex == 2) {
      return ChatbotScreen(
        onNavTap: (index) {
          if (index == 1) _pickFromCamera(context);
          else setState(() => _currentIndex = index);
        },
      );
    } else if (_currentIndex == 4) {
      return BlogFeedScreen(
        onBack: () => setState(() => _currentIndex = 0),
      );
    }
    
    final provider = context.watch<AppProvider>();
    final userName = provider.currentUser?['name']?.toString().split(' ').first ?? 'Farmer';
    final lang = provider.appLanguage;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${Localized.tr(lang, 'Hello')}, $userName! 👋', style: AppTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(Localized.tr(lang, 'Detect your crop disease'), style: AppTheme.headlineLarge.copyWith(color: AppTheme.textPrimary)),
                        ],
                      ),

                    ],
                  ),
                  const SizedBox(height: 28),
                  _ActionCard(
                    icon:     Icons.camera_alt_rounded,
                    title:    Localized.tr(lang, 'Open Camera'),
                    subtitle: Localized.tr(lang, 'Capture a leaf photo'),
                    gradient: AppTheme.primaryGradient,
                    onTap: () => _pickFromCamera(context),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon:     Icons.photo_library_rounded,
                    title:    Localized.tr(lang, 'Upload Image'),
                    subtitle: Localized.tr(lang, 'Pick from your photo gallery'),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _pickFromGallery(context),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Localized.tr(lang, 'Supported Crops'), style: AppTheme.headlineSmall.copyWith(color: AppTheme.textPrimary)),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/library'),
                        child: Text(Localized.tr(lang, 'View Library'), style: AppTheme.labelMedium.copyWith(color: AppTheme.accent)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _crops.asMap().entries.map((e) {
                      return _CropChip(label: Localized.tr(lang, e.value.name), emoji: e.value.emoji)
                          .animate(delay: (350 + e.key * 40).ms).fadeIn().scale(begin: const Offset(0.8, 0.8));
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Text(Localized.tr(lang, 'Quick Tips'), style: AppTheme.headlineSmall.copyWith(color: AppTheme.textPrimary)).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 12),
                  ...(_HomeScreenState.getTips(lang)).asMap().entries.map((e) {
                    return _TipCard(tip: e.value).animate(delay: (550 + e.key * 60).ms).fadeIn().slideX(begin: -0.2);
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
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
                _NavItem(icon: Icons.home_rounded, label: Localized.tr(lang, 'Home'), active: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.camera_alt_rounded, label: Localized.tr(lang, 'Scan'), active: false, onTap: () => _pickFromCamera(context)),
                _NavItem(icon: Icons.chat_bubble_rounded, label: Localized.tr(lang, 'Chatbot'), active: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: Icons.article_rounded, label: Localized.tr(lang, 'Blog'), active: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
                _NavItem(icon: Icons.person_rounded, label: Localized.tr(lang, 'Profile'), active: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<_CropData> _crops = [
    _CropData('Tomato', '🍅'), _CropData('Potato', '🥔'),
    _CropData('Wheat', '🌾'),  _CropData('Rice', '🌾'),
    _CropData('Cotton', '🌿'), _CropData('Jute', '🎋'),
  ];
  static List<String> getTips(String lang) => [
    Localized.tr(lang, 'tip1'),
    Localized.tr(lang, 'tip2'),
    Localized.tr(lang, 'tip3'),
  ];
}

class _CropData {
  final String name; final String emoji;
  const _CropData(this.name, this.emoji);
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final LinearGradient gradient; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.primaryShadow),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(title, style: AppTheme.headlineMedium.copyWith(color: Colors.white)), const SizedBox(height: 4), Text(subtitle, style: AppTheme.bodyMedium.copyWith(color: Colors.white70))],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CropChip extends StatelessWidget {
  final String label; final String emoji;
  const _CropChip({required this.label, required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.divider)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(emoji, style: TextStyle(fontSize: 14)), const SizedBox(width: 6), Text(label, style: AppTheme.labelMedium)]),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  const _TipCard({required this.tip});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Text(tip, style: AppTheme.bodyMedium),
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
