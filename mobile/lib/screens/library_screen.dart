import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/prediction_result.dart';
import '../utils/localization.dart';
import '../utils/treatment_localization.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  String _selectedCrop = 'All';
  bool _showHealthyOnly = false;

  @override
  void initState() {
    super.initState();
    // Load diseases from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadDiseases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.appLanguage;

    final crops = ['All', ...{...provider.diseases.map((d) => d.crop)}];
    final filtered = provider.diseases.where((d) {
      final matchSearch = d.disease.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.crop.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCrop   = _selectedCrop == 'All' || d.crop == _selectedCrop;
      final matchHealthy= !_showHealthyOnly || d.healthy;
      return matchSearch && matchCrop && matchHealthy;
    }).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(Localized.tr(lang, 'Disease Library'), style: AppTheme.headlineSmall),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ),

              // ── Search Bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: Localized.tr(lang, 'Search diseases or crops...'),
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.primaryLight),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),

              const SizedBox(height: 12),

              // ── Crop Filter Chips ─────────────────────────────────────
              if (crops.length > 1)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: crops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final crop   = crops[i];
                      final active = crop == _selectedCrop;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCrop = crop),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color:  active ? AppTheme.primary : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? AppTheme.primary : AppTheme.divider,
                            ),
                          ),
                           child: Text(
                             Localized.tr(lang, crop),
                             style: AppTheme.labelMedium.copyWith(
                               color: active ? Colors.white : AppTheme.textSecondary,
                             ),
                           ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              // ── Stats bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? Localized.tr(lang, 'result') : Localized.tr(lang, 'results')}',
                      style: AppTheme.bodySmall,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showHealthyOnly = !_showHealthyOnly),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _showHealthyOnly ? AppTheme.success : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _showHealthyOnly ? AppTheme.success : AppTheme.textMuted,
                              ),
                            ),
                            child: _showHealthyOnly
                                ? const Icon(Icons.check, size: 10, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(Localized.tr(lang, 'Healthy Only'), style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Disease List ──────────────────────────────────────────
              Expanded(
                child: provider.diseasesLoaded
                    ? filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    color: AppTheme.textMuted, size: 48),
                                const SizedBox(height: 12),
                                Text(Localized.tr(lang, 'No diseases found'), style: AppTheme.bodyMedium),
                              ],
                            ),
                          )
                        : AnimationLimiter(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 350),
                                  child: SlideAnimation(
                                    verticalOffset: 30,
                                    child: FadeInAnimation(
                                      child: _DiseaseCard(disease: filtered[index], lang: lang),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                    : _buildShimmer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor:  AppTheme.cardColor,
      highlightColor: AppTheme.surfaceLight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  final DiseaseListItem disease;
  final String lang;
  const _DiseaseCard({required this.disease, required this.lang});

  Color get _severityColor {
    switch (disease.severity.toLowerCase()) {
      case 'critical':        return AppTheme.error;
      case 'high':            return const Color(0xFFE64A19);
      case 'moderate to high':return AppTheme.warning;
      case 'moderate':        return AppTheme.accent;
      case 'none':            return AppTheme.success;
      default:                return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: disease.healthy ? AppTheme.success : _severityColor,
              shape: BoxShape.circle,
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Localized.tr(lang, disease.crop),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  disease.healthy ? Localized.tr(lang, 'Healthy') : Localized.tr(lang, disease.disease),
                  style: AppTheme.headlineSmall.copyWith(fontSize: 14),
                ),
                if (disease.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    // Translate the description snippet using the language-specific
                    // treatment JSON; falls back to English when lang == 'en'.
                    TreatmentLocalization.get(
                      lang, disease.label, 'symptoms', disease.description),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Severity chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _severityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _severityColor.withOpacity(0.3)),
            ),
            child: Text(
              disease.healthy
                  ? Localized.tr(lang, 'Healthy')
                  : Localized.tr(lang, disease.severity),
              style: AppTheme.bodySmall.copyWith(color: _severityColor),
            ),
          ),
        ],
      ),
    );
  }
}
