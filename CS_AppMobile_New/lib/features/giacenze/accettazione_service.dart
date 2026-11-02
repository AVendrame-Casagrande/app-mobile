import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/accettazione.dart';

/// Esito dell'invio lista di carico (WriteListaMagazzinoAutomatico.php).
class EsitoListaCarico {
  final String response;
  EsitoListaCarico(this.response);

  /// Successo = la risposta inizia con "200".
  bool get isSuccess =>
      response.trim().length >= 3 && response.trim().substring(0, 3) == '200';
}

/// Service del modulo Giacenze → Accettazione (scrittura).
/// Porting di Pagine/Accettazione (selectAccettazioni,
/// WriteListaMagazzinoAutomatico).
/// Sotto-funzioni rimandate: import precarico, automha UDC, PDF, auto-alert
/// variazioni, mancanti dettaglio.
class AccettazioneService {
  AccettazioneService(this._api);

  final ApiClient _api;

  /// Elenco accettazioni per magazzino.
  /// POST /giacenze/selectAccettazioni.php {magazzino}
  Future<AccettazioniResult> getAccettazioni(String magazzino) async {
    final dynamic res;
    try {
      res = await _api.postJson(
        '${AppConfig.giacenzeUrl}/selectAccettazioni',
        data: {'magazzino': magazzino},
      );
    } on ApiException catch (e) {
      // HTTP 404 = nessun movimento per il magazzino (come il PHP): lista vuota.
      if (e.statusCode == 404) return AccettazioniResult();
      rethrow;
    }
    if (res is Map) {
      return AccettazioniResult.fromJson(Map<String, dynamic>.from(res));
    }
    return AccettazioniResult();
  }

  /// Invia la lista di carico al magazzino automatico.
  /// POST /api/WriteListaMagazzinoAutomatico.php (tipo_interfaccia 'CAR').
  Future<EsitoListaCarico> inviaListaCarico({
    required String utente,
    required String magazzinoOrigine,
    required String magazzinoDestinazione,
    required List<Accettazione> righe,
  }) async {
    // Raggruppo per articolo sommando le quantità (come nell'originale).
    final mappa = <String, Map<String, dynamic>>{};
    for (final r in righe) {
      final ex = mappa[r.articolo];
      if (ex == null) {
        mappa[r.articolo] = {
          'articolo': r.articolo,
          'qta': r.qtaCarico,
          'umis': r.um,
        };
      } else {
        ex['qta'] = (ex['qta'] as num) + r.qtaCarico;
      }
    }
    final listaPrelievi = mappa.values.toList();

    final res = await _api.postText(
      '${AppConfig.movimentiUrl}/WriteListaMagazzinoAutomatico',
      data: {
        'utente': utente,
        'magazzino_origine': magazzinoOrigine,
        'magazzino_destinazione': magazzinoDestinazione,
        'tipo_interfaccia': 'CAR',
        'listaPrelievi': (listaPrelievi),
        'nota': '',
        'odl': '',
        'fase': '',
      },
    );
    return EsitoListaCarico(res);
  }
}
