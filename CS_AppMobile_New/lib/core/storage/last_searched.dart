import 'package:intl/intl.dart';

import 'local_storage.dart';

/// Una voce di ricerca recente.
class LastSearchedItem {
  final String codice;
  final String data; // dd-MM-yyyy
  final String ora; // HH:mm:ss

  LastSearchedItem({this.codice = '', this.data = '', this.ora = ''});

  Map<String, dynamic> toJson() => {'codice': codice, 'data': data, 'ora': ora};

  factory LastSearchedItem.fromJson(Map<String, dynamic> json) =>
      LastSearchedItem(
        codice: (json['codice'] ?? '').toString(),
        data: (json['data'] ?? '').toString(),
        ora: (json['ora'] ?? '').toString(),
      );
}

/// Gestione delle "ultime ricerche" per sezione — porting di
/// applicazione.updateLastSearched / getHtmlLastSearched (Applicazione.js).
/// Persistite in LocalStorage sotto la chiave 'lastSearched' come una mappa
/// `sezione -> lista di {codice, data, ora}`.
class LastSearched {
  LastSearched._();

  static const String _key = 'lastSearched';
  static const int _max = 15;

  static Map<String, dynamic> _readAll() {
    final raw = LocalStorage.instance.getJson(_key);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  /// Ritorna le ricerche recenti di una sezione, dalla più recente.
  static List<LastSearchedItem> get(String sezione) {
    final all = _readAll();
    final raw = all[sezione];
    if (raw is! List) return [];
    final lista = raw
        .whereType<Map>()
        .map((e) => LastSearchedItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    // Salvate dalla più vecchia alla più recente → inverto per mostrarle al contrario.
    return lista.reversed.toList();
  }

  /// Aggiunge/aggiorna una ricerca (dedup, max 15) e persiste.
  static Future<void> add(String sezione, String codice) async {
    final c = codice.trim();
    if (c.isEmpty) return;
    final all = _readAll();
    final raw = all[sezione];
    final lista = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw.whereType<Map>()) {
        lista.add(Map<String, dynamic>.from(e));
      }
    }
    // Rimuovo eventuale duplicato.
    lista.removeWhere((e) => (e['codice'] ?? '').toString() == c);
    // Cap a _max.
    while (lista.length >= _max) {
      lista.removeAt(0);
    }
    final now = DateTime.now();
    lista.add(LastSearchedItem(
      codice: c,
      data: DateFormat('dd-MM-yyyy').format(now),
      ora: DateFormat('HH:mm:ss').format(now),
    ).toJson());
    all[sezione] = lista;
    await LocalStorage.instance.setJson(_key, all);
  }

  /// Svuota le ricerche di una sezione.
  static Future<void> clear(String sezione) async {
    final all = _readAll();
    all.remove(sezione);
    await LocalStorage.instance.setJson(_key, all);
  }
}
