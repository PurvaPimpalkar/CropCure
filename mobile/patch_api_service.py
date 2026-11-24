import re

with open("d:/cropcure_final/mobile/lib/services/api_service.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Add models to ApiService definitions if needed, however, we can just return raw responses.
api_service_additions = """
  // ── Authentication ────────────────────────────────────────────────────────
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

  // ── History ─────────────────────────────────────────────────────────────
  static Future<void> saveScan(int userId, String crop, String disease, double confidence, String treatmentShown, String imagePath) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/history'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.get(Uri.parse('$_baseUrl/history/$userId')).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['history'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
"""

if "Future<Map<String, dynamic>> signup" not in text:
    text = text.replace("} // End of ApiService", "")
    text = text.replace("class ApiException implements Exception", api_service_additions + "\n}\n\nclass ApiException implements Exception")

with open("d:/cropcure_final/mobile/lib/services/api_service.dart", "w", encoding="utf-8") as f:
    f.write(text)
print("api_service updated.")
