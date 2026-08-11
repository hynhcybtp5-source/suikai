import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FxSnapshot {
  final Map<String, double> rates;
  final DateTime updatedAt;
  const FxSnapshot(this.rates, this.updatedAt);
}

class FxService {
  static const _url = 'https://open.er-api.com/v6/latest/THB';
  static const _ratesKey = 'fx_thb_rates_v1';
  static const _updatedKey = 'fx_updated_at_v1';
  static const _ttl = Duration(hours: 12);

  Future<FxSnapshot> latest({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = _readCache(prefs);
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.updatedAt) < _ttl)
      return cached;
    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw Exception('FX unavailable');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = json['rates'] as Map<String, dynamic>;
      final rates = raw.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
      final updatedAt = DateTime.now().toUtc();
      await prefs.setString(_ratesKey, jsonEncode(rates));
      await prefs.setString(_updatedKey, updatedAt.toIso8601String());
      return FxSnapshot(rates, updatedAt);
    } catch (_) {
      return cached ??
          FxSnapshot(const {
            'THB': 1,
          }, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    }
  }

  FxSnapshot? _readCache(SharedPreferences prefs) {
    final ratesJson = prefs.getString(_ratesKey);
    final updated = DateTime.tryParse(prefs.getString(_updatedKey) ?? '');
    if (ratesJson == null || updated == null) return null;
    final raw = jsonDecode(ratesJson) as Map<String, dynamic>;
    return FxSnapshot(
      raw.map((key, value) => MapEntry(key, (value as num).toDouble())),
      updated,
    );
  }

  double convert(double amount, String from, String to, FxSnapshot snapshot) {
    final fromRate = snapshot.rates[from];
    final toRate = snapshot.rates[to];
    if (fromRate == null || toRate == null || fromRate == 0) return amount;
    return amount / fromRate * toRate;
  }
}
