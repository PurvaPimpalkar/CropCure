import 'package:image_picker/image_picker.dart';
import '../models/prediction_result.dart';

/// Web stub for TFLiteService.
/// On web, dart:ffi is not available so TFLite cannot run.
/// The real implementation (tflite_service.dart) is loaded on native platforms only.
/// AppProvider checks kIsWeb before calling this, so this should never actually run.
class TFLiteService {
  static Future<void> init() async {}

  static Future<PredictionResult> predict(XFile imageFile) async {
    throw UnsupportedError(
      'TFLite on-device inference is not supported on web. '
      'The web platform uses the backend API for predictions.',
    );
  }
}
