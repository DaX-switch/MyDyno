import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../services/photo_service.dart';
import 'app_db.dart';

class Repo {
  static const _u = Uuid();
  static String newId() => _u.v4();

  static Future<List<Vehicle>> all() async {
    final db = await AppDb.get();
    final r = await db.query('vehicles', orderBy: 'updated_at DESC');
    return r.map(Vehicle.fromRow).toList();
  }

  static Future<Vehicle?> get(String id) async {
    final db = await AppDb.get();
    final r = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Vehicle.fromRow(r.first);
  }

  /// Zapis z automatyczną aktualizacją updated_at (bez INSERT OR REPLACE – cascade!).
  static Future<void> save(Vehicle v) async {
    final db = await AppDb.get();
    v.updatedAt = DateTime.now();
    final n = await db
        .update('vehicles', v.toRow(), where: 'id = ?', whereArgs: [v.id]);
    if (n == 0) await db.insert('vehicles', v.toRow());
  }

  static Future<void> touch(String id) async {
    final db = await AppDb.get();
    await db.update('vehicles', {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<PhotoRec>> photos(String vehicleId, [String? tab]) async {
    final db = await AppDb.get();
    final r = await db.query('photos',
        where: tab == null ? 'vehicle_id = ?' : 'vehicle_id = ? AND tab = ?',
        whereArgs: tab == null ? [vehicleId] : [vehicleId, tab],
        orderBy: 'updated_at');
    return r.map(PhotoRec.fromRow).toList();
  }

  static Future<void> addPhoto(String vehicleId, String tab, String file) async {
    final db = await AppDb.get();
    await db.insert('photos', {
      'id': newId(),
      'vehicle_id': vehicleId,
      'tab': tab,
      'file_name': file,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await touch(vehicleId);
  }

  static Future<void> removePhoto(PhotoRec ph) async {
    final db = await AppDb.get();
    await PhotoService.delete(ph.fileName);
    await db.delete('photos', where: 'id = ?', whereArgs: [ph.id]);
    await touch(ph.vehicleId);
  }

  static Future<void> delete(String id) async {
    for (final ph in await photos(id)) {
      await PhotoService.delete(ph.fileName);
    }
    final db = await AppDb.get();
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clone(String id) async {
    final v = await Repo.get(id);
    if (v == null) return;
    final c = Vehicle(
      id: newId(),
      brand: v.brand,
      model: '${v.model} (kopia)',
      year: v.year,
      engineCode: v.engineCode,
      stockPower: v.stockPower,
      ecuFamily: v.ecuFamily,
      data: Vehicle.copyData(v.data),
    );
    await save(c);
    for (final ph in await photos(id)) {
      await addPhoto(c.id, ph.tab, await PhotoService.duplicate(ph.fileName));
    }
  }

  static Future<List<String>> distinct(String column) async {
    final db = await AppDb.get();
    final r = await db.rawQuery(
        "SELECT DISTINCT $column AS v FROM vehicles WHERE $column <> '' ORDER BY $column");
    return r.map((e) => e['v'] as String).toList();
  }
}
