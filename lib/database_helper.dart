import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'schedule_database.db');
    return openDatabase(
      path,
      version: 2, // 升級版本號
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE schedules(id INTEGER PRIMARY KEY, title TEXT, description TEXT, date TEXT, model INTEGER, userId INTEGER)',
        );
        await db.execute(
          'CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, chatTitle TEXT, content TEXT, timestamp TEXT, userId INTEGER)',
        );
      },
    );
  }

  // 插入行程
  Future<void> insertSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    await db.insert(
      'schedules',
      schedule,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 查詢行程
  Future<List<Map<String, dynamic>>> getSchedules(int userId, String date) async {
    final db = await database;
    return await db.query(
      'schedules',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, date],
    );
  }

  // 插入消息
  Future<void> insertMessage(String chatTitle, String content, int userId) async {
    final db = await database;
    await db.insert(
      'messages',
      {'chatTitle': chatTitle, 'content': content, 'timestamp': DateTime.now().toIso8601String(), 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 查詢消息
  Future<List<Map<String, dynamic>>> getMessages(String chatTitle) async {
    final db = await database;
    return await db.query('messages', where: 'chatTitle = ?', whereArgs: [chatTitle]);
  }
}
