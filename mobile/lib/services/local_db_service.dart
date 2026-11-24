import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Fully offline SQLite-backed service.
/// Replaces the Python backend for:
///   • User auth   (users table)
///   • Scan history (scan_history table)
///
/// No network calls. Works on Android/iOS/desktop.
class LocalDbService {
  static Database? _db;

  // ── Open / create DB ───────────────────────────────────────────────────────

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path   = '$dbPath/cropcure.db';

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            name     TEXT    NOT NULL,
            email    TEXT    NOT NULL UNIQUE,
            password TEXT    NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE scan_history (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id         INTEGER NOT NULL,
            crop            TEXT,
            disease         TEXT,
            confidence      REAL,
            treatment_shown TEXT,
            image_path      TEXT,
            scan_date       TEXT DEFAULT (datetime('now'))
          )
        ''');
      },
    );
  }

  // ── Password hashing (SHA-256) ─────────────────────────────────────────────

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// Create a new user. Returns user map on success, throws on duplicate email.
  static Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {
    final database = await db;

    // Check for duplicate email
    final existing = await database.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
    );
    if (existing.isNotEmpty) {
      throw Exception('An account with this email already exists.');
    }

    final id = await database.insert('users', {
      'name':     name,
      'email':    email,
      'password': _hash(password),
    });

    return {'id': id, 'name': name, 'email': email};
  }

  /// Verify credentials. Returns user map on success, null on failure.
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final database = await db;

    final rows = await database.query(
      'users',
      where: 'LOWER(email) = LOWER(?) AND password = ?',
      whereArgs: [email, _hash(password)],
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    return {
      'id':    row['id'],
      'name':  row['name'],
      'email': row['email'],
    };
  }

  // ── Scan History ───────────────────────────────────────────────────────────

  /// Save a scan result for [userId].
  static Future<void> saveScan({
    required int    userId,
    required String crop,
    required String disease,
    required double confidence,
    required String treatmentShown,
    required String imagePath,
  }) async {
    final database = await db;
    await database.insert('scan_history', {
      'user_id':         userId,
      'crop':            crop,
      'disease':         disease,
      'confidence':      confidence,
      'treatment_shown': treatmentShown,
      'image_path':      imagePath,
      // scan_date filled by SQLite DEFAULT
    });
  }

  /// Fetch all scans for [userId], most recent first.
  static Future<List<Map<String, dynamic>>> getHistory(int userId) async {
    final database = await db;
    return database.query(
      'scan_history',
      where:   'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }
}
