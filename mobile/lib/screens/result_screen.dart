import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/prediction_result.dart';
import '../utils/localization.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: switch (provider.state) {
            AppState.analyzing    => _buildAnalyzing(context, provider),
            AppState.success      => _buildResult(context, provider),
            AppState.error        => _buildError(context, provider),
            AppState.invalidImage => _buildInvalidImage(context, provider),
            AppState.idle         => _buildAnalyzing(context, provider),
          },
        ),
      ),
    );
  }

  Widget _buildAnalyzing(BuildContext context, AppProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                provider.reset();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),

        const Spacer(),

        // Image preview — works for web and mobile using XFile
        if (provider.selectedImage != null) ...[
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: kIsWeb
                  ? Image.network(
                      provider.selectedImage!.path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                    )
                  : _MobileImage(xFile: provider.selectedImage!),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(),
          const SizedBox(height: 32),
        ],

        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppTheme.primaryShadow,
          ),
          child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 44),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1.5.seconds, color: AppTheme.primaryLight.withValues(alpha: 0.3))
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.0, 1.0),
              duration: 800.ms,
            ),

        const SizedBox(height: 28),
        Text('Analyzing Leaf...', style: AppTheme.headlineMedium)
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 10),
        Text(
          'Our AI model is identifying the disease.\nThis takes just a few seconds.',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 32),
        SizedBox(
          width: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.surfaceLight,
              color: AppTheme.primaryLight,
              minHeight: 4,
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const Spacer(),
      ],
    );
  }

  Widget _buildResult(BuildContext context, AppProvider provider) {
    final result = provider.result!;
    final conf   = (result.confidence / 100.0).clamp(0.0, 1.0);
    final lang   = provider.appLanguage;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () {
                    provider.reset();
                    Navigator.of(context).pop();
                  },
                ),
                const Spacer(),
                Text(Localized.tr(lang, 'Detection Result'), style: AppTheme.headlineSmall.copyWith(color: AppTheme.textPrimary)),
                const Spacer(),
                if (result.isMock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text('DEMO', style: AppTheme.labelMedium.copyWith(color: AppTheme.warning)),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Image ──────────────────────────────────────────────────────
          if (provider.selectedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: kIsWeb
                          ? Image.network(
                              provider.selectedImage!.path,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _ImageFallback(),
                            )
                          : _MobileImage(xFile: provider.selectedImage!, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: result.healthy
                            ? AppTheme.success.withValues(alpha: 0.9)
                            : AppTheme.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            result.healthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                            color: Colors.white, size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            result.healthy
                                ? Localized.tr(lang, 'Healthy')
                                : 'Diseased',
                            style: AppTheme.labelMedium.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 20),

          // ── Main result card ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Localized.tr(lang,'Crop Detected'), style: AppTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(Localized.tr(lang, result.crop), style: AppTheme.displayMedium.copyWith(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 50,
                        lineWidth: 7,
                        percent: conf,
                        center: Text(
                          '${result.confidence.toStringAsFixed(0)}%',
                          style: AppTheme.headlineSmall.copyWith(color: AppTheme.accent),
                        ),
                        progressColor: AppTheme.accent,
                        backgroundColor: AppTheme.surfaceLight,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 16),
                  Text(Localized.tr(lang, 'Disease Identified'), style: AppTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    result.healthy
                        ? Localized.tr(lang, 'Healthy')
                        : Localized.tr(lang, result.disease),
                    style: AppTheme.headlineMedium.copyWith(
                      color: result.healthy ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

          const SizedBox(height: 16),

          // ── Top 3 ────────────────────────────────────────────────────
          if (result.top3.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Localized.tr(lang, 'Other Possibilities'), style: AppTheme.headlineSmall.copyWith(color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...result.top3.skip(1).take(2).map((t) => _Top3Tile(prediction: t, lang: lang)),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Always show — diseased: 'View Treatment Plan', healthy: 'View Crop Care Tips'
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/treatment'),
                    icon: Icon(
                      result.healthy
                          ? Icons.spa_rounded
                          : Icons.medical_services_rounded,
                    ),
                    label: Text(
                      result.healthy
                          ? Localized.tr(lang, 'View Crop Care Tips')
                          : Localized.tr(lang, 'View Treatment Plan'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: result.healthy
                          ? const Color(0xFF2E7D32)
                          : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.reset();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(Localized.tr(lang, 'Scan Another')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: AppTheme.divider),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 450.ms),

          const SizedBox(height: 24),

          // ── Hardcoded Farmer Advice ───────────────────────────────────
          if (!result.healthy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _FarmerAdviceCard(disease: result.disease, lang: lang),
            ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, AppProvider provider) {
    final lang = provider.appLanguage;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 72)
              .animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text('Analysis Failed', style: AppTheme.headlineLarge).animate().fadeIn(),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage ?? 'An unexpected error occurred.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                provider.reset();
                Navigator.of(context).pop();
              },
              child: Text(Localized.tr(lang, 'Try Again')),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  // ── Invalid / non-crop image screen ─────────────────────────────────────────
  Widget _buildInvalidImage(BuildContext context, AppProvider provider) {
    final lang = provider.appLanguage;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hide_image_outlined,
              color: AppTheme.warning,
              size: 52,
            ),
          )
              .animate()
              .scale(curve: Curves.elasticOut, duration: 600.ms),

          const SizedBox(height: 28),

          Text(
            Localized.tr(lang, 'Not a Crop Image'),
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              Localized.tr(
                  lang,
                  'This does not appear to be a crop leaf image. '
                  'Please upload or scan a clear photo of a crop leaf.'),
              style: AppTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),

          const SizedBox(height: 20),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _InvalidTip(text: Localized.tr(lang, 'invalid_tip1')),
                _InvalidTip(text: Localized.tr(lang, 'invalid_tip2')),
                _InvalidTip(text: Localized.tr(lang, 'invalid_tip3')),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                provider.reset();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(Localized.tr(lang, 'Scan Again')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _InvalidTip extends StatelessWidget {
  final String text;
  const _InvalidTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.primaryLight, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTheme.bodyMedium)),
        ],
      ),
    );
  }
}


// ── Image helpers (web vs mobile) ─────────────────────────────────────────────

class _MobileImage extends StatelessWidget {
  final XFile xFile;
  final BoxFit fit;
  const _MobileImage({required this.xFile, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(xFile.path),
      fit: fit,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Icon(Icons.image_not_supported_rounded,
            color: AppTheme.textMuted, size: 40),
      ),
    );
  }
}

class _Top3Tile extends StatelessWidget {
  final Top3Prediction prediction;
  final String lang;
  const _Top3Tile({required this.prediction, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Localized.tr(lang, prediction.crop), style: AppTheme.labelLarge),
                Text(
                  prediction.disease.toLowerCase() == 'healthy'
                      ? Localized.tr(lang, 'Healthy')
                      : Localized.tr(lang, prediction.disease),
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${prediction.confidence.toStringAsFixed(1)}%',
            style: AppTheme.labelMedium.copyWith(color: AppTheme.accent),
          ),
        ],
      ),
    );
  }
}

class _FarmerAdviceCard extends StatelessWidget {
  final String disease;
  final String lang;
  const _FarmerAdviceCard({required this.disease, required this.lang});

  @override
  Widget build(BuildContext context) {
    String advice = "- Maintain general field hygiene.\n- Remove infected leaves immediately.";
    String title = Localized.tr(lang, 'Farmer Advice & Precaution Tips');
    
    final lowerDisease = disease.toLowerCase();
    
    if (lowerDisease.contains('blight')) {
      advice = "- Avoid overhead irrigation.\n- Ensure proper crop spacing.\n- Promptly remove infected leaves.\n- Apply protective fungicide early.";
    } else if (lowerDisease.contains('rust')) {
      advice = "- Use resistant crop varieties.\n- Apply fungicide early in season.\n- Monitor field humidity.\n- Avoid dense planting.";
    } else if (lowerDisease.contains('bacterial')) {
      advice = "- Use certified disease-free seeds.\n- Avoid leaf wetness.\n- Disinfect your tools frequently.\n- Copper sprays can reduce spread.";
    } else if (lowerDisease.contains('spot') || lowerDisease.contains('cercospora')) {
      advice = "- Rotate crops regularly.\n- Destroy crop debris after harvest.\n- Ensure adequate plant nutrition.";
    }

    // Attempt very basic local translation of advice if needed (though requirements said hardcoded based on english keys is fine, we can just return English advice or we could hardcode translations. Requirements: "App text should dynamically update based on selected language. Do NOT translate model labels. Only translate UI labels and advice text.")
    // To satisfy the requirement "translate UI labels and advice text", I will do a quick swap if lang is hindi or marathi.
    if (lang == 'hi') {
      if (lowerDisease.contains('blight')) advice = "- ऊपर से सिंचाई से बचें।\n- फसल की छंटाई करें।\n- संक्रमित पत्तियां हटाएं।\n- फफूंदनाशक का प्रयोग करें।";
      else if (lowerDisease.contains('rust')) advice = "- प्रतिरोधी किस्मों का प्रयोग करें।\n- फफूंदनाशक जल्दी लगाएं।\n- खेत की नमी पर ध्यान दें।";
      else if (lowerDisease.contains('bacterial')) advice = "- प्रमाणित बीजों का उपयोग करें।\n- पत्तियों को गीला न होने दें।\n- उपकरणों को साफ रखें।";
      else advice = "- खेत की सफाई बनाए रखें।\n- संक्रमित पत्तियों को तुरंत हटा दें।";
    } else if (lang == 'mr') {
      if (lowerDisease.contains('blight')) advice = "- वरून सिंचन टाळा.\n- पिकांमध्ये योग्य अंतर ठेवा.\n- संक्रमित पाने काढून टाका.\n- लवकर बुरशीनाशक वापरा.";
      else if (lowerDisease.contains('rust')) advice = "- प्रतिरोधक वाणांचा वापर करा.\n- बुरशीनाशक लवकर लागू करा.\n- आर्द्रतेवर नियंत्रण ठेवा.";
      else if (lowerDisease.contains('bacterial')) advice = "- प्रमाणित बियाणे वापरा.\n- पाने ओली होऊ देऊ नका.\n- साधने निर्जंतुक करा.";
      else advice = "- शेतातील स्वच्छता राखा.\n- संक्रमित पाने त्वरित काढून टाका.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_rounded, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headlineSmall.copyWith(color: AppTheme.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice, style: AppTheme.bodyLarge.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
