// lib/services/chat_storage_service.dart
import 'package:ehr/model/chat_message.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatStorageService {
  static Database? _database;
  static final ChatStorageService _instance = ChatStorageService._internal();

  factory ChatStorageService() => _instance;

  ChatStorageService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medical_chat.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chat_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            model_used TEXT,
            confidence REAL,
            attachment_path TEXT,
            attachment_type TEXT
          )
        ''');
        
        await db.execute('''
          CREATE INDEX idx_timestamp ON chat_messages(timestamp)
        ''');
        
        await db.execute('''
          CREATE INDEX idx_is_user ON chat_messages(is_user)
        ''');
      },
    );
  }

  Future<int> insertMessage(ChatMessage message) async {
    final db = await database;
    return await db.insert('chat_messages', message.toMap());
  }

  Future<List<ChatMessage>> getMessages({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) {
      return ChatMessage.fromMap(maps[i]);
    }).reversed.toList();
  }

  Future<int> deleteMessage(int id) async {
    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearChatHistory() async {
    final db = await database;
    return await db.delete('chat_messages');
  }

  Future<int> getMessageCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chat_messages')
    ) ?? 0;
  }

  Future<List<ChatMessage>> searchMessages(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'message LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );
    
    return List.generate(maps.length, (i) {
      return ChatMessage.fromMap(maps[i]);
    });
  }
}