import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static late SharedPreferences _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();

  static bool get showDyno => _p.getBool('show_dyno') ?? true;
  static bool get roadDyno => _p.getBool('road_dyno') ?? true;
  static bool get slaveMode => _p.getBool('slave_mode') ?? false;

  static Future<void> setShowDyno(bool v) => _p.setBool('show_dyno', v);
  static Future<void> setRoadDyno(bool v) => _p.setBool('road_dyno', v);
  static Future<void> setSlaveMode(bool v) => _p.setBool('slave_mode', v);
}
