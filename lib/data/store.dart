import 'package:hive_flutter/hive_flutter.dart';

/// Local storage (works offline). The whole app state is saved as one JSON string.
class Store {
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('equishare');
  }

  static String? read() => _box.get('state') as String?;
  static Future<void> write(String json) => _box.put('state', json);
}
