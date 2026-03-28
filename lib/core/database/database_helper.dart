import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/comic_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bookmark.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';

    await db.execute('''
CREATE TABLE bookmarks (
  id $idType,
  title $textType,
  thumbUrl $textType,
  link $textType,
  latestChapter $textTypeNull,
  chapterLink $textTypeNull,
  type $textTypeNull,
  status $textTypeNull,
  format $textTypeNull,
  updatedAt $textTypeNull
)
''');

    await db.execute('''
CREATE TABLE history (
  id $idType,
  title $textType,
  thumbUrl $textType,
  link $textType UNIQUE,
  latestChapter $textTypeNull,
  chapterLink $textTypeNull,
  type $textTypeNull,
  status $textTypeNull,
  format $textTypeNull,
  updatedAt $textTypeNull
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';

    if (oldVersion < 2) {
      await db.execute('ALTER TABLE bookmarks ADD COLUMN chapterLink TEXT');
      await db.execute('ALTER TABLE bookmarks ADD COLUMN type TEXT');
      await db.execute('ALTER TABLE bookmarks ADD COLUMN status TEXT');
      await db.execute('ALTER TABLE bookmarks ADD COLUMN format TEXT');
    }
    
    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE history (
  id $idType,
  title $textType,
  thumbUrl $textType,
  link $textType UNIQUE,
  latestChapter $textTypeNull,
  chapterLink $textTypeNull,
  type $textTypeNull,
  status $textTypeNull,
  format $textTypeNull,
  updatedAt $textTypeNull
)
''');
    }
  }

  Future<void> saveHistory(ComicModel comic) async {
    final db = await instance.database;
    final map = comic.toMap();
    map['updatedAt'] = DateTime.now().toIso8601String();
    await db.insert(
      'history', 
      map, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<List<ComicModel>> getHistory() async {
    final db = await instance.database;
    final maps = await db.query('history', orderBy: 'updatedAt DESC');
    return maps.map((map) => ComicModel.fromMap(map)).toList();
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('history');
  }

  Future<void> saveBookmark(ComicModel comic) async {
    final db = await instance.database;
    final map = comic.toMap();
    map['updatedAt'] = DateTime.now().toIso8601String();
    await db.insert(
        'bookmarks',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<List<ComicModel>> getBookmarks() async {
    final db = await instance.database;
    final maps = await db.query('bookmarks', orderBy: 'updatedAt DESC');

    return maps.map((map) => ComicModel.fromMap(map)).toList();
  }

  Future<void> removeBookmark(String link) async {
    final db = await instance.database;
    await db.delete('bookmarks', where: 'link = ?', whereArgs: [link]);
  }

  Future<void> clearBookmarks() async {
    final db = await instance.database;
    await db.delete('bookmarks');
  }

  Future<bool> isBookmarked(String link) async {
    final db = await instance.database;
    final maps = await db.query(
      'bookmarks',
      where: 'link = ?',
      whereArgs: [link],
    );
    return maps.isNotEmpty;
  }

  Future<bool> isBookmarkedReader(String index) async {
    final db = await instance.database;
    final maps = await db.query(
      'bookmarks',
      where: 'latestChapter = ?',
      whereArgs: [index],
    );
    return maps.isNotEmpty;
  }
}
