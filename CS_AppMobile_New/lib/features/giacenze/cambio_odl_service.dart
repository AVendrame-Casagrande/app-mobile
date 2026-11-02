import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/cambio_odl.dart';
import 'rientri_service.dart' show EsitoMovimentoSingolo;

/// Service del modulo Giacenze → Cambio ODL (scrittura).
/// Porting di Query.js (selectCambioOdl, validateOdlSelectFasi,
/// queryUpdateInviaCambioOdl → APIMovMagMobileApp.php doppio movimento).
class CambioOdlService {
  CambioOdlService(this._api);

  final ApiClient _api;

  /// Ricerca cambio ODL per ODL / padre / magazzino.
  /// POST /giacenze/selectCambioOdl.php {codiceOdl_Padre_Mag}
  Future<CambioOdlResult> selectCambioOdl(String codice) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/selectCambioOdl',
      data: {'codiceOdl_Padre_Mag': codice},
    );
    if (res is Map) {
      return CambioOdlResult.fromJson(Map<String, dynamic>.from(res));
    }
    return CambioOdlResult();
  }

  /// Valida un nuovo ODL e ne ottiene le fasi possibili.
  /// POST /giacenze/validateOdlSelectFasi.php {odl}
  Future<List<FasePossibile>> validateOdlSelectFasi(String odl) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/validateOdlSelectFasi',
      data: {'odl': odl},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => FasePossibile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Invia un movimento singolo (APIMovMagMobileApp.php, form-urlencoded).
  Future<EsitoMovimentoSingolo> inviaMovimento({
    required String articolo,
    required String damag,
    required String davano,
    required String amag,
    required num qta,
    required String odl,
    required String utente,
    required String societa,
    String causale = 'TNAV2',
    String avano = '',
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
        'commessa': '',
        'nota': '',
        'id': utente,
        'societa': societa,
      },
    );
    return EsitoMovimentoSingolo(res);
  }
}
