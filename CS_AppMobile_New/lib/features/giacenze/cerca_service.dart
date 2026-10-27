import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/articolo_giacenze.dart';
import '../../models/utente.dart';

/// Service del modulo Giacenze → Cerca.
/// Porting di Giacenze-Magazzino/Classi/Query.js
/// (querySelectSingoloArticoloCerca: selectArticoloLike + selectSingoloArticolo).
class CercaService {
  CercaService(this._api);

  final ApiClient _api;

  /// Società in base alla lingua dell'utente (come nell'originale).
  String societaPerUtente(Utente utente) => utente.isEnglish ? 'CSUSA' : 'CSPRO';

  /// Ricerca "like" per codice/descrizione.
  /// POST /giacenze/selectArticoloLike.php data: {inputArticoloDesc, societa}
  Future<List<ArticoloRicerca>> cercaLike(String input, String societa) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/selectArticoloLike',
      data: {'inputArticoloDesc': input, 'societa': societa},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ArticoloRicerca.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Dettaglio completo di un singolo articolo.
  /// POST /giacenze/selectSingoloArticolo.php
  /// data: {codiceArticolo, societa, needCompleteInfo:true}
  Future<ArticoloGiacenze?> getSingoloArticolo(
      String codiceArticolo, String societa) async {
    final dynamic res;
    try {
      res = await _api.postJson(
        '${AppConfig.giacenzeUrl}/selectSingoloArticolo',
        data: {
          'codiceArticolo': codiceArticolo,
          'societa': societa,
          'needCompleteInfo': true,
        },
      );
    } on ApiException catch (e) {
      // Articolo inesistente: il server risponde HTTP 404.
      if (e.statusCode == 404) return null;
      rethrow;
    }
    if (res is Map) {
      return ArticoloGiacenze.fromJson(Map<String, dynamic>.from(res));
    }
    return null;
  }

  /// Distinta (esplosione/implosione) di un articolo.
  /// POST /giacenze/getListaDistinte.php
  /// data: {codiceArticolo, tipoDistinta, solamenteCheckFigli:false}
  Future<List<DistintaArticolo>> getListaDistinte(
    String codiceArticolo, {
    String tipoDistinta = 'esplosione',
  }) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/getListaDistinte',
      data: {
        'codiceArticolo': codiceArticolo,
        'tipoDistinta': tipoDistinta,
        'solamenteCheckFigli': false,
      },
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => DistintaArticolo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
