import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/blog_model.dart';

/// Blog API service for the Farmer Community Blog module.
/// Uses XFile throughout — compatible with Flutter Web and native platforms.
class BlogApiService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    // Base URL defined by the user
    return 'http://10.208.116.48:8000';
  }

  static const Duration _timeout = Duration(seconds: 60);

  // ── Blogs ─────────────────────────────────────────────────────────────────

  /// Fetch all blogs, optionally filtered by crop name, sorted by rating.
  static Future<List<BlogPost>> getAllBlogs({
    String? cropFilter,
    int page = 1,
    int pageSize = 20,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/blogs/all').replace(queryParameters: {
        if (cropFilter != null && cropFilter.isNotEmpty) 'crop': cropFilter,
        'page': '$page',
        'page_size': '$pageSize',
        'lang': lang,
      });
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json.containsKey('blogs') && json['blogs'] is List) {
          final list = json['blogs'] as List<dynamic>;
          return list
              .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return <BlogPost>[];
    } catch (e) {
      print('Blog fetch error: $e');
      return <BlogPost>[];
    }
  }

  /// Search blogs by crop name.
  static Future<List<BlogPost>> searchBlogs(String cropName,
      {String lang = 'en'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/blogs/search')
          .replace(queryParameters: {'crop': cropName, 'lang': lang});
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json.containsKey('blogs') && json['blogs'] is List) {
          final list = json['blogs'] as List<dynamic>;
          return list
              .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return <BlogPost>[];
    } catch (e) {
      print('Blog search error: $e');
      return <BlogPost>[];
    }
  }

  /// Get single blog detail, translated to [lang].
  static Future<BlogPost?> getBlogById(int id, {String lang = 'en'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/blogs/$id')
          .replace(queryParameters: {'lang': lang});
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return BlogPost.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a new blog post with optional images and video.
  /// Accepts XFile — works on Flutter Web and native (Android/iOS).
  static Future<BlogPost?> createBlog({
    required String title,
    required String cropName,
    required String description,
    required String farmerName,
    List<XFile>? images,
    XFile? video,
  }) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/blogs/create'));

      request.fields['title'] = title;
      request.fields['crop_name'] = cropName;
      request.fields['description'] = description;
      request.fields['farmer_name'] = farmerName;

      // Upload images — read bytes from XFile (works on web + native)
      if (images != null) {
        for (final img in images) {
          final bytes = await img.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: img.name,
          ));
        }
      }

      // Upload video — read bytes from XFile
      if (video != null) {
        final bytes = await video.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: video.name,
        ));
      }

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return BlogPost.fromJson(json['blog'] as Map<String, dynamic>);
      } else {
        print('Blog create failed: ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Blog create exception: $e');
      throw Exception(e.toString());
    }
  }

  // ── Ratings ───────────────────────────────────────────────────────────────

  /// Submit a rating for a blog (1–5). Returns updated average and count.
  static Future<Map<String, dynamic>?> rateBlog({
    required int blogId,
    required String userIdentifier,
    required int rating,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/blogs/rate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'blog_id': blogId,
              'user_identifier': userIdentifier,
              'rating': rating,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get the current user's rating for a blog (0 if not rated).
  static Future<int> getMyRating({
    required int blogId,
    required String userIdentifier,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/blogs/$blogId/my-rating')
          .replace(queryParameters: {'user_identifier': userIdentifier});
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['rating'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  /// Submit a comment.
  static Future<bool> addComment({
    required int blogId,
    required String farmerName,
    required String comment,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/blogs/comment'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'blog_id': blogId,
              'farmer_name': farmerName,
              'comment': comment,
            }),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch comments for a blog.
  static Future<List<BlogComment>> getComments(int blogId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/blogs/$blogId/comments'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final list = json['comments'] as List<dynamic>;
        return list
            .map((e) => BlogComment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Media URLs ────────────────────────────────────────────────────────────

  /// Full URL for a blog image filename served by the backend.
  static String imageUrl(String filename) =>
      '$_baseUrl/media/blog_images/$filename';

  /// Full URL for a blog video filename served by the backend.
  static String videoUrl(String filename) =>
      '$_baseUrl/media/blog_videos/$filename';
}
