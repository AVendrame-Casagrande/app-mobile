import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/situazione_odl.dart';

/// Service del modulo Produzione → Situazione ODL (read-only).
/// Porting di Produzione-Odl/Classi/Query.js
/// (querySelectSituazioneCheckOdl + querySelectSituazioneOdl).
class SituazioneOdlService {
  SituazioneOdlService(this._api);

  final ApiClient _api;

  String get _baseUrl => AppConfig.produzioneUrl;

  /// Ricerca padre/ODL: ritorna l'elenco di ODL corrispondenti.
  /// POST /produzione/selectSituazioneCheckOdl.php data: {odl_padre}
  Future<List<CheckOdl>> checkOdl(String odlPadre) async {
    final res = await _api.postJson(
      '$_baseUrl/selectSituazioneCheckOdl',
      data: {'odl_padre': odlPadre},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => CheckOdl.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Situazione completa di un singolo ODL.
  /// POST /produzione/selectSituazioneOdl.php data: {odl}
  Future<SituazioneOdlResult> getSituazioneOdl(String odl) async {
    final res = await _api.postJson(
      '$_baseUrl/selectSituazioneOdl',
      data: {'odl': odl},
    );
    if (res is! List) return SituazioneOdlResult();
    final rows = res
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return SituazioneOdlResult.fromRows(rows);
  }
}
