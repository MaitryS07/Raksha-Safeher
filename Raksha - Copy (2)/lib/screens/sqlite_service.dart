import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteService {
  static Database? _db;

  static Future<Database> _openDB() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "raksha_history.db");

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute("""
        CREATE TABLE incidents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT,
          note TEXT,
          latitude REAL,
          longitude REAL,
          created_at TEXT
        )
        """);
      },
    );

    return _db!;
  }

  /// SAVE INCIDENT
  static Future<void> logIncident({
    required String type,
    String note = "",
    double? lat,
    double? lng,
  }) async {
    final db = await _openDB();

    await db.insert(
      "incidents",
      {
        "type": type,
        "note": note,
        "latitude": lat,
        "longitude": lng,
        "created_at": DateTime.now().toIso8601String(),
      },
    );
  }

  /// FETCH ALL INCIDENTS
  static Future<List<Map<String, dynamic>>> fetchIncidents() async {
    final db = await _openDB();
    return await db.query(
      "incidents",
      orderBy: "id DESC",
    );
  }

  /// CLEAR HISTORY (if ever needed)
  static Future<void> clearHistory() async {
    final db = await _openDB();
    await db.delete("incidents");
  }
}
