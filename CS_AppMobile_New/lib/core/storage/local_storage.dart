import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper su SharedPreferences che replica l'uso di `localStorage`
/// dell'app Cordova (chiavi stringa, valori JSON).
class LocalStorage {
  LocalStorage._(this._prefs);

  final SharedPreferences _prefs;

  static LocalStorage? _instance;
  static LocalStorage get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('LocalStorage non inizializzato: chiama LocalStorage.init()');
    }
    return i;
  }

  static Future<LocalStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = LocalStorage._(prefs);
    return _instance!;
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  /// Legge un valore JSON (oggetto o lista). Ritorna null se assente o non valido.
  dynamic getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  bool? getBool(String key) {
    if (!_prefs.containsKey(key)) return null;
    // L'originale salva booleani come JSON ("true"/"false").
    final raw = _prefs.getString(key);
    if (raw != null) {
      if (raw == 'true') return true;
      if (raw == 'false') return false;
    }
    return _prefs.getBool(key);
  }

  Future<void> setBool(String key, bool value) =>
      _prefs.setString(key, value ? 'true' : 'false');

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();

  bool containsKey(String key) => _prefs.containsKey(key);
}
