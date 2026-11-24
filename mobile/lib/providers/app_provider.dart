import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction_result.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../theme/app_theme.dart';
import '../utils/treatment_localization.dart';
// TFLite is only available on native platforms (Android, iOS, desktop)
// It cannot be imported at the top level on web due to dart:ffi unavailability.
// We use a conditional import pattern instead.
import '../services/tflite_service_stub.dart'
    if (dart.library.ffi) '../services/tflite_service.dart';

enum AppState { idle, analyzing, success, error, invalidImage }

class AppProvider extends ChangeNotifier {
  AppState _state = AppState.idle;
  PredictionResult? _result;
  String? _errorMessage;
  XFile? _selectedImage;
  List<DiseaseListItem> _diseases = [];
  bool _diseasesLoaded = false;
  bool _serverConnected = false;

  Map<String, dynamic>? _user;
  List<dynamic> _history = [];
  bool _historyLoaded = false;

  String _appLanguage = 'en'; // default english
  bool _isDarkMode = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  AppState get state => _state;
  PredictionResult? get result => _result;
  String? get errorMessage => _errorMessage;
  XFile? get selectedImage => _selectedImage;
  List<DiseaseListItem> get diseases => _diseases;
  bool get diseasesLoaded => _diseasesLoaded;
  bool get serverConnected => _serverConnected;
  bool get isAnalyzing => _state == AppState.analyzing;

  bool get isAuthenticated => _user != null;
  Map<String, dynamic>? get currentUser => _user;
  List<dynamic> get history => _history;
  bool get historyLoaded => _historyLoaded;
  String get appLanguage => _appLanguage;
  bool get isDarkMode => _isDarkMode;

  // ── Actions ───────────────────────────────────────────────────────────────

  void initTheme(bool initialMode) {
    _isDarkMode = initialMode;
    // Don't call notifyListeners() here, as this is used during init
  }

  Future<void> setLanguage(String lang) async {
    _appLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    // Pre-load treatment translations for the new language.
    await TreatmentLocalization.load(lang);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    AppTheme.configure(isDark);
    notifyListeners();
  }

  void setSelectedImage(XFile image) {
    _selectedImage = image;
    notifyListeners();
  }

  Future<void> checkServerHealth() async {
    if (kIsWeb) {
      // Web still uses the backend; check its health
      try {
        await ApiService.healthCheck();
        _serverConnected = true;
      } catch (_) {
        _serverConnected = false;
      }
    } else {
      // Native: fully offline — always "connected"
      _serverConnected = true;
    }
    notifyListeners();
  }

  Future<PredictionResult?> analyzeImage(XFile imageFile) async {
    _state = AppState.analyzing;
    _errorMessage = null;
    _result = null;
    _selectedImage = imageFile;
    notifyListeners();

    try {
      PredictionResult prediction;

      if (kIsWeb) {
        // Web: use backend API (dart:ffi / TFLite not available on web)
        prediction = await ApiService.predictDisease(imageFile);
      } else {
        // Android / iOS / Desktop: fully on-device TFLite inference
        prediction = await TFLiteService.predict(imageFile);
      }

      // ── Input Validation ───────────────────────────────────────────────────
      // Validation is performed inside TFLiteService.predict() using a
      // three-condition gate:
      //   1. greenRatio >= 0.05   (green-dominant pixels)
      //   2. maxConfidence >= 0.75 (top-class confidence)
      //   3. margin >= 0.20        (gap over 2nd-best prediction)
      // Any failure sets prediction.isCrop = false → reject the image.
      if (!prediction.isCrop) {
        _state = AppState.invalidImage;
        notifyListeners();
        return null;           // history NOT saved
      }
      // ──────────────────────────────────────────────────────────────────────


      _result = prediction;
      _state  = AppState.success;

      // Save to scan history (local SQLite on native, backend API on web)
      if (_user != null) {
        final userId = _user!['id'];
        final intId  = userId is int
            ? userId
            : int.tryParse(userId.toString()) ?? 0;

        if (kIsWeb) {
          await ApiService.saveScan(
            intId,
            prediction.crop,
            prediction.disease,
            prediction.confidence,
            prediction.treatment?.description ?? 'No treatment',
            imageFile.path,
          );
        } else {
          await LocalDbService.saveScan(
            userId:         intId,
            crop:           prediction.crop,
            disease:        prediction.disease,
            confidence:     prediction.confidence,
            treatmentShown: prediction.treatment?.description ?? 'No treatment',
            imagePath:      imageFile.path,
          );
        }
        _historyLoaded = false;
      }

      notifyListeners();
      return prediction;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state        = AppState.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Prediction failed: ${e.toString()}';
      _state        = AppState.error;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadDiseases() async {
    if (_diseasesLoaded) return;
    try {
      if (kIsWeb) {
        _diseases = await ApiService.getAllDiseases();
      } else {
        // Build disease list from bundled treatment_data.json — no backend needed
        final raw  = await rootBundle.loadString('assets/model/treatment_data.json');
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _diseases = data.entries.toList().asMap().entries.map((entry) {
          final idx  = entry.key;
          final e    = entry.value;
          final info = e.value as Map<String, dynamic>;
          final label   = e.key;
          final healthy = label.toLowerCase().contains('healthy');
          final parts   = label.split('_');
          final crop    = parts.isNotEmpty ? parts[0] : label;
          final disease = parts.length > 1
              ? parts.sublist(1).join(' ')
              : label;
          return DiseaseListItem(
            classId:     idx,
            label:       label,
            crop:        crop,
            disease:     _titleCase(disease),
            healthy:     healthy,
            severity:    (info['severity'] as String?) ?? (healthy ? 'None' : 'Moderate'),
            description: (info['symptoms'] as String?) ?? '',
          );
        }).toList();
      }
      _diseasesLoaded = true;
      notifyListeners();
    } catch (_) {
      // Silently fail
    }
  }

  static String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('is_dark_mode') ?? false;
    _isDarkMode = isDark;
    AppTheme.configure(isDark);

    final lang = prefs.getString('app_lang');
    if (lang != null) {
      _appLanguage = lang;
      // Pre-load treatment translations so they are ready before the user
      // navigates to the treatment screen.
      TreatmentLocalization.load(lang); // fire-and-forget: async but non-blocking
    }

    final userData = prefs.getString('auth_user');
    if (userData != null) {
      _user = jsonDecode(userData);
      // On web, also restore the JWT token for API calls
      if (kIsWeb) {
        final token = prefs.getString('auth_token');
        if (token != null) ApiService.setToken(token);
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      if (kIsWeb) {
        final res = await ApiService.login(email, password);
        _user = res['user'];
        ApiService.setToken(res['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', res['token']);
        await prefs.setString('auth_user', jsonEncode(_user));
      } else {
        // Native: fully local auth via SQLite
        final user = await LocalDbService.login(email, password);
        if (user == null) {
          _errorMessage = 'Invalid email or password.';
          notifyListeners();
          return false;
        }
        _user = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user', jsonEncode(_user));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    try {
      if (kIsWeb) {
        final res = await ApiService.signup(name, email, password);
        _user = res['user'];
        ApiService.setToken(res['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', res['token']);
        await prefs.setString('auth_user', jsonEncode(_user));
      } else {
        // Native: fully local signup via SQLite
        final user = await LocalDbService.signup(name, email, password);
        _user = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user', jsonEncode(_user));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    _user = null;
    _history = [];
    _historyLoaded = false;
    if (kIsWeb) ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    if (_user == null || _historyLoaded) return;
    try {
      final userId = _user!['id'];
      final intId  = userId is int
          ? userId
          : int.tryParse(userId.toString()) ?? 0;

      if (kIsWeb) {
        _history = await ApiService.getHistory(intId);
      } else {
        // Native: read from local SQLite
        _history = await LocalDbService.getHistory(intId);
      }
    } catch (e) {
      _history = [];
    } finally {
      _historyLoaded = true;
      notifyListeners();
    }
  }

  void reset() {
    _state        = AppState.idle;
    _result       = null;
    _errorMessage = null;
    _selectedImage= null;
    notifyListeners();
  }

}
