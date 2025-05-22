// lib/core/database/database_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:notes_app/features/notes/data/models/note_model.dart';
import 'package:notes_app/features/notes/data/models/category_model.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  static Database? _database;
  static bool _isInitialized = false;

  DatabaseHelper._internal();

  // Initialize the database factory
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (kIsWeb) {
        print(
          'Web platform detected, skipping database factory initialization',
        );
        _isInitialized = true;
        return;
      }
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Initialize FFI
        sqfliteFfiInit();
        // Change the default factory to use FFI
        databaseFactory = databaseFactoryFfi;
        print('Database factory initialized for desktop platform');
      } else {
        print('Using default database factory for mobile platform');
      }
      _isInitialized = true;
    } catch (e) {
      print('Error initializing database factory: $e');
      // For mobile platforms, this might not be necessary
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _isInitialized = true;
        print('Continuing with default factory for mobile');
      } else {
        rethrow;
      }
    }
  }

  Future<Database> get database async {
    // Ensure initialization before accessing database
    await initialize();
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      if (kIsWeb) throw UnsupportedError('Database not supported on web');
      // Get the proper database path
      String databasesPath;
      try {
        databasesPath = await getDatabasesPath();
      } catch (e) {
        // Fallback path for desktop platforms
        print('getDatabasesPath failed: $e, using fallback');
        if (!kIsWeb && Platform.isWindows) {
          databasesPath = join(
            Platform.environment['USERPROFILE']!,
            'Documents',
          );
        } else if (!kIsWeb && (Platform.isLinux || Platform.isMacOS)) {
          databasesPath = join(Platform.environment['HOME']!, 'Documents');
        } else {
          rethrow;
        }
      }

      final path = join(databasesPath, 'luxe_notes.db');
      print('Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Handle database upgrades if needed in the future
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      print('Creating database tables...');

      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          color INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      print('Categories table created');

      // Create notes table
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          is_pinned INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');
      print('Notes table created');

      // Insert default categories
      await _insertDefaultCategories(db);

      print('Database tables created successfully');
    } catch (e) {
      print('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {
        'name': 'Personal',
        'color': 0xFF6366F1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Work',
        'color': 0xFFF59E0B,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Ideas',
        'color': 0xFF10B981,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Tasks',
        'color': 0xFFEF4444,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final category in defaultCategories) {
      try {
        await db.insert('categories', category);
        print('Inserted default category: ${category['name']}');
      } catch (e) {
        // Category might already exist
        print('Category ${category['name']} already exists or error: $e');
      }
    }
  }

  // Enhanced test connection method with better error handling
  Future<bool> testConnection() async {
    try {
      print('Testing database connection...');

      final db = await database;
      print('Database instance obtained');

      // Test basic query
      await db.rawQuery('SELECT 1');
      print('Basic query test passed');

      // Test if tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('categories', 'notes')",
      );

      print(
        'Found ${tables.length} tables: ${tables.map((t) => t['name']).join(', ')}',
      );

      if (tables.length < 2) {
        print('Database tables missing. Expected 2, found ${tables.length}');
        return false;
      }

      // Test if we can query the tables
      final categoriesCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM categories',
      );
      final notesCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notes',
      );

      print('Categories count: ${categoriesCount.first['count']}');
      print('Notes count: ${notesCount.first['count']}');

      print('Database connection test passed');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  // Method to reset database (useful for debugging)
  Future<void> resetDatabase() async {
    try {
      print('Resetting database...');

      // Close existing connection
      if (_database != null) {
        await _database!.close();
        _database = null;
        print('Existing database connection closed');
      }
      if (kIsWeb) throw UnsupportedError('Database reset not supported on web');
      // Get database path
      String databasesPath;
      try {
        databasesPath = await getDatabasesPath();
      } catch (e) {
        // Fallback path for desktop platforms
        if (!kIsWeb && Platform.isWindows) {
          databasesPath = join(
            Platform.environment['USERPROFILE']!,
            'Documents',
          );
        } else if (!kIsWeb && (Platform.isLinux || Platform.isMacOS)) {
          databasesPath = join(Platform.environment['HOME']!, 'Documents');
        } else {
          rethrow;
        }
      }

      final path = join(databasesPath, 'luxe_notes.db');
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('Database file deleted');
      }
      // Reinitialize
      _database = await _initDatabase();
      print('Database reset completed');
    } catch (e) {
      print('Error resetting database: $e');
      rethrow;
    }
  }

  // All your existing methods remain the same...
  Future<List<CategoryModel>> getCategories() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'name ASC',
      );
      return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NoteModel>> getNotes({
    int? categoryId,
    String? searchQuery,
  }) async {
    try {
      final db = await database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (categoryId != null) {
        whereClause = 'category_id = ?';
        whereArgs.add(categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (whereClause.isNotEmpty) {
          whereClause += ' AND ';
        }
        whereClause += '(title LIKE ? OR content LIKE ?)';
        whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'is_pinned DESC, updated_at DESC',
      );

      return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  Future<int> insertNote(NoteModel note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<void> updateNote(NoteModel note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> togglePinNote(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE notes SET is_pinned = CASE WHEN is_pinned = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [id],
    );
  }

  Future<NoteModel> duplicateNote(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) throw Exception('Note not found');

    final originalNote = NoteModel.fromMap(maps.first);
    final duplicatedNote = NoteModel(
      title: '${originalNote.title} (Copy)',
      content: originalNote.content,
      categoryId: originalNote.categoryId,
      isPinned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final newId = await insertNote(duplicatedNote);
    return duplicatedNote.copyWith(id: newId);
  }

  // Clean up method
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
