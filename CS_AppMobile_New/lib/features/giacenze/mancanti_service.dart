import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/sse_client.dart';
import '../../models/articolo_mancante.dart';
import '../../models/movimento_giacenza.dart';
import 'rientri_service.dart' show EsitoMovimentoSingolo;

/// Service dei moduli Giacenze → Mancanti e Prelievi.
/// Porting di Query.js: querySelectMancantiDaMag, queryGetOdlList (prelievi),
/// checkInviatiError, queryPreparaMovimentoMancanti (invio in blocco con
/// WriteMovimentiMultipliAPI + SSE) e queryUpdateInviaMovimentoMancanti
/// (ri-esecuzione sincrona dagli Inviati).
class MancantiService {
  MancantiService(this._api);

  final ApiClient _api;

  String get _base => AppConfig.giacenzeUrl;

  /// Scarica i mancanti per magazzino impegno (e, per i prelievi, ODL).
  /// POST /giacenze/selectMancantiDaMag.php
  /// [statoPickYSelected]: true per i Mancanti, false per i Prelievi.
  Future<MancantiResult> getMancanti({
    required String magazzinoImpegno,
    String codiceOdl = '',
    required bool statoPickYSelected,
  }) async {
    final res = await _api.postJson(
      '$_base/selectMancantiDaMag',
      data: {
        'magazzinoImpegno': magazzinoImpegno,
        'statoPickYSelected': statoPickYSelected,
        'codiceOdl': codiceOdl,
      },
    );
    if (res is Map) {
      return MancantiResult.fromJson(Map<String, dynamic>.from(res));
    }
    return MancantiResult();
  }

  /// Elenco ODL/ODV del magazzino per i Prelievi.
  /// POST /giacenze/getOdlListFromMagDest.php {magazzinoDestinazione, inviatoDaPrelievi:true}
  Future<List<OdlPrelievo>> getOdlPrelievi(String magazzino) async {
    final res = await _api.postJson(
      '$_base/getOdlListFromMagDest',
      data: {'magazzinoDestinazione': magazzino, 'inviatoDaPrelievi': true},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => OdlPrelievo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Storia dei movimenti già inviati.
  /// POST /giacenze/getStoriaMovimento.php {utente, dtrun, hrrun, magazzino_impegno, sezione}
  /// - con utente '' e il dataLog corrente: movimenti inviati da chiunque
  ///   dopo l'ultimo aggiornamento (per escluderli e per il controllo doppi invii);
  /// - con l'utente e dtrun/hrrun 0: storico dell'utente (tab Inviati).
  Future<List<Map<String, dynamic>>> getStoriaMovimento({
    required String utente,
    required String dtrun,
    required String hrrun,
    required String magazzinoImpegno,
    required String sezione,
  }) async {
    final res = await _api.postJson(
      '$_base/getStoriaMovimento',
      data: {
        'utente': utente,
        'dtrun': dtrun,
        'hrrun': hrrun,
        'magazzino_impegno': magazzinoImpegno,
        'sezione': sezione,
      },
    );
    if (res is! List) return [];
    return res.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Storico della tab Inviati (solo movimenti della [sezione]).
  Future<List<StoricoMancante>> getInviati({
    required String utente,
    required String magazzinoImpegno,
    required String sezione,
  }) async {
    final raw = await getStoriaMovimento(
      utente: utente,
      dtrun: '0',
      hrrun: '0',
      magazzinoImpegno: magazzinoImpegno,
      sezione: sezione,
    );
    return raw
        .where((m) => (m['sezione'] ?? '').toString() == sezione)
        .map(StoricoMancante.fromJson)
        .toList();
  }

  /// True se tra i movimenti inviati oggi dall'utente ce n'è almeno uno non
  /// completato (⚠️ sulla tab Inviati) — porting di checkInviatiError().
  /// POST /giacenze/getStoriaMovimentoOggi.php
  Future<bool> haInviatiConErrori({
    required String utente,
    required String magazzinoImpegno,
    required String sezione,
  }) async {
    final res = await _api.postJson(
      '$_base/getStoriaMovimentoOggi',
      data: {
        'utente': utente,
        'magazzino_impegno': magazzinoImpegno,
        'sezione': sezione,
      },
    );
    if (res is! List) return false;
    return res
        .whereType<Map>()
        .any((m) => (m['stato_mov'] ?? '').toString() != '2');
  }

  /// Ultimo aggiornamento del DB mancanti.
  /// GET /giacenze/getLatestDtrunHrrun.php
  Future<DataLogMancanti> getLatestDataLog() async {
    final res = await _api.postJson('$_base/getLatestDtrunHrrun');
    if (res is Map) return DataLogMancanti.fromJson(Map<String, dynamic>.from(res));
    return DataLogMancanti();
  }

  /// Movimenti da inviare in blocco — porting di writeStoriaMovimento()
  /// dentro queryPreparaMovimentoMancanti().
  static List<MovimentoApi> preparaMovimenti(
    List<ArticoloMancante> mancanti, {
    required String idApi,
    required String sezione,
    required String utente,
    required String societa,
    required DataLogMancanti dataLog,
  }) {
    return [
      for (final m in mancanti)
        MovimentoApi(
          idApi: idApi,
          causale: 'TNAV2',
          societa: societa,
          utente: utente,
          articolo: m.articolo,
          qta: m.giacdispo,
          damag: m.magdispo,
          davano: m.vanodispo,
          amag: m.magazzinoImpegno,
          avano: '',
          odl: m.odl,
          sezione: sezione,
          extra: {
            'dtrun': int.tryParse(dataLog.dtrun) ?? 0,
            'hrrun': int.tryParse(dataLog.hrrun) ?? 0,
            'descarticolo': m.descArticolo.replaceAll("'", '`'),
            'padre': m.padre,
            'des_padre': m.desPadre,
            'pesol': m.pesol,
            'desccolore': m.descColore,
            'fase': m.fase,
            'fabbdate_integer': m.fabbdateInteger,
            'nomefornlastdispo': m.nomefornlastdispo,
            'bollanolastdispo': m.bollanolastdispo,
            'bolladtlastdispo': m.bolladtlastdispo,
            'umis': m.umis,
            'descrizionefase': m.descrizioneFase,
            'pos': m.pos,
          },
        ),
    ];
  }

  /// Invio in blocco (POST api/WriteMovimentiMultipliAPI.php). Ritorna l'ack
  /// del server; l'esito reale arriva su [streamEsito].
  Future<String> writeMovimentiMultipli(
    List<MovimentoApi> movimenti, {
    required String idApi,
    required String nomeLista,
    required String utente,
    required String sezione,
  }) {
    return _api.postText(
      '${AppConfig.movimentiUrl}/WriteMovimentiMultipliAPI',
      data: {
        'dataObject': ({
          'id_api': idApi,
          'nome_lista': nomeLista,
          'utente': utente,
          'sezione': sezione,
          'extraData': <String, dynamic>{},
        }),
        'movimenti': (movimenti.map((m) => m.toJson()).toList()),
      },
    );
  }

  /// Esiti via SSE (api/MovimentiMagazzinoSSE?id=...). Ogni invio usa un
  /// suo [SseClient], così più liste possono essere seguite in parallelo.
  Stream<EsitoMovimento> streamEsito(String idApi, SseClient sse) {
    return sse
        .connect('${AppConfig.movimentiUrl}/MovimentiMagazzinoSSE?id=$idApi')
        .map(EsitoMovimento.fromJson);
  }

  /// Aggiorna lo stato di un movimento nella storia (2 = completato, 1 = errore).
  /// POST /giacenze/updateStatoStoriaMovimento.php
  Future<void> updateStatoStoria({
    required String articolo,
    required String odl,
    required String fase,
    required Object dtrun,
    required Object hrrun,
    required int statoMov,
  }) async {
    await _api.postText(
      '$_base/updateStatoStoriaMovimento',
      data: {
        'articolo': articolo,
        'odl': odl,
        'fase': fase,
        'dtrun': dtrun,
        'hrrun': hrrun,
        'stato_mov': statoMov,
      },
    );
  }

  /// Ri-esecuzione di un movimento dagli Inviati (percorso sincrono
  /// APIMovMagMobileApp.php) — porting di queryUpdateInviaMovimentoMancanti().
  /// Aggiorna la storia a 2 (successo) o 1 (errore).
  Future<EsitoMovimentoSingolo> rieseguiMovimento(
    StoricoMancante m, {
    required String utente,
    required String societa,
  }) async {
    final datamov = DateFormat('yyyyMMdd').format(DateTime.now());
    final res = await _api.postText(
      '${AppConfig.movimentiUrl}/APIMovMagMobileApp',
      data: {
        'articolo': m.articolo,
        'datamov': datamov,
        'causale': 'TNAV2',
        'damag': m.magdispo,
        'amag': m.magazzinoImpegno,
        'qta': m.qta,
        'davano': m.vanodispo,
        'avano': '',
        'odl': m.odl,
        'commessa': '',
        'nota': '',
        'ambiente': 'PRODUZIONE',
        'id': utente,
        'societa': societa,
      },
    );
    final esito = EsitoMovimentoSingolo(res);
    try {
      await updateStatoStoria(
        articolo: m.articolo,
        odl: m.odl,
        fase: m.fase,
        dtrun: m.dtrun,
        hrrun: m.hrrun,
        statoMov: esito.isSuccess ? 2 : 1,
      );
    } catch (_) {
      // Best-effort come l'originale.
    }
    return esito;
  }
}
