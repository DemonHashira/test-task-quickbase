import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Database get database {
    if (_database != null) return _database!;
    _database = _initDatabase();
    return _database!;
  }

  Database _initDatabase() {
    var databasesPath = Directory.current.path;
    String path = '$databasesPath/github_users.db';
    bool exists = File(path).existsSync();
    var database = sqlite3.open(path);
    if (!exists) {
      database.execute(
        'CREATE TABLE users(id INTEGER PRIMARY KEY, login TEXT, name TEXT, created_at TEXT)',
      );
    }
    return database;
  }

  void insertUser(Map<String, dynamic> user) {
    var result = database.select(
      'SELECT * FROM users WHERE login = ?',
      [user['login']],
    );

    if (result.isNotEmpty) {
      database.execute(
        'UPDATE users SET name = ?, created_at = ? WHERE login = ?',
        [user['name'], user['created_at'], user['login']],
      );
    } else {
      database.execute(
        'INSERT INTO users(id, login, name, created_at) VALUES (?, ?, ?, ?)',
        [user['id'], user['login'], user['name'], user['created_at']],
      );
    }
  }

  List<Map<String, dynamic>> getUsers() {
    var result = database.select('SELECT * FROM users');
    return result
        .map((row) => {
              'id': row['id'],
              'login': row['login'],
              'name': row['name'],
              'created_at': row['created_at'],
            })
        .toList();
  }
}
