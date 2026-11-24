import 'dart:convert';
import 'package:flutter/services.dart';

/// Provides translated treatment content for Hindi ('hi') and Marathi ('mr').
///
/// Usage:
///   1. Call [load] once when the language is set (AppProvider handles this).
///   2. Call [get] anywhere to retrieve the translated text for a given
///      disease label and field name.  Falls back to English if not found.
///
/// No architecture changes are required — works alongside the existing
/// Localized.tr() system for UI strings.
class TreatmentLocalization {
  // In-memory cache: langCode -> { label -> { field -> translated_text } }
  static final Map<String, Map<String, dynamic>> _cache = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Pre-loads translated treatment JSON for [lang] ('hi' or 'mr').
  /// Safe to call multiple times; loads only once per language.
  /// English has no separate file — falls through to the English fallback.
  static Future<void> load(String lang) async {
    if (lang == 'en') return; // English is always the fallback from JSON
    if (_cache.containsKey(lang)) return; // already loaded
    try {
      final raw = await rootBundle.loadString(
        'assets/model/treatment_data_$lang.json',
      );
      _cache[lang] = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // File missing or parse error — silently fall back to English
      _cache[lang] = {};
    }
  }

  /// Returns the translated value for [label] + [field] in [lang].
  /// Example: get('hi', 'Wheat_Brown_rust', 'symptoms', englishFallback)
  ///
  /// [label]    — disease key, e.g. 'Tomato_Early_blight'
  /// [field]    — JSON field name: 'symptoms' | 'treatment' | 'prevention' |
  ///              'advice' | 'immediate_action' | 'chemical_treatment' |
  ///              'organic_alternative' | 'farmer_tips'
  /// [fallback] — English text already stored in TreatmentInfo (used when
  ///              translation is unavailable).
  static String get(
    String lang,
    String label,
    String field,
    String fallback,
  ) {
    if (lang == 'en' || label.isEmpty) return fallback;
    final langData = _cache[lang];
    if (langData == null) return fallback; // load() not called yet
    final entry = langData[label] as Map<String, dynamic>?;
    if (entry == null) return fallback;
    return (entry[field] as String?) ?? fallback;
  }
}
