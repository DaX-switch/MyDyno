import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../constants.dart';

class AppDb {
  static Database? _db;

  static Future<String> path() async =>
      p.join(await getDatabasesPath(), 'mydyno.db');

  static Future<Database> get() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      await path(),
      password: kDbPassword,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
        await db.execute('''CREATE TABLE vehicles(
          id TEXT PRIMARY KEY, brand TEXT NOT NULL, model TEXT NOT NULL,
          year TEXT, engine_code TEXT, stock_power TEXT, ecu_family TEXT,
          data TEXT NOT NULL DEFAULT '{}',
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE photos(
          id TEXT PRIMARY KEY, vehicle_id TEXT NOT NULL, tab TEXT NOT NULL,
          file_name TEXT NOT NULL, updated_at TEXT NOT NULL,
          FOREIGN KEY(vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE)''');
      },
    );
    return _db!;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Zamyka bazę, kopiuje plik do [dest] i otwiera ponownie (spójna kopia).
  static Future<void> snapshot(String dest) async {
    await close();
    await File(await path()).copy(dest);
    await get();
  }
}
