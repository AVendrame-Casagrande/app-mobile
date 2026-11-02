import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/kanban_articolo.dart';
import '../../models/scaffale_kanban.dart';

/// Service del modulo Kanban.
/// Porting di Kanban/Classi/Query.js (selectAllScaffali, selectArticoliScaffale,
/// selectSingoloArticolo, selectSingoloScaffale, writeOrdineRifornimento).
class ScaffaliService {
  ScaffaliService(this._api);

  final ApiClient _api;

  /// Elenco di tutti gli scaffali.
  /// GET /kanban/selectAllScaffali.php → list {codice, descrizione, magazzino, societa}
  Future<List<ScaffaleKanban>> getAllScaffali() async {
    final res = await _api.postJson('${AppConfig.kanbanUrl}/selectAllScaffali');
    if (res is! List) return [];
    final lista = res
        .whereType<Map>()
        .map((e) => ScaffaleKanban.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    lista.sort((a, b) => a.codice.compareTo(b.codice));
    return lista;
  }

  /// Dettaglio celle di un singolo scaffale.
  /// POST /kanban/selectSingoloScaffale.php
  /// data: {codiceScaffale, limitPresent} → [{codice, descrizione, magazzino, societa, qtaCella}]
  Future<List<ScaffaleKanban>> getSingoloScaffale(
    String codiceScaffale, {
    bool limitPresent = false,
  }) async {
    final res = await _api.postJson(
      '${AppConfig.kanbanUrl}/selectSingoloScaffale',
      data: {
        'codiceScaffale': codiceScaffale,
        'limitPresent': limitPresent,
      },
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ScaffaleKanban.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Articoli presenti in uno scaffale.
  /// POST /kanban/selectArticoliScaffale.php {codiceScaffale}
  /// → list {codice, descrizione, qtaConfezione, tipo, fornitore}
  Future<List<ArticoloScaffale>> getArticoliScaffale(String codiceScaffale) async {
    final res = await _api.postJson(
      '${AppConfig.kanbanUrl}/selectArticoliScaffale',
      data: {'codiceScaffale': codiceScaffale},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ArticoloScaffale.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Verifica che l'articolo esista (Query.js → giacenze/selectSingoloArticolo,
  /// società della sessione, needCompleteInfo:false). Ritorna il codice articolo
  /// restituito dal server, oppure null se l'articolo non esiste.
  /// Rilancia l'eccezione per gli errori di rete/server.
  Future<String?> verificaArticolo(String codice) async {
    final dynamic res;
    try {
      res = await _api.postJson(
        '${AppConfig.giacenzeUrl}/selectSingoloArticolo',
        data: {
          'codiceArticolo': codice,
          'societa': AuthToken.societa,
          'needCompleteInfo': false,
        },
      );
    } on ApiException catch (e) {
      // HTTP 404 = articolo inesistente.
      if (e.statusCode == 404) return null;
      rethrow;
    }
    if (res is Map) {
      final c = (res['codice'] ?? '').toString().trim();
      if (c.isNotEmpty) return c;
    }
    return null;
  }

  /// Aggiunge un articolo allo scaffale.
  /// POST /kanban/addArticoloScaffale {scaffale, codiceArticolo}
  /// → 'error' se l'articolo è già presente nello scaffale, altrimenti 'ok'.
  /// Ritorna false se l'articolo era già presente.
  Future<bool> addArticoloScaffale(String scaffale, String codiceArticolo) async {
    final res = await _api.postText(
      '${AppConfig.kanbanUrl}/addArticoloScaffale',
      data: {'scaffale': scaffale, 'codiceArticolo': codiceArticolo},
    );
    return res.trim() != 'error';
  }

  /// Toglie un articolo dallo scaffale.
  /// POST /kanban/deleteArticoloScaffale {scaffale, codiceArticolo} → 'ok'
  Future<void> deleteArticoloScaffale(
      String scaffale, String codiceArticolo) async {
    await _api.postText(
      '${AppConfig.kanbanUrl}/deleteArticoloScaffale',
      data: {'scaffale': scaffale, 'codiceArticolo': codiceArticolo},
    );
  }

  /// Elenco degli scaffali in cui è presente un articolo.
  /// POST /kanban/addElencoScaffaliToArticolo {codiceArticolo}
  /// → list {codice, descrizione}
  Future<List<ScaffaloArticolo>> getElencoScaffaliArticolo(
      String codiceArticolo) async {
    final res = await _api.postJson(
      '${AppConfig.kanbanUrl}/addElencoScaffaliToArticolo',
      data: {'codiceArticolo': codiceArticolo},
    );
    if (res is! List) return [];
    return res.whereType<Map>().map((e) {
      return ScaffaloArticolo(
        codice: (e['codice'] ?? '').toString(),
        descrizione: (e['descrizione'] ?? '').toString(),
      );
    }).toList();
  }

  /// Dettaglio articolo Kanban (con scaffali).
  /// POST /kanban/selectSingoloArticolo.php {codiceArticolo, addScaffaliPhp:true}
  Future<ArticoloKanban?> getArticoloKanban(String codice) async {
    final res = await _api.postJson(
      '${AppConfig.kanbanUrl}/selectSingoloArticolo',
      data: {'codiceArticolo': codice.trim(), 'addScaffaliPhp': true},
    );
    if (res is Map && res['codice'] != null) {
      return ArticoloKanban.fromJson(Map<String, dynamic>.from(res));
    }
    return null;
  }

  /// Invia gli ordini di rifornimento ai fornitori.
  /// POST /kanban/writeOrdineRifornimento.php {listaRifornimenti: JSON}
  /// Ogni riga: {scaffale, articolo, quantita, tipoLista:'rifornimento'}.
  Future<bool> inviaRifornimento(List<Map<String, dynamic>> righe) async {
    final res = await _api.postJson(
      '${AppConfig.kanbanUrl}/writeOrdineRifornimento',
      data: {'listaRifornimenti': (righe)},
    );
    // Il backend risponde JSON; consideriamo l'assenza di errore come successo.
    return res != null;
  }

  /// Elenco dei magazzini distinti presenti negli scaffali (per il filtro).
  List<String> magazziniDistinti(List<ScaffaleKanban> scaffali) {
    final set = <String>{};
    for (final s in scaffali) {
      if (s.magazzino.isNotEmpty) set.add(s.magazzino);
    }
    final lista = set.toList()..sort();
    return lista;
  }
}
