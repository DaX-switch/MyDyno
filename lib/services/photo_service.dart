import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class _CompressParams {
  final String src;
  final bool isHighQuality;
  _CompressParams(this.src, this.isHighQuality);
}

Uint8List _compressJob(_CompressParams params) {
  var im = img.decodeImage(File(params.src).readAsBytesSync())!;
  im = img.bakeOrientation(im);

  final maxDim = params.isHighQuality ? 2560 : 1280;
  final quality = params.isHighQuality ? 92 : 75;

  if (max(im.width, im.height) > maxDim) {
    im = im.width >= im.height
        ? img.copyResize(im, width: maxDim)
        : img.copyResize(im, height: maxDim);
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: quality));
}

class PhotoService {
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

  static Future<String> saveCompressed(String srcPath, {String? tab}) async {
    final highQualityTabs = ['moc', 'dyno', 'power', 'hamownia'];
    final isHighQuality = tab != null && highQualityTabs.any((k) => tab.toLowerCase().contains(k));

    final bytes = await compute(_compressJob, _CompressParams(srcPath, isHighQuality));
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
