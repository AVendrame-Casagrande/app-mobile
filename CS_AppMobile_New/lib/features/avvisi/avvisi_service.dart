import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/avviso.dart';

/// Service del modulo Attività/Avvisi.
/// Porting delle chiamate in www/scripts/Classi/Query.js
/// (getAllAvvisi, completaAvviso, eliminaAvviso).
class AvvisiService {
  AvvisiService(this._api);

  final ApiClient _api;

  /// Scarica tutti gli avvisi per il portale dell'utente.
  /// POST /avvisi/selectAllAvvisi.php  data: {utente_creazione_portale}
  Future<List<Avviso>> getAllAvvisi(String nomePortale) async {
    final res = await _api.postJson(
      '${AppConfig.avvisiUrl}/selectAllAvvisi',
      data: {'utente_creazione_portale': nomePortale},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => Avviso.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Avvisi validi oggi (filtro come nell'originale: scadenza >= oggi).
  List<Avviso> filtraValidiOggi(List<Avviso> tutti) {
    final dateNow = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
    final list = tutti.where((a) => a.isVisibileOggi(dateNow)).toList();
    list.sort((a, b) => b.timestInteger.compareTo(a.timestInteger));
    return list;
  }

  /// Numero di attività destinate all'utente corrente.
  int contaPerDestinatario(List<Avviso> validi, String codiceUtente) =>
      validi.where((a) => a.dest == codiceUtente).length;

  /// Completa un'attività.
  /// POST /avvisi/completaAvviso.php data: {timest, utente, dest}
  Future<bool> completaAvviso(Avviso avviso) async {
    try {
      await _api.postText(
        '${AppConfig.avvisiUrl}/completaAvviso',
        data: {
          'timest': avviso.timestInteger,
          'utente': avviso.utente.toLowerCase(),
          'dest': avviso.dest,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina un'attività.
  /// POST /avvisi/eliminaAvviso.php data: {timest, utente}
  Future<bool> eliminaAvviso(Avviso avviso) async {
    try {
      await _api.postText(
        '${AppConfig.avvisiUrl}/eliminaAvviso',
        data: {
          'timest': avviso.timestInteger,
          'utente': avviso.utente.toLowerCase(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
