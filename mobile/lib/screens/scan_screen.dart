import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../utils/localization.dart';

/// Camera scan screen.
///
/// On **Android/iOS**: uses the `camera` package for a live viewfinder with
/// an animated scanning frame.
/// On **Web**:  since the `camera` package is not supported on web, this screen
/// shows a polished UI with an "Open Camera" button that triggers the browser's
/// native `getUserMedia` camera via `image_picker` (which is fully web-compatible).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 720,
        maxHeight: 720,
      );
      if (xFile != null && mounted) {
        Navigator.of(context).pushNamed('/result');
        await context.read<AppProvider>().analyzeImage(xFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 720,
        maxHeight: 720,
      );
      if (xFile != null && mounted) {
        Navigator.of(context).pushNamed('/result');
        await context.read<AppProvider>().analyzeImage(xFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open gallery: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().appLanguage;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(Localized.tr(lang, 'Scan Leaf'), style: AppTheme.headlineSmall),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ),

              const Spacer(),

              // ── Scanner visual ────────────────────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),

                  // Animated scan frame
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(painter: _FramePainter()),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 2.seconds,
                        color: AppTheme.primaryLight.withValues(alpha: 0.4),
                      ),

                  // Animated scan line
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: _AnimatedScanLine(),
                  ),

                  // Center icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.primaryShadow,
                    ),
                    child: const Icon(
                      Icons.local_florist_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.0, 1.0),
                        duration: 1.2.seconds,
                      ),
                ],
              ).animate().fadeIn(delay: 200.ms).scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.elasticOut,
                duration: 800.ms,
              ),

              const SizedBox(height: 32),

              Text(
                Localized.tr(lang, 'Identify Crop Disease'),
                style: AppTheme.headlineLarge,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  kIsWeb
                      ? Localized.tr(lang, 'Click below to open your webcam or upload a photo from your device')
                      : Localized.tr(lang, 'Take a photo of the affected leaf for instant AI diagnosis'),
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
              ),

              const SizedBox(height: 36),

              // ── Action Buttons ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCapturing ? null : _captureAndAnalyze,
                        icon: _isCapturing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded),
                        label: Text(kIsWeb ? Localized.tr(lang, 'Open Webcam') : Localized.tr(lang, 'Take a Photo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: AppTheme.headlineMedium.copyWith(fontSize: 16),
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCapturing ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(Localized.tr(lang, 'Upload from Gallery')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: AppTheme.divider, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  ],
                ),
              ),

              const Spacer(),

              // ── Web notice ────────────────────────────────────────────────
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your browser will ask for camera permission when you click "Open Webcam".',
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 28.0;
    final w = size.width;
    final h = size.height;

    canvas.drawPath(Path()..moveTo(0, corner)..lineTo(0, 0)..lineTo(corner, 0), paint);
    canvas.drawPath(Path()..moveTo(w - corner, 0)..lineTo(w, 0)..lineTo(w, corner), paint);
    canvas.drawPath(Path()..moveTo(0, h - corner)..lineTo(0, h)..lineTo(corner, h), paint);
    canvas.drawPath(Path()..moveTo(w - corner, h)..lineTo(w, h)..lineTo(w, h - corner), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedScanLine extends StatefulWidget {
  @override
  State<_AnimatedScanLine> createState() => _AnimatedScanLineState();
}

class _AnimatedScanLineState extends State<_AnimatedScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: 250.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        children: [
          Positioned(
            top: _anim.value,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryLight.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
