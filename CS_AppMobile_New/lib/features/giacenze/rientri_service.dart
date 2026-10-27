import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/rientro.dart';

/// Esito di un movimento singolo (APIMovMagMobileApp.php).
class EsitoMovimentoSingolo {
  final String response;
  EsitoMovimentoSingolo(this.response);

  /// Successo = la risposta Diapason inizia con '0043I'.
  bool get isSuccess =>
      response.trim().length >= 5 && response.trim().substring(0, 5) == '0043I';
}

/// Service del modulo Giacenze → Rientri (scrittura).
/// Porting di Query.js (selectRientri) + EventHandlers Rientri
/// (APIMovMagMobileApp.php).
class RientriService {
  RientriService(this._api);

  final ApiClient _api;

  /// Magazzini di destinazione possibili per un rientro (come nell'originale).
  static const List<String> magazziniDestinazione = ['MGPUL01', 'MGB180', 'MG00020'];

  /// Elenco rientri per magazzino.
  /// POST /giacenze/selectRientri.php {magazzino}
  Future<List<Rientro>> getRientri(String magazzino) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/selectRientri',
      data: {'magazzino': magazzino},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => Rientro.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Invia un movimento singolo all'API Diapason.
  /// POST /api/APIMovMagMobileApp.php (form-urlencoded).
  Future<EsitoMovimentoSingolo> inviaMovimento({
    required String articolo,
    required String damag,
    required String davano,
    required String amag,
    required num qta,
    required String utente,
    required String societa,
    String causale = 'TNAV2',
    String avano = '',
    String odl = '',
    String commessa = '',
    String nota = '',
    String ambiente = 'PRODUZIONE',
  }) async {
    final datamov = DateFormat('yyyyMMdd').format(DateTime.now());
    final res = await _api.postText(
      '${AppConfig.movimentiUrl}/APIMovMagMobileApp',
      data: {
        'articolo': articolo,
        'datamov': datamov,
        'causale': causale,
        'damag': damag,
        'amag': amag,
        'qta': qta,
        'davano': davano,
        'avano': avano,
        'odl': odl,
        'commessa': commessa,
        'nota': nota,
        'ambiente': ambiente,
        'id': utente,
        'societa': societa,
      },
    );
    return EsitoMovimentoSingolo(res);
  }
}
