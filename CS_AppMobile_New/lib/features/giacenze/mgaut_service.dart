import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/automha_ordine.dart';
import '../../models/movimento_giacenza.dart';

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();

/// Giacenza di un articolo in un magazzino (listaMagazzini di selectSingoloArticolo).
class GiacenzaMagazzino {
  final num giacente;
  final num impegnato;
  const GiacenzaMagazzino(this.giacente, this.impegnato);
}

/// Articolo con le giacenze per magazzino.
class ArticoloAut {
  final String codice;
  final String descrizione;
  final String unitaMisura;
  final Map<String, GiacenzaMagazzino> magazzini;
  const ArticoloAut(this.codice, this.descrizione, this.unitaMisura, this.magazzini);

  num giacenteSu(String magazzino) => magazzini[magazzino]?.giacente ?? 0;
}

/// Service del modulo Giacenze → Liste AUT / MGAUT.
/// Porting di Pagine/Mgaut: AUT01 (getListaTrasferimentiMgis001 + invio
/// WriteMovimentiMultipliAPI 'mgaut01'), MGAUT02, liste MGAUT00/MGAUT10
/// (creazione prelievi mgaut_prel_* + WriteListaMagazzinoAutomatico) e
/// liste 27/34 dalle Attività.
class MgautService {
  MgautService(this._api);

  final ApiClient _api;

  String get _g => AppConfig.giacenzeUrl;

  Future<List<AutomhaOrdine>> _getLista(String endpoint) async {
    final res = await _api.postJson('$_g/$endpoint');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => AutomhaOrdine.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Lista trasferimenti da MGAUT01 (AUT01).
  Future<List<AutomhaOrdine>> getMgis001() =>
      _getLista('getListaTrasferimentiMgis001');

  /// Lista MGAUT02.
  Future<List<AutomhaOrdine>> getMgaut02() => _getLista('getListaMgaut02');

  /// Elimina una lista di prelievo. true se 'deleted'.
  /// POST /giacenze/deleteListaPrelievo.php {tipoprel, rifprel, subrifprel, seqprel}
  Future<bool> deleteLista(AutomhaOrdine r) async {
    final res = await _api.postText(
      '$_g/deleteListaPrelievo',
      data: {
        'tipoprel': r.tipoprel,
        'rifprel': r.rifprel,
        'subrifprel': r.subrifprel,
        'seqprel': r.seqprel,
      },
    );
    return res.trim() == 'deleted';
  }

  /// Costruisce il MovimentoApi 'mgaut01' per una riga MGIS001.
  static MovimentoApi movimentoDaRiga(
    AutomhaOrdine r, {
    required String idApi,
    required String utente,
  }) {
    var causale = 'TNAV2';
    var amag = r.magto;
    var avano = r.vanoto;
    var commessa = '';
    var nota = r.nota;

    // Movimento UNA per i KAN (come nell'originale).
    if (r.isKan) {
      causale = 'UNA';
      nota = '${r.magto}_${r.scaffale}';
      amag = '123140'; // cdc convenzionale per i movimenti UNA
      commessa = r.commessa;
      avano = '';
    }

    return MovimentoApi(
      idApi: idApi,
      causale: causale,
      societa: AuthToken.societa,
      utente: utente,
      articolo: r.articolo,
      qta: r.qta,
      damag: 'MGAUT01',
      davano: '',
      amag: amag,
      avano: avano,
      odl: r.rifprel,
      commessa: commessa,
      nota: nota,
      sezione: 'mgaut01',
      rifprel: r.rifprel,
      subrifprel: r.subrifprel,
      seqprel: r.seqprel,
      seq: r.seq,
    );
  }

  // ---------------------------------------------------------------------------
  // Creazione prelievi (addArticoloManualeToMgaut)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _maps(dynamic res) => res is List
      ? res.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];

  List<String> _strings(dynamic res) =>
      res is List ? res.map((e) => e.toString()).toList() : [];

  /// Articolo con listaMagazzini. null se non esiste (HTTP 404 o risposta vuota).
  /// POST /giacenze/selectSingoloArticolo.php {codiceArticolo, societa, needCompleteInfo:false}
  Future<ArticoloAut?> getArticolo(String codice) async {
    dynamic res;
    try {
      res = await _api.postJson('$_g/selectSingoloArticolo', data: {
        'codiceArticolo': codice,
        'societa': AuthToken.societa,
        'needCompleteInfo': false,
      });
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
    if (res is! Map || res['codice'] == null) return null;
    final mag = <String, GiacenzaMagazzino>{};
    final raw = res['listaMagazzini'];
    if (raw is List) {
      for (final m in raw.whereType<Map>()) {
        mag[_str(m['codice'])] =
            GiacenzaMagazzino(_num(m['giacente']), _num(m['impegnato']));
      }
    }
    return ArticoloAut(_str(res['codice']), _str(res['descrizione']),
        _str(res['unitaMisura']), mag);
  }

  /// [{articolo, qta}] — POST mgaut_prel_odl_get_articoli.php
  Future<List<Map<String, dynamic>>> odlGetArticoli(
          String odl, String fase, String magOrigine, String magDest) async =>
      _maps(await _api.postJson('$_g/mgaut_prel_odl_get_articoli', data: {
        'odl': odl,
        'fase': fase,
        'magazzino_origine': magOrigine,
        'magazzino_destinazione': magDest,
      }));

  /// [{articolo, pos, seq, qta}] — POST mgaut_prel_odv_get_articoli.php
  Future<List<Map<String, dynamic>>> odvGetArticoli(
          String odv, String magOrigine, String magDest) async =>
      _maps(await _api.postJson('$_g/mgaut_prel_odv_get_articoli', data: {
        'odv': odv,
        'magazzino_origine': magOrigine,
        'magazzino_destinazione': magDest,
      }));

  /// Magazzini di destinazione possibili per l'articolo.
  /// POST mgaut_prel_odl_get_magazzini.php / mgaut_prel_odv_get_magazzini.php
  Future<List<String>> getMagazziniDestinazione(
      String tipo, String articolo, String magOrigine) async {
    final endpoint = tipo == 'ODV'
        ? 'mgaut_prel_odv_get_magazzini'
        : 'mgaut_prel_odl_get_magazzini';
    return _strings(await _api.postJson('$_g/$endpoint',
        data: {'articolo': articolo, 'magazzino_origine': magOrigine}));
  }

  /// [{odl, padre, des_padre, fase, descrizionefase, qta}] — POST mgaut_prel_odl_get_odl.php
  Future<List<Map<String, dynamic>>> odlGetOdl(
          String articolo, String magOrigine, String magDest) async =>
      _maps(await _api.postJson('$_g/mgaut_prel_odl_get_odl', data: {
        'articolo': articolo,
        'magazzino_origine': magOrigine,
        'magazzino_destinazione': magDest,
      }));

  /// [{odv, cliente, nomecliente, pos, seq, qta}] — POST mgaut_prel_odv_get_odv.php
  Future<List<Map<String, dynamic>>> odvGetOdv(
          String articolo, String magOrigine, String magDest) async =>
      _maps(await _api.postJson('$_g/mgaut_prel_odv_get_odv', data: {
        'articolo': articolo,
        'magazzino_origine': magOrigine,
        'magazzino_destinazione': magDest,
      }));

  /// {padre, desc_padre, listaFasi:[{fase, descrizionefase, qta}]} o null.
  /// POST checkOdlListaPrelievoMgautAndGetFasi.php {odl}
  Future<Map<String, dynamic>?> checkOdlGetFasi(String odl) async {
    // ODL vuoto: l'API risponde 400 (parametro obbligatorio) → 'ODL inesistente'.
    if (odl.trim().isEmpty) return null;
    final res = await _api
        .postJson('$_g/checkOdlListaPrelievoMgautAndGetFasi', data: {'odl': odl});
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  /// (magazzinoFound, magazzino_has_vani)
  /// POST checkMagazzinoExistsAndCheckVani.php {magazzino}
  Future<(bool, bool)> checkMagazzino(String magazzino) async {
    // Magazzino vuoto: l'API risponde 400 (parametro obbligatorio) → non trovato.
    if (magazzino.trim().isEmpty) return (false, false);
    final res = await _api.postJson('$_g/checkMagazzinoExistsAndCheckVani',
        data: {'magazzino': magazzino});
    if (res is! Map) return (false, false);
    bool t(dynamic v) => v == true || v == 1 || v == '1';
    return (t(res['magazzinoFound']), t(res['magazzino_has_vani']));
  }

  /// POST queryDesktop/giacenze/checkVanoExists.php {vano}
  Future<bool> checkVanoExists(String vano) async {
    final res = await _api.postJson(
        '${AppConfig.queryDesktopUrl}/giacenze/checkVanoExists',
        data: {'vano': vano});
    return res == true || res == 1 || res == '1';
  }

  /// ODV della pre bolla — POST mgaut_prel_immediato_get_odv_from_prebolla.php
  /// Pre bolla vuota: nessun ODV (l'API risponderebbe 400).
  Future<List<String>> odvDaPrebolla(String prebolla) async => prebolla.trim().isEmpty
      ? []
      : _strings(await _api.postJson('$_g/mgaut_prel_immediato_get_odv_from_prebolla',
          data: {'prebolla': prebolla}));

  /// Righe del prelievo immediato — POST mgaut_prel_immediato_get_righe_from_odv.php
  /// [{articolo, descarticolo, umis, qta, magfrom, magto, cliente, nomecliente, pos, seq}]
  Future<List<Map<String, dynamic>>> righeDaOdv(String odv) async => _maps(
      await _api.postJson('$_g/mgaut_prel_immediato_get_righe_from_odv',
          data: {'odv': odv}));

  /// Invio di una lista al magazzino automatico. Successo se inizia con "200".
  /// POST api/WriteListaMagazzinoAutomatico.php
  Future<String> writeListaMagazzinoAutomatico({
    required String utente,
    required String magazzinoOrigine,
    required String magazzinoDestinazione,
    required String odl,
    required String fase,
    required String tipoInterfaccia,
    required List<Map<String, dynamic>> righe,
    required String nota,
  }) async {
    final res = await _api.postText(
      '${AppConfig.movimentiUrl}/WriteListaMagazzinoAutomatico',
      data: {
        'utente': utente,
        'magazzino_origine': magazzinoOrigine,
        'magazzino_destinazione': magazzinoDestinazione,
        'odl': odl,
        'fase': fase,
        'tipo_interfaccia': tipoInterfaccia,
        'listaPrelievi': (righe),
        'nota': nota,
      },
    );
    return res.trim();
  }

  // ---------------------------------------------------------------------------
  // Liste 27/34 (dalle Attività)
  // ---------------------------------------------------------------------------

  /// false se la riga è già al MGAUT02 in attesa dello script di completamento.
  /// POST getListaPrelievi0027FromAttivitaCheckScript.php
  Future<bool> daVisualizzare0027(String articolo, String odl, int timest) async {
    final dynamic res;
    try {
      res = await _api.postJson(
          '$_g/getListaPrelievi0027FromAttivitaCheckScript',
          data: {'articolo_avviso': articolo, 'odl_avviso': odl, 'timest_avviso': timest});
    } on ApiException catch (e) {
      // HTTP 400 = articolo/ODL dell'Attività vuoti: il PHP non trovava
      // movimenti e la riga restava visibile.
      if (e.statusCode == 400) return true;
      rethrow;
    }
    return !(res == false || res == 0 || res == '0' || res == 'false');
  }

  /// Avvia lo script che completerà l'Attività quando l'articolo arriva su
  /// MGAUT01 e ritorna l'id del messaggio chat inviato al creatore.
  /// POST avvisi/startScriptCompletaAvviso0027Mgaut01.php
  Future<String> startScriptCompletaAvviso({
    required String articolo,
    required String odl,
    required int timestAvviso,
    required String utenteCompletante,
    required String utenteAvviso,
    required String utenteAvvisoDiapason,
    required String destAvviso,
    required String chatText,
  }) async {
    final res = await _api.postText(
      '${AppConfig.avvisiUrl}/startScriptCompletaAvviso0027Mgaut01',
      data: {
        'articolo_avviso': articolo,
        'odl_avviso': odl,
        'timest_avviso': timestAvviso,
        'utente_completante_diapason': utenteCompletante,
        'utente_avviso': utenteAvviso,
        'utente_avviso_diapason': utenteAvvisoDiapason,
        'dest_avviso': destAvviso,
        'chat_text': chatText,
      },
    );
    return res.trim();
  }

  /// Promemoria email del messaggio chat (setEmailChatReminder).
  /// POST chat/setEmailChatReminder.php {message: JSON, id_inserted}
  Future<void> setEmailChatReminder(
    String id, {
    required String messaggio,
    required String sender,
    required String receiver,
  }) async {
    final now = DateTime.now();
    final message = {
      'id': int.tryParse(id) ?? 0,
      'messaggio': messaggio,
      'senderid': sender,
      'receiverid': receiver,
      'data_invio': int.parse(DateFormat('yyyyMMdd').format(now)),
      'ora_invio': int.parse(DateFormat('HHmmss').format(now)),
      'letto': false,
      'data_lettura': 0,
      'ora_lettura': 0,
      'tipo': 'inviato',
      'tipo_messaggio': 'avviso_completato',
      'nascosto_ricevuto': 'f',
      'nascosto_inviato': 'f',
      'url_foto': '',
      'senderid_group': '',
    };
    await _api.postText('${AppConfig.chatUrl}/setEmailChatReminder',
        data: {'message': (message), 'id_inserted': id});
  }
}
