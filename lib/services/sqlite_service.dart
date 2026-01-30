import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteService {
  static Database? db;

  static Future init() async {
    final path = join(await getDatabasesPath(), "raksha_incidents.db");

    db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        await db.execute("""
          CREATE TABLE incidents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT,
            time TEXT,
            emergency INTEGER DEFAULT 0,
            location TEXT
          )
        """);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 🔹 Add new columns for existing users (no data loss)
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE incidents ADD COLUMN emergency INTEGER DEFAULT 0");
          await db.execute(
              "ALTER TABLE incidents ADD COLUMN location TEXT");
        }
      },
    );
  }

  /// 🟢 Save an incident (works for SOS & normal reports)
  static Future logIncident(
    String message, {
    bool emergency = false,
    String? location,
  }) async {
    await db?.insert("incidents", {
      "message": message,
      "time": DateTime.now().toIso8601String(),
      "emergency": emergency ? 1 : 0,
      "location": location,
    });
  }

  /// 🟡 Get all incidents (latest first)
  static Future<List<Map<String, dynamic>>> getIncidents() async {
    return await db?.query(
          "incidents",
          orderBy: "id DESC",
        ) ??
        [];
  }

  /// 🔴 Optional: clear history
  static Future clearAll() async {
    await db?.delete("incidents");
  }
}
