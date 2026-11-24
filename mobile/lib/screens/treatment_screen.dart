import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/prediction_result.dart';
import '../utils/localization.dart';
import '../utils/treatment_localization.dart';

class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AppProvider>();
    final lang      = provider.appLanguage;
    final result    = provider.result;
    final treatment = result?.treatment;
    // Convenience helper: translate a treatment content field using the
    // language-specific JSON, falling back to the English text from JSON.
    String tc(String field, String fallback) =>
        TreatmentLocalization.get(lang, result?.label ?? '', field, fallback);

    if (result == null || treatment == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: Center(
            child: Text(Localized.tr(lang, 'No treatment data available.'),
                style: AppTheme.bodyMedium),
          ),
        ),
      );
    }

    final isHealthy = result.healthy;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── App Bar ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Text(Localized.tr(lang, 'Treatment Plan'),
                          style: AppTheme.headlineSmall),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                ),
              ),

              // ── Disease / Healthy Banner ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: treatment.severityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: treatment.severityColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: treatment.severityColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHealthy
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            color: treatment.severityColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${Localized.tr(lang, result.crop)} — '
                                '${Localized.tr(lang, result.disease)}',
                                style: AppTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text('${Localized.tr(lang, "Severity")}: ',
                                    style: AppTheme.bodySmall),
                                Text(
                                  Localized.tr(lang, treatment.severity),
                                  style: AppTheme.labelMedium.copyWith(
                                      color: treatment.severityColor),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${Localized.tr(lang, "Confidence")}: ${result.confidence.toStringAsFixed(1)}%',
                                  style: AppTheme.labelMedium.copyWith(
                                      color: AppTheme.primaryLight,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                ),
              ),

              // ── HEALTHY crop branch ────────────────────────────────────────
              if (isHealthy) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: _SectionCard(
                    icon: Icons.spa_rounded,
                    title: '🌿 ${Localized.tr(lang, "Crop Status: Healthy")}',
                    accentColor: const Color(0xFF2E7D32),
                    delay: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Localized.tr(lang,
                              'No treatment required. Maintain regular crop care and monitoring.'),
                          style: AppTheme.bodyLarge.copyWith(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(Localized.tr(lang, 'Maintenance Tips:'),
                            style: AppTheme.labelLarge),
                        const SizedBox(height: 8),
                        ...[
                          Localized.tr(lang, 'healthy_tip1'),
                          Localized.tr(lang, 'healthy_tip2'),
                          Localized.tr(lang, 'healthy_tip3'),
                          Localized.tr(lang, 'healthy_tip4'),
                          Localized.tr(lang, 'healthy_tip5'),
                        ].map((tip) => _BulletTip(text: tip)),
                      ],
                    ),
                  ),
                ),
                // Show cultural practices / advice from JSON if available
                if (treatment.culturalPractices.isNotEmpty &&
                    treatment.culturalPractices != 'N/A')
                  SliverToBoxAdapter(
                    child: _SectionCard(
                      icon: Icons.agriculture_rounded,
                      title: Localized.tr(lang, 'Crop Care Advice'),
                      accentColor: const Color(0xFF2E7D32),
                      delay: 250,
                      child: Text(
                          tc('advice', treatment.culturalPractices),
                          style: AppTheme.bodyLarge),
                    ),
                  ),
              ],

              // ── DISEASED crop branch ───────────────────────────────────────
              if (!isHealthy) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // About This Disease
                SliverToBoxAdapter(
                  child: _SectionCard(
                    icon: Icons.info_outline_rounded,
                    title: Localized.tr(lang, 'About This Disease'),
                    delay: 150,
                    child: Text(tc('symptoms', treatment.description),
                        style: AppTheme.bodyLarge),
                  ),
                ),

                // Immediate Action
                if (treatment.immediateAction.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionCard(
                      icon: Icons.bolt_rounded,
                      title: '⚡ ${Localized.tr(lang, "Immediate Action Required")}',
                      accentColor: const Color(0xFFE64A19),
                      delay: 200,
                      child: Text(
                          tc('immediate_action', treatment.immediateAction),
                          style: AppTheme.bodyLarge),
                    ),
                  ),

                // Recommended Medicines
                if (treatment.medicines.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionCard(
                      icon: Icons.medication_rounded,
                      title: Localized.tr(lang, 'Recommended Medicines'),
                      delay: 250,
                      child: AnimationLimiter(
                        child: Column(
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 350),
                            childAnimationBuilder: (w) => SlideAnimation(
                              horizontalOffset: 40,
                              child: FadeInAnimation(child: w),
                            ),
                            children: treatment.medicines
                                .map((m) => _MedicineTile(medicine: m, lang: lang))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Chemical Treatment
                if (treatment.chemicalTreatment.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionCard(
                      icon: Icons.science_rounded,
                      title: '🧪 ${Localized.tr(lang, "Chemical Treatment")}',
                      delay: 300,
                      child: Text(
                          tc('chemical_treatment', treatment.chemicalTreatment),
                          style: AppTheme.bodyLarge),
                    ),
                  ),

                // Organic Alternative
                if (treatment.organicAlternative.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionCard(
                      icon: Icons.eco_rounded,
                      title: '🌿 ${Localized.tr(lang, "Organic Alternative")}',
                      accentColor: const Color(0xFF388E3C),
                      delay: 350,
                      child: Text(
                          tc('organic_alternative', treatment.organicAlternative),
                          style: AppTheme.bodyLarge),
                    ),
                  ),

                // Precautions
                if (treatment.precautions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionCard(
                      icon: Icons.shield_rounded,
                      title: Localized.tr(lang, 'Precautions'),
                      delay: 400,
                      child: Column(
                        children: treatment.precautions
                            .map((p) => _PrecautionTile(
                                  text: tc('prevention', p),
                                ))
                            .toList(),
                      ),
                    ),
                  ),

                // Farmer Tips
                if (treatment.farmerTips.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FarmerTipsCard(
                        tips: tc('farmer_tips', treatment.farmerTips),
                        lang: lang,
                        delay: 450),
                  ),

                // Cultural Practices
                if (treatment.culturalPractices.isNotEmpty &&
                    treatment.culturalPractices != 'N/A')
                  SliverToBoxAdapter(
                    child: _SectionCard(
                      icon: Icons.agriculture_rounded,
                      title: Localized.tr(lang, 'Cultural Practices'),
                      delay: 500,
                      child: Text(
                          tc('advice', treatment.culturalPractices),
                          style: AppTheme.bodyLarge),
                    ),
                  ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Section Card
// =============================================================================

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final int delay;
  final Color? accentColor;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.delay,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: AppTheme.headlineSmall.copyWith(fontSize: 15)),
              ),
            ]),
            const SizedBox(height: 16),
            Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ).animate()
          .fadeIn(delay: Duration(milliseconds: delay))
          .slideY(begin: 0.2),
    );
  }
}

// =============================================================================
// Farmer Tips Card
// =============================================================================

class _FarmerTipsCard extends StatelessWidget {
  final String tips;
  final String lang;
  final int delay;
  const _FarmerTipsCard(
      {required this.tips, required this.lang, required this.delay});

  @override
  Widget build(BuildContext context) {
    final lines = tips
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B5E20).withOpacity(0.12),
              AppTheme.cardGradient.colors.last,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.35)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tips_and_updates_rounded,
                      color: Color(0xFF2E7D32), size: 20),
                ),
                const SizedBox(width: 12),
                Text('👨‍🌾 ${Localized.tr(lang, "Farmer Advice")}',
                    style: AppTheme.headlineSmall.copyWith(fontSize: 15)),
              ]),
            ),
            Divider(
                height: 1,
                color: const Color(0xFF2E7D32).withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: lines
                    .map((tip) => _FarmerTipTile(text: tip))
                    .toList(),
              ),
            ),
          ],
        ),
      ).animate()
          .fadeIn(delay: Duration(milliseconds: delay))
          .slideY(begin: 0.2),
    );
  }
}

class _FarmerTipTile extends StatelessWidget {
  final String text;
  const _FarmerTipTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child:
                  Text(text, style: AppTheme.bodyLarge.copyWith(height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bullet Tip (healthy crop)
// =============================================================================

class _BulletTip extends StatelessWidget {
  final String text;
  const _BulletTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child:
                Text(text, style: AppTheme.bodyLarge.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Medicine Tile
// =============================================================================

class _MedicineTile extends StatelessWidget {
  final MedicineInfo medicine;
  final String lang;
  const _MedicineTile({required this.medicine, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.medication_liquid_rounded,
              color: AppTheme.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name, style: AppTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  Localized.tr(lang, medicine.type),
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.accent.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Precaution Tile
// =============================================================================

class _PrecautionTile extends StatelessWidget {
  final String text;
  const _PrecautionTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.warning_amber_rounded,
                color: AppTheme.warning, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTheme.bodyLarge)),
        ],
      ),
    );
  }
}
