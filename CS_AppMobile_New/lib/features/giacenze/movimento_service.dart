import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/sse_client.dart';
import '../../models/movimento_giacenza.dart';

/// Service del modulo Giacenze → Movimento (Stock Mov, scrittura).
/// Porting di Giacenze-Magazzino/Classi/Query.js
/// (selectArticoloMagazzini, writeMovimentiMultipliAPI, MovimentiMagazzinoSSE).
class MovimentoService {
  MovimentoService(this._api);

  final ApiClient _api;
  final SseClient _sse = SseClient();

  /// Ricerca articolo per movimento (magazzini, ODL possibili, ecc.).
  /// POST /giacenze/selectArticoloMagazzini.php {codiceArticolo, societa}
  Future<ArticoloMovimento?> selectArticoloMagazzini(
      String codiceArticolo, String societa) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/selectArticoloMagazzini',
      data: {'codiceArticolo': codiceArticolo, 'societa': societa},
    );
    if (res is Map) {
      return ArticoloMovimento.fromJson(Map<String, dynamic>.from(res));
    }
    return null;
  }

  /// Invia la lista movimenti all'API (POST WriteMovimentiMultipliAPI.php).
  /// Ritorna l'ack testuale del server (la conferma reale arriva via SSE).
  Future<String> writeMovimentiMultipli(
    List<MovimentoApi> movimenti, {
    required String idApi,
    required String nomeLista,
    required String utente,
    required String sezione,
    Map<String, dynamic> extraData = const {},
  }) async {
    return _api.postText(
      '${AppConfig.movimentiUrl}/WriteMovimentiMultipliAPI',
      data: {
        'dataObject': ({
          'id_api': idApi,
          'nome_lista': nomeLista,
          'utente': utente,
          'sezione': sezione,
          'extraData': extraData,
        }),
        'movimenti': (movimenti.map((m) => m.toJson()).toList()),
      },
    );
  }

  /// Stream degli esiti del movimento (MovimentiMagazzinoSSE?id=...).
  Stream<EsitoMovimento> streamEsito(String idApi) {
    return _sse
        .connect('${AppConfig.movimentiUrl}/MovimentiMagazzinoSSE?id=$idApi')
        .map(EsitoMovimento.fromJson);
  }

  void closeStream() => _sse.close();
}
