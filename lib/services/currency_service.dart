import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'db_helper.dart';

class RatesResult {
  final Map<String, double> perIdr; // nilai 1 IDR dalam mata uang lain
  final bool live;
  const RatesResult(this.perIdr, this.live);
}

/// Kurs dari Frankfurter (gratis, tanpa API key).
class CurrencyService {
  static const symbols = ['USD', 'EUR', 'JPY', 'SGD'];

  static Map<String, double> _parse(String body) => (jsonDecode(body)['rates'] as Map)
      .map((k, v) => MapEntry(k as String, (v as num).toDouble()));

  static Future<RatesResult> fetchRates() async {
    try {
      final uri = Uri.parse(
          'https://api.frankfurter.dev/v1/latest?base=IDR&symbols=${symbols.join(',')}');
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final rates = _parse(r.body);
      if (rates.isEmpty) throw Exception('kosong');
      await DbHelper.instance.putCache('rates', r.body); // simpan untuk mode offline
      return RatesResult(rates, true);
    } catch (_) {
      final saved = await DbHelper.instance.getCache('rates');
      if (saved != null) {
        try {
          return RatesResult(_parse(saved), false);
        } catch (_) {}
      }
      return const RatesResult(MockData.rates, false);
    }
  }
}
