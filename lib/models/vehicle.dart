import 'dart:convert';

const priceKeys = ['price_last', 'price_history', 'master_cost'];

class Vehicle {
  String id, brand, model, year, engineCode, stockPower, ecuFamily;
  Map<String, dynamic> data;
  DateTime createdAt, updatedAt;

  Vehicle({
    required this.id,
    this.brand = '',
    this.model = '',
    this.year = '',
    this.engineCode = '',
    this.stockPower = '',
    this.ecuFamily = '',
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : data = data ?? <String, dynamic>{},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Vehicle.fromRow(Map<String, Object?> r) => Vehicle(
        id: r['id'] as String,
        brand: (r['brand'] ?? '') as String,
        model: (r['model'] ?? '') as String,
        year: (r['year'] ?? '') as String,
        engineCode: (r['engine_code'] ?? '') as String,
        stockPower: (r['stock_power'] ?? '') as String,
        ecuFamily: (r['ecu_family'] ?? '') as String,
        data: Map<String, dynamic>.from(
            jsonDecode((r['data'] ?? '{}') as String) as Map),
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'engine_code': engineCode,
        'stock_power': stockPower,
        'ecu_family': ecuFamily,
        'data': jsonEncode(data),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> tab(String key) {
    final t = data[key];
    if (t is Map<String, dynamic>) return t;
    final n = <String, dynamic>{};
    data[key] = n;
    return n;
  }

  /// Głęboka kopia danych zakładek, opcjonalnie bez cen.
  static Map<String, dynamic> copyData(Map<String, dynamic> d,
      {bool stripPrices = false}) {
    final c = jsonDecode(jsonEncode(d)) as Map<String, dynamic>;
    if (stripPrices) {
      for (final t in c.values) {
        if (t is Map) {
          for (final k in priceKeys) {
            t.remove(k);
          }
        }
      }
    }
    return c;
  }
}

class PhotoRec {
  final String id, vehicleId, tab, fileName;
  PhotoRec(this.id, this.vehicleId, this.tab, this.fileName);
  factory PhotoRec.fromRow(Map<String, Object?> r) => PhotoRec(
      r['id'] as String,
      r['vehicle_id'] as String,
      r['tab'] as String,
      r['file_name'] as String);
}
