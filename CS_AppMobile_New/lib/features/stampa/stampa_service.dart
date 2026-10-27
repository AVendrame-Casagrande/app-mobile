import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/stampa_verniciatura.dart';

/// Service backend del modulo Stampa Etichette (verniciatura).
/// Porting di Giacenze-Magazzino/Classi/Query.js
/// (getOdlListFromMagDest, addInfoOdlStampaVern, addInfoOdlStampaVernLibera).
class StampaService {
  StampaService(this._api);

  final ApiClient _api;

  String get _base => AppConfig.giacenzeUrl;

  /// Lista ODL per magazzino destinazione.
  /// POST /giacenze/getOdlListFromMagDest.php
  Future<List<OdlStampa>> getOdlList(String magazzinoDestinazione) async {
    final res = await _api.postJson(
      '$_base/getOdlListFromMagDest',
      data: {
        'magazzinoDestinazione': magazzinoDestinazione,
        'inviatoDaPrelievi': false,
      },
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => OdlStampa.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Info ODL per popolare l'etichetta (fasi, padre, descrizione, colore).
  /// POST /giacenze/addInfoOdlStampaVern.php
  Future<InfoOdlStampa> addInfoOdl(String odl) async {
    final res = await _api.postJson(
      '$_base/addInfoOdlStampaVern',
      data: {'odl': odl},
    );
    if (res is Map) {
      return InfoOdlStampa.fromJson(Map<String, dynamic>.from(res));
    }
    return InfoOdlStampa();
  }

  /// Info ODL per etichetta libera (può non avere fasi).
  /// POST /giacenze/addInfoOdlStampaVernLibera.php
  Future<InfoOdlStampa> addInfoOdlLibera(String odl) async {
    final res = await _api.postJson(
      '$_base/addInfoOdlStampaVernLibera',
      data: {'odl': odl},
    );
    if (res is Map) {
      return InfoOdlStampa.fromJson(Map<String, dynamic>.from(res));
    }
    return InfoOdlStampa();
  }
}
