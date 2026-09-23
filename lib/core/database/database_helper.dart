import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/downloaded_chapter_model.dart';

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

    return await openDatabase(path, version: 8, onCreate: _createDB, onUpgrade: _onUpgrade);
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
  updatedAt $textTypeNull,
  isPinned INTEGER DEFAULT 0,
  isHot INTEGER DEFAULT 0,
  isRecommended INTEGER DEFAULT 0
)
''');

    await db.execute('CREATE INDEX idx_bookmarks_link ON bookmarks (link)');

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
  updatedAt $textTypeNull,
  isPinned INTEGER DEFAULT 0,
  isHot INTEGER DEFAULT 0,
  isRecommended INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS downloaded_chapters (
  id TEXT PRIMARY KEY,
  comic_id TEXT NOT NULL,
  comic_title TEXT NOT NULL,
  comic_thumb_url TEXT,
  chapter_title TEXT NOT NULL,
  chapter_url TEXT NOT NULL,
  local_path TEXT NOT NULL,
  page_count INTEGER NOT NULL,
  size_bytes INTEGER DEFAULT 0,
  downloaded_at INTEGER NOT NULL
)
''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_downloaded_comic_id ON downloaded_chapters (comic_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_downloaded_chapter_url ON downloaded_chapters (chapter_url)');
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

    if (oldVersion < 4) {
      await db.execute('CREATE INDEX idx_bookmarks_link ON bookmarks (link)');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE bookmarks ADD COLUMN isPinned INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE history ADD COLUMN isPinned INTEGER DEFAULT 0');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE bookmarks ADD COLUMN isHot INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE bookmarks ADD COLUMN isRecommended INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE history ADD COLUMN isHot INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE history ADD COLUMN isRecommended INTEGER DEFAULT 0');
    }

    if (oldVersion < 7) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT
)
''');
    }

    if (oldVersion < 8) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS downloaded_chapters (
  id TEXT PRIMARY KEY,
  comic_id TEXT NOT NULL,
  comic_title TEXT NOT NULL,
  comic_thumb_url TEXT,
  chapter_title TEXT NOT NULL,
  chapter_url TEXT NOT NULL,
  local_path TEXT NOT NULL,
  page_count INTEGER NOT NULL,
  size_bytes INTEGER DEFAULT 0,
  downloaded_at INTEGER NOT NULL
)
''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_downloaded_comic_id ON downloaded_chapters (comic_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_downloaded_chapter_url ON downloaded_chapters (chapter_url)');
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
    return maps.map((map) {
      final m = Map<String, dynamic>.from(map);
      m.remove('updatedAt');
      return ComicModel.fromMap(m);
    }).toList();
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('history');
  }

  Future<void> removeHistory(String link) async {
    final db = await instance.database;
    await db.delete('history', where: 'link = ?', whereArgs: [link]);
  }

  Future<void> saveBookmark(ComicModel comic) async {
    final db = await instance.database;

    // Cek apakah komik ini sebelumnya sudah pernah disimpan dan memiliki status isPinned
    final existing = await db.query(
      'bookmarks',
      columns: ['isPinned'],
      where: 'link = ?',
      whereArgs: [comic.link],
      limit: 1,
    );

    int isPinned = comic.isPinned ? 1 : 0;
    if (existing.isNotEmpty && isPinned == 0) {
      isPinned = (existing.first['isPinned'] as int?) ?? 0;
    }

    // Hapus bookmark lama dengan url detail (link) yang sama agar diganti sepenuhnya
    await db.delete('bookmarks', where: 'link = ?', whereArgs: [comic.link]);

    final map = comic.toMap();
    map['isPinned'] = isPinned;
    map['updatedAt'] = DateTime.now().toIso8601String();
    await db.insert('bookmarks', map);
  }

  Future<List<ComicModel>> getBookmarks() async {
    final db = await instance.database;
    final maps = await db.query('bookmarks', orderBy: 'updatedAt DESC');

    final seenLinks = <String>{};
    final List<ComicModel> result = [];
    for (final map in maps) {
      final m = Map<String, dynamic>.from(map);
      m.remove('updatedAt');
      final comic = ComicModel.fromMap(m);
      if (seenLinks.add(comic.link)) {
        result.add(comic);
      }
    }
    return result;
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

  Future<bool> isBookmarkedReader(String link, String index) async {
    final db = await instance.database;
    final maps = await db.query(
      'bookmarks',
      columns: ['id'],
      where: 'link = ? AND latestChapter = ?',
      whereArgs: [link, index],
    );
    return maps.isNotEmpty;
  }

  // SETTINGS PERSISTENCE
  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // DOWNLOADED CHAPTERS
  Future<void> saveDownloadedChapter(DownloadedChapterModel chapter) async {
    final db = await instance.database;
    await db.insert(
      'downloaded_chapters',
      chapter.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DownloadedChapterModel>> getAllDownloadedChapters() async {
    final db = await instance.database;
    final maps = await db.query(
      'downloaded_chapters',
      orderBy: 'downloaded_at DESC',
    );
    return maps.map((m) => DownloadedChapterModel.fromMap(m)).toList();
  }

  Future<List<DownloadedChapterModel>> getDownloadedChaptersByComic(String comicId) async {
    final db = await instance.database;
    final maps = await db.query(
      'downloaded_chapters',
      where: 'comic_id = ?',
      whereArgs: [comicId],
      orderBy: 'downloaded_at DESC',
    );
    return maps.map((m) => DownloadedChapterModel.fromMap(m)).toList();
  }

  Future<DownloadedChapterModel?> getDownloadedChapterByUrl(String chapterUrl) async {
    final db = await instance.database;
    final maps = await db.query(
      'downloaded_chapters',
      where: 'chapter_url = ?',
      whereArgs: [chapterUrl],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DownloadedChapterModel.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> isChapterDownloaded(String chapterUrl) async {
    final db = await instance.database;
    final maps = await db.query(
      'downloaded_chapters',
      columns: ['id'],
      where: 'chapter_url = ?',
      whereArgs: [chapterUrl],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<void> deleteDownloadedChapter(String chapterUrl) async {
    final db = await instance.database;
    await db.delete(
      'downloaded_chapters',
      where: 'chapter_url = ?',
      whereArgs: [chapterUrl],
    );
  }

  Future<void> deleteDownloadedChaptersByComic(String comicId) async {
    final db = await instance.database;
    await db.delete(
      'downloaded_chapters',
      where: 'comic_id = ?',
      whereArgs: [comicId],
    );
  }

  Future<void> clearAllDownloadedChapters() async {
    final db = await instance.database;
    await db.delete('downloaded_chapters');
  }
}
