import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/situazione_odv.dart';

/// Service del modulo Situazione ODV.
/// Porting di Query.js ajaxQuerySituazioneOdv.
class SituazioneOdvService {
  SituazioneOdvService(this._api);

  final ApiClient _api;

  /// Scarica la situazione ODV per tipo ordine ('OR' o 'OM').
  /// POST /getSituazioneOdv.php data: {or_om}
  /// Risultato ordinato per data consegna (dtcons) crescente.
  Future<List<OdvLista>> getSituazioneOdv(String orOm) async {
    final res = await _api.postJson(
      '${AppConfig.generaleUrl}/getSituazioneOdv',
      data: {'or_om': orOm},
    );
    if (res is! List) return [];
    final liste = res
        .whereType<Map>()
        .map((e) => OdvLista.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    liste.sort((a, b) => a.dtconsInteger.compareTo(b.dtconsInteger));
    return liste;
  }
}
