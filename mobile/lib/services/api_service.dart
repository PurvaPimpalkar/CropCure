import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../models/prediction_result.dart';

class ApiService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _authHeaders {
    if (_token != null) {
      return {'Authorization': 'Bearer $_token'};
    }
    return {};
  }

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.208.116.48:8000';
  }

  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health')).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Server returned ${response.statusCode}');
    } catch (e) {
      throw ApiException('Cannot connect to server. Is the backend running?');
    }
  }

  static Future<PredictionResult> predictDisease(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/predict'));
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PredictionResult.fromJson(json);
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(json['detail'] as String? ?? 'Invalid image');
      } else {
        throw ApiException('Server error: ${response.statusCode}');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Prediction failed: ${e.toString()}');
    }
  }

  static Future<List<DiseaseListItem>> getAllDiseases() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/diseases')).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> list = json['diseases'] as List<dynamic>;
        return list.map((e) => DiseaseListItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw ApiException('Failed to load diseases: ${response.statusCode}');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  static Future<List<String>> getSupportedCrops() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/crops')).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['crops'] as List<dynamic>).map((e) => e as String).toList();
      }
      throw ApiException('Failed to load crops: ${response.statusCode}');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(_timeout);
      
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) return json;
      throw ApiException(json['detail'] ?? 'Signup failed');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during signup');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);
      
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) return json;
      throw ApiException(json['detail'] ?? 'Login failed');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during login');
    }
  }

  static Future<void> saveScan(int userId, String crop, String disease, double confidence, String treatmentShown, String imagePath) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/history'),
        headers: {'Content-Type': 'application/json', ..._authHeaders},
        body: jsonEncode({
          'user_id': userId,
          'crop': crop,
          'disease': disease,
          'confidence': confidence,
          'treatment_shown': treatmentShown,
          'image_path': imagePath
        }),
      ).timeout(_timeout);
      if (response.statusCode != 200) throw ApiException('Failed to save scan');
    } catch (e) {
      print('Failed to save scan: $e');
    }
  }

  static Future<List<dynamic>> getHistory(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/history/$userId'), headers: _authHeaders).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['history'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
