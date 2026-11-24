import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../models/prediction_result.dart';

/// On-device TFLite inference service.
/// Teachable Machine model: 224×224, RGB, normalised 0-1 (pixel / 255.0).
///
/// Preprocessing pipeline (device-independent):
///   1. Decode image bytes with the `image` package.
///   2. Fix EXIF orientation so every image is upright.
///   3. Convert to RGB (drops alpha if RGBA).
///   4. Resize to 224 × 224 with bilinear interpolation.
///   5. Normalise: pixel / 255.0  →  Float32 tensor [1, 224, 224, 3].
///
/// Prediction validation:
///   greenRatio ≥ 0.12  AND  maxConfidence ≥ 0.85  → accept as crop.
///   Otherwise → return isCrop = false ("Not a Crop Image").
class TFLiteService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static Map<String, dynamic> _treatmentData = {};
  static bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;
    try {
      // 1. Load the TensorFlow Lite model
      _interpreter = await Interpreter.fromAsset('assets/model/model_unquant.tflite');

      // 2. Load labels.txt
      final rawLabels = await rootBundle.loadString('assets/model/labels.txt');
      _labels = rawLabels
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) {
            // Strip index: "0 Tomato_Early_blight" -> "Tomato_Early_blight"
            final parts = l.split(' ');
            return parts.length >= 2 ? parts.sublist(1).join('_') : l;
          })
          .toList();

      // 3. Load treatment_data.json
      final rawTreatment = await rootBundle.loadString('assets/model/treatment_data.json');
      _treatmentData = jsonDecode(rawTreatment) as Map<String, dynamic>;

      _initialized = true;
    } catch (e) {
      debugPrint('TFLite Init Error: $e');
    }
  }

  // ── Prediction Pipeline ───────────────────────────────────────────────────

  /// Run full prediction pipeline on [imageFile].
  ///
  /// Validation:
  ///   greenRatio ≥ 0.12  AND  maxConfidence ≥ 0.85  → accepted as crop.
  ///   Otherwise                                      → isCrop = false.
  static Future<PredictionResult> predict(XFile imageFile) async {
    // Ensure model + labels are loaded.
    await init();
    if (_interpreter == null) throw Exception('TFLite Interpreter not loaded');

    // Step 1 – Read raw image bytes.
    final bytes = await imageFile.readAsBytes();

    // ── Pre-model Validation & Preprocessing ───────────────────────────────
    // Runs in a single background isolate to prevent double decoding times
    // which causes the camera pipeline to hang.
    final Float32List? flatInput = await compute(_preprocessAndValidateIsolate, bytes);

    if (flatInput == null) {
      debugPrint('[TFLite] Rejected: Not a crop image (greenRatio < 0.12)');
      return PredictionResult(
        classId:    0,
        label:      '',
        crop:       '',
        disease:    '',
        healthy:    false,
        confidence: 0.0,
        top3:       [],
        isMock:     false,
        treatment:  null,
        isCrop:     false,
      );
    }
    // ────────────────────────────────────────────────────────────────────────

    // Step 6 – Build input tensor shape [1, 224, 224, 3] (float32).
    final input = flatInput.toList().reshape([1, 224, 224, 3]);

    // Step 7 – Allocate output buffer [1, numClasses].
    final numClasses = _labels.length;
    final output = List<double>.filled(numClasses, 0.0).reshape([1, numClasses]);

    // Step 8 – Run TFLite inference.
    _interpreter!.run(input, output);

    // Step 9 – Rank scores descending.
    final scores  = List<double>.from(output[0] as List);
    final indexed = List.generate(scores.length, (i) => MapEntry(i, scores[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    final int    bestIdx       = indexed[0].key;
    final double maxConfidence = indexed[0].value;
    final double secondConf    = indexed.length > 1 ? indexed[1].value : 0.0;
    final double margin        = maxConfidence - secondConf;

    debugPrint(
      '[TFLite] maxConf=${maxConfidence.toStringAsFixed(3)}  '
      'secondConf=${secondConf.toStringAsFixed(3)}  '
      'margin=${margin.toStringAsFixed(3)}',
    );

    // ── Post-model Prediction Validation ──────────────────────────────────────
    // Require ≥ 90% confidence after the pixel-level gates have already filtered
    // most non-leaf images.  90% is strict enough to reject accidental high-
    // confidence false positives (e.g. green logo at 88%) while reliably
    // accepting genuine crop-leaf scans that the model was trained on.
    const double kMinConfidence = 0.90;

    final bool isCrop = maxConfidence >= kMinConfidence;

    debugPrint('[TFLite] isCrop=$isCrop');

    if (!isCrop) {
      return PredictionResult(
        classId:    bestIdx,
        label:      '',
        crop:       '',
        disease:    '',
        healthy:    false,
        confidence: maxConfidence * 100.0,
        top3:       [],
        isMock:     false,
        treatment:  null,
        isCrop:     false,
      );
    }
    // ─────────────────────────────────────────────────────────────────────────

    // Happy path – build full prediction result.
    final label   = _labels[bestIdx];
    final (crop, disease) = _parseLabel(label);
    final healthy = label.toLowerCase().contains('healthy');

    // Build top-3 results for the UI.
    final top3 = indexed.take(3).map((e) {
      final p = _parseLabel(_labels[e.key]);
      return Top3Prediction(
        classId:    e.key,
        crop:       p.$1,
        disease:    p.$2,
        confidence: e.value * 100.0,
      );
    }).toList();

    // Fetch treatment / advice data.
    final treatment = _buildTreatment(label, healthy);

    return PredictionResult(
      classId:    bestIdx,
      label:      label,
      crop:       crop,
      disease:    disease,
      healthy:    healthy,
      confidence: maxConfidence * 100.0, // scaled 0-100 for existing UI
      top3:       top3,
      isMock:     false,
      treatment:  treatment,
      isCrop:     true,
    );
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Parse crop and disease names from label string.
  static (String, String) _parseLabel(String label) {
    // Special case for multi-word crop names (Pepper bell)
    if (label.startsWith('Pepper_bell_')) {
      final disease = label.replaceFirst('Pepper_bell_', '').replaceAll('_', ' ');
      return ('Pepper', 'Bell ${_titleCase(disease)}');
    }
    
    final underscoreIdx = label.indexOf('_');
    if (underscoreIdx == -1) return (_titleCase(label), _titleCase(label));
    
    final crop    = label.substring(0, underscoreIdx);
    final disease = label.substring(underscoreIdx + 1).replaceAll('_', ' ');
    return (_titleCase(crop), _titleCase(disease));
  }

  static String _titleCase(String s) =>
    s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

  /// Matches prediction against treatment_data.json
  static TreatmentInfo? _buildTreatment(String label, bool healthy) {
    Map<String, dynamic>? data = _treatmentData[label] as Map<String, dynamic>?;

    if (data == null) {
      final lower = label.toLowerCase();
      for (final key in _treatmentData.keys) {
        if (key.toLowerCase() == lower) {
          data = _treatmentData[key] as Map<String, dynamic>;
          break;
        }
      }
    }

    if (data == null) return null;

    final severity = data['severity'] as String? ?? (healthy ? 'None' : 'Moderate');

    return TreatmentInfo(
      description:        data['symptoms']             as String? ?? '',
      severity:           severity,
      dosage:             data['treatment']            as String? ?? '',
      applicationMethod:  data['treatment']            as String? ?? '',
      precautions:        [(data['prevention'] as String? ?? '')],
      culturalPractices:  data['advice']               as String? ?? '',
      immediateAction:    data['immediate_action']     as String? ?? '',
      chemicalTreatment:  data['chemical_treatment']   as String? ?? '',
      organicAlternative: data['organic_alternative']  as String? ?? '',
      farmerTips:         data['farmer_tips']          as String? ?? '',
      medicines:          [], // Dynamic extraction simplified for rewrite consistency
    );
  }
}

// ── Combined Validation & Preprocessing Isolate ───────────────────────────────

/// Device-independent image preprocessing for TFLite inference.
/// Parses the image ONCE and returns null if it's not a crop leaf.
Float32List? _preprocessAndValidateIsolate(Uint8List bytes) {
  // Step 1 – Decode.
  final raw = img.decodeImage(bytes);
  if (raw == null) throw Exception('Image decoding failed');

  // Step 2 – Fix EXIF orientation BEFORE checking green pixels, to be safe.
  final oriented = img.bakeOrientation(raw);

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3 – MULTI-LAYER Leaf Validation
  //
  // Layer 1 : Green pixel count  (lenient per-pixel check)
  //   Real crop leaves are often DARK green under natural lighting.
  //   G only needs to beat R and B by +15 (not +25) so shadowed leaf
  //   pixels are not rejected.  G ≥ 45 filters pitch-black objects.
  //   R ≥ 15 filters pure-artifical greens (grass paint, screens).
  //
  // Layer 2 : Texture / variance check  (primary logo/cloth rejection)
  //   Real leaves have surface texture (veins, highlights, shadows).
  //   Logos, cloth, walls, and bottles are visually UNIFORM → low variance.
  //   Threshold: variance(G) ≥ 250
  //
  // Layer 3 : Green-pixel ratio gate  (≥ 15% of image must be green)
  // ─────────────────────────────────────────────────────────────────────────

  final thumb = img.copyResize(oriented, width: 128, height: 128,
      interpolation: img.Interpolation.linear);

  int  greenPixels = 0;
  final int totalPixels = thumb.width * thumb.height;

  // Running sums for texture (variance) calculation on the green channel.
  double sumG  = 0.0;
  double sumG2 = 0.0;

  for (final pixel in thumb) {
    final int r = pixel.r.toInt();
    final int g = pixel.g.toInt();
    final int b = pixel.b.toInt();

    // ── Layer 1: Lenient natural-leaf green range ───────────────────────────
    // G > R + 15 and G > B + 15 : green is dominant (allows dark leaves).
    // G >= 45                   : not pitch-black shadow / very dark logo.
    // G <= 220                  : not washed-out sky or overexposed area.
    // R >= 15                   : real leaves have chlorophyll + red pigment.
    // R <  190                  : avoids yellow/lime false positives.
    if (g >  r + 15  &&
        g >  b + 15  &&
        g >= 45      && g <= 220 &&
        r >= 15      && r <  190) {
      greenPixels++;
    }

    // Accumulate for variance (uses ALL pixels for a robust estimate).
    final double gf = g.toDouble();
    sumG  += gf;
    sumG2 += gf * gf;
  }

  final double greenRatio = totalPixels == 0 ? 0.0 : greenPixels / totalPixels;

  // ── Layer 2: Texture / variance check ──────────────────────────────────
  // Variance(G) = E[G²] − E[G]²
  // Logos / uniform cloth / plain backgrounds: variance very low (< 250).
  // Real crop leaves (texture, veins, light variation): variance ≥ 250.
  final double meanG     = sumG / totalPixels;
  final double varianceG = (sumG2 / totalPixels) - (meanG * meanG);

  if (varianceG < 250.0) {
    return null; // Too uniform – logo, flat background, or plain cloth
  }

  // ── Layer 3: Green-pixel ratio gate ────────────────────────────────────
  // At least 15% of the image must have leaf-like green pixels.
  if (greenRatio < 0.15) {
    return null; // Not enough green leaf area in this image
  }

  // Step 4 – Convert to RGB.
  final rgb = oriented.format == img.Format.uint8 && oriented.numChannels == 3
      ? oriented
      : oriented.convert(format: img.Format.uint8, numChannels: 3);

  // Step 5 – Resize to 224 × 224.
  // Matches the input shape the Teachable Machine model was trained on.
  final resized = img.copyResize(rgb, width: 224, height: 224,
      interpolation: img.Interpolation.linear);

  // Step 6 – Normalise pixels to [0.0, 1.0] and flatten to Float32.
  final flat = Float32List(224 * 224 * 3);
  int idx = 0;
  for (final pixel in resized) {
    flat[idx++] = pixel.r / 255.0;
    flat[idx++] = pixel.g / 255.0;
    flat[idx++] = pixel.b / 255.0;
  }

  return flat;
}
