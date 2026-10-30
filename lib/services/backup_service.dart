import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../constants.dart';
import '../db/app_db.dart';
import '../db/repo.dart';
import '../models/vehicle.dart';
import 'photo_service.dart';

class BackupService {
  static Future<Directory> _tmp() async {
    final d = Directory(p.join((await getTemporaryDirectory()).path, 'mydyno_tmp'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<String> _backupsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'backups'));
    if (!await d.exists()) await d.create(recursive: true);
    return d.path;
  }

  static String _stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  static Future<File> _writeZip(Archive a, String name) async {
    final out = File(p.join((await _tmp()).path, name));
    await out.writeAsBytes(ZipEncoder().encode(a)!);
    return out;
  }

  // ---------- EKSPORT PEŁNY ----------
  static Future<void> exportFull() async {
    final snap = p.join((await _tmp()).path, 'snapshot.db');
    await AppDb.snapshot(snap);
    final a = Archive();
    final dbBytes = await File(snap).readAsBytes();
    a.addFile(ArchiveFile('mydyno.db', dbBytes.length, dbBytes));
    final dir = await PhotoService.dir();
    await for (final e in dir.list()) {
      if (e is File && p.basename(e.path) != '.nomedia') {
        final b = await e.readAsBytes();
        a.addFile(ArchiveFile('photos/${p.basename(e.path)}', b.length, b));
      }
    }
    await File(snap).delete();
    final f = await _writeZip(a, 'mydyno_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.zip');
    await Share.shareXFiles([XFile(f.path)], text: 'My Dyno – backup');
  }

  // ---------- EKSPORT POJEDYNCZEGO MODELU (.mydyno) ----------
  static Future<void> exportVehicle(Vehicle v, {required bool stripPrices}) async {
    final row = Map<String, Object?>.from(v.toRow());
    row['data'] = jsonEncode(Vehicle.copyData(v.data, stripPrices: stripPrices));
    final photos = await Repo.photos(v.id);
    final a = Archive();
    final meta = utf8.encode(jsonEncode({
      'format': 'mydyno-vehicle',
      'version': 1,
      'vehicle': row,
      'photos': [
        for (final ph in photos) {'tab': ph.tab, 'file_name': ph.fileName}
      ],
    }));
    a.addFile(ArchiveFile('vehicle.json', meta.length, meta));
    for (final ph in photos) {
      final f = File(await PhotoService.pathFor(ph.fileName));
      if (await f.exists()) {
        final b = await f.readAsBytes();
        a.addFile(ArchiveFile('photos/${ph.fileName}', b.length, b));
      }
    }
    final safe = '${v.brand}_${v.model}'.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final f = await _writeZip(a, '$safe.mydyno');
    await Share.shareXFiles([XFile(f.path)], text: 'My Dyno – ${v.brand} ${v.model}');
  }

  // ---------- PRZYWRACANIE PEŁNE (ZASTĄP) ----------
  static Future<void> restoreFull(String zipPath) async {
    final arc = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
    final dbFile = arc.files.where((f) => f.isFile && f.name == 'mydyno.db');
    if (dbFile.isEmpty) throw 'To nie jest pełny backup My Dyno (brak mydyno.db).';
    final tmpDb = p.join((await _tmp()).path, 'incoming.db');
    await File(tmpDb).writeAsBytes(dbFile.first.content as List<int>);
    // walidacja: czy otwiera się hasłem i ma właściwe tabele
    try {
      final chk = await openDatabase(tmpDb, password: kDbPassword, readOnly: true);
      await chk.query('vehicles', limit: 1);
      await chk.query('photos', limit: 1);
      await chk.close();
    } catch (_) {
      throw 'Plik bazy jest uszkodzony lub zaszyfrowany innym hasłem.';
    }
    await AppDb.snapshot(p.join(await _backupsDir(), 'pre_restore_${_stamp()}.db'));
    await AppDb.close();
    final dest = await AppDb.path();
    for (final s in ['', '-journal', '-wal', '-shm']) {
      final f = File('$dest$s');
      if (await f.exists()) await f.delete();
    }
    await File(tmpDb).copy(dest);
    final dir = await PhotoService.dir();
    await for (final e in dir.list()) {
      if (e is File && p.basename(e.path) != '.nomedia') await e.delete();
    }
    for (final f in arc.files) {
      if (f.isFile && f.name.startsWith('photos/')) {
        await File(p.join(dir.path, p.basename(f.name)))
            .writeAsBytes(f.content as List<int>);
      }
    }
    await AppDb.get();
  }

  // ---------- BEZPIECZNE SCALANIE (MERGE) ----------
  /// Zwraca liczbę zaimportowanych modeli.
  static Future<int> merge(String path) async {
    final arc = ZipDecoder().decodeBytes(await File(path).readAsBytes());
    final photoBytes = <String, List<int>>{
      for (final f in arc.files)
        if (f.isFile && f.name.startsWith('photos/'))
          p.basename(f.name): f.content as List<int>
    };
    final vehicles = <Map<String, Object?>>[];
    final photoRows = <Map<String, Object?>>[]; // z kluczem vehicle_id = stare id

    final vj = arc.files.where((f) => f.isFile && f.name == 'vehicle.json');
    final dj = arc.files.where((f) => f.isFile && f.name == 'mydyno.db');
    if (vj.isNotEmpty) {
      final j = jsonDecode(utf8.decode(vj.first.content as List<int>));
      if (j['format'] != 'mydyno-vehicle') throw 'Nieznany format pliku.';
      final v = Map<String, Object?>.from(j['vehicle'] as Map);
      vehicles.add(v);
      for (final ph in (j['photos'] as List)) {
        photoRows.add({
          'vehicle_id': v['id'],
          'tab': ph['tab'],
          'file_name': p.basename(ph['file_name'] as String),
        });
      }
    } else if (dj.isNotEmpty) {
      final tmpDb = p.join((await _tmp()).path, 'merge_src.db');
      await File(tmpDb).writeAsBytes(dj.first.content as List<int>);
      try {
        final src = await openDatabase(tmpDb, password: kDbPassword, readOnly: true);
        vehicles.addAll((await src.query('vehicles')).map(Map<String, Object?>.from));
        photoRows.addAll((await src.query('photos')).map(Map<String, Object?>.from));
        await src.close();
      } catch (_) {
        throw 'Nie można odczytać bazy z pliku (uszkodzona lub inne hasło).';
      } finally {
        await File(tmpDb).delete();
      }
    } else {
      throw 'Nieobsługiwany plik – oczekiwano ZIP z mydyno.db lub paczki .mydyno.';
    }

    // kopia pre-merge w tle
    await AppDb.snapshot(p.join(await _backupsDir(), 'pre_merge_${_stamp()}.db'));

    final dir = await PhotoService.dir();
    final written = <File>[];
    try {
      final db = await AppDb.get();
      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        for (final old in vehicles) {
          final newId = Repo.newId();
          final row = Map<String, Object?>.from(old)
            ..['id'] = newId
            ..['model'] = '${old['model'] ?? ''} [Import]'
            ..['created_at'] = now
            ..['updated_at'] = now;
          await txn.insert('vehicles', row);
          for (final ph in photoRows.where((x) => x['vehicle_id'] == old['id'])) {
            final bytes = photoBytes[ph['file_name']];
            if (bytes == null) continue;
            final name = '${Repo.newId()}.jpg';
            final f = File(p.join(dir.path, name));
            await f.writeAsBytes(bytes);
            written.add(f);
            await txn.insert('photos', {
              'id': Repo.newId(),
              'vehicle_id': newId,
              'tab': ph['tab'],
              'file_name': name,
              'updated_at': now,
            });
          }
        }
      });
    } catch (e) {
      for (final f in written) {
        if (await f.exists()) await f.delete();
      }
      rethrow; // transakcja wycofana – baza bez zmian
    }
    return vehicles.length;
  }
}
