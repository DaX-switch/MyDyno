import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Uint8List _compress(String src) {
  var im = img.decodeImage(File(src).readAsBytesSync())!;
  im = img.bakeOrientation(im);
  if (max(im.width, im.height) > 1024) {
    im = im.width >= im.height
        ? img.copyResize(im, width: 1024)
        : img.copyResize(im, height: 1024);
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: 70));
}

class PhotoService {
  /// Prywatny katalog aplikacji + .nomedia (galeria/Google Photos nie indeksują).
  static Future<Directory> dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'photos'));
    if (!await d.exists()) await d.create(recursive: true);
    final nm = File(p.join(d.path, '.nomedia'));
    if (!await nm.exists()) await nm.create();
    return d;
  }

  static Future<String> pathFor(String fileName) async =>
      p.join((await dir()).path, fileName);

  /// Kompresuje zdjęcie (max 1024 px, JPG 70%) i zapisuje; zwraca nazwę pliku.
  static Future<String> saveCompressed(String srcPath) async {
    final bytes = await compute(_compress, srcPath);
    final name = '${const Uuid().v4()}.jpg';
    await File(await pathFor(name)).writeAsBytes(bytes);
    return name;
  }

  static Future<void> delete(String fileName) async {
    final f = File(await pathFor(fileName));
    if (await f.exists()) await f.delete();
  }

  static Future<String> duplicate(String fileName) async {
    final name = '${const Uuid().v4()}.jpg';
    await File(await pathFor(fileName)).copy(await pathFor(name));
    return name;
  }
}
