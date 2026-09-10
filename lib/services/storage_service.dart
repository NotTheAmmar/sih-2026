import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/catalog_item.dart';

class StorageService {
  static const String _catalogsKey = 'kalakriti_catalogs';

  Future<List<CatalogItem>> loadCatalogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_catalogsKey) ?? [];
    return raw
        .map((s) => CatalogItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCatalog(CatalogItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_catalogsKey) ?? [];

    // Replace existing or add new
    final index = raw.indexWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == item.id;
    });

    final encoded = jsonEncode(item.toJson());
    if (index >= 0) {
      raw[index] = encoded;
    } else {
      raw.add(encoded);
    }

    await prefs.setStringList(_catalogsKey, raw);
  }

  Future<void> deleteCatalog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_catalogsKey) ?? [];
    raw.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == id;
    });
    await prefs.setStringList(_catalogsKey, raw);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_catalogsKey);
  }
}
