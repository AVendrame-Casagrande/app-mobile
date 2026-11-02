import '../../core/config.dart';
import '../../core/network/api_client.dart';

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();
bool _bool(dynamic v) => v == true || v == 't' || v == '1' || v == 1;

/// Magazzino da cui l'articolo può essere trasferito al magazzino della lista.
class Trasferimento {
  final String magazzino;
  num disponibile;
  final num disponibileOriginale;
  Trasferimento(this.magazzino, this.disponibile) : disponibileOriginale = disponibile;

  Map<String, dynamic> toJson() => {
        'magazzino': magazzino,
        'disponibile': disponibile,
        'disponibile_originale': disponibileOriginale,
      };
}

/// Riga della lista di Pre-Carico (classe RigaPrecarico).
class RigaPrecarico {
  final String articolo;
  final String descrizione;
  final String um;
  num qta;
  num qtaOriginale;
  num qtaEnx;
  num qtaEnxOriginale;
  String nota;
  final List<Trasferimento> trasferimenti = [];

  /// Campi in più arrivati dallo storico (inviati di nuovo con la modifica).
  final Map<String, dynamic> extra;

  RigaPrecarico({
    required this.articolo,
    this.descrizione = '',
    this.um = '',
    required this.qta,
    this.qtaEnx = 0,
    this.nota = '',
    this.extra = const {},
  })  : qtaOriginale = qta,
        qtaEnxOriginale = qtaEnx;

  factory RigaPrecarico.fromStorico(Map<String, dynamic> j) => RigaPrecarico(
        articolo: _str(j['articolo']),
        descrizione: _str(j['descrizione']),
        um: _str(j['um']),
        qta: _num(j['qta']),
        qtaEnx: _num(j['qta_enx']),
        nota: _str(j['nota']),
        extra: j,
      );

  Map<String, dynamic> toJson() => {
        ...extra,
        'articolo': articolo,
        'descrizione': descrizione,
        'um': um,
        'qta': qta,
        'qta_originale': qtaOriginale,
        'qta_enx': qtaEnx,
        'qta_enx_originale': qtaEnxOriginale,
        'nota': nota,
        'listaRientriTrasferimenti': trasferimenti.map((t) => t.toJson()).toList(),
      };
}

/// Lista di Pre-Carico corrente (classe ListaPrecaricoPage).
class ListaPrecarico {
  final List<RigaPrecarico> righe = [];
  String magazzino = '';
  String odl = 'PRE-CARICO';
  String sequenza = '0';
  String padre = '';
  String padreDescrizione = '';
  String fase = '';
  bool modificaInCorso = false;

  String get nome => '${odl}_${fase}_$sequenza';
}

/// Lista già inviata (getStoriaPrecarico.php).
class StoricoPrecarico {
  final String id;
  final String odl;
  final String fase;
  final String sequenza;
  final String magazzino;
  final String padre;
  final String padreDescrizione;
  final bool completato;
  final bool modificato;
  bool revisionato;
  final int dataCreazione;
  final int oraCreazione;
  final int dataCompletamento;
  final int oraCompletamento;
  final String utenteCompletamento;
  final List<Map<String, dynamic>> righe;

  StoricoPrecarico._(
    this.id,
    this.odl,
    this.fase,
    this.sequenza,
    this.magazzino,
    this.padre,
    this.padreDescrizione,
    this.completato,
    this.modificato,
    this.revisionato,
    this.dataCreazione,
    this.oraCreazione,
    this.dataCompletamento,
    this.oraCompletamento,
    this.utenteCompletamento,
    this.righe,
  );

  String get nome => '${odl}_${fase}_$sequenza';

  /// Modificata dal magazzino e non ancora revisionata (MOD in rosso).
  bool get daRevisionare => modificato && !revisionato;

  factory StoricoPrecarico.fromJson(Map<String, dynamic> j) {
    final raw = j['righe'];
    return StoricoPrecarico._(
      _str(j['id']),
      _str(j['odl']),
      _str(j['fase']),
      _str(j['sequenza']),
      _str(j['magazzino']),
      _str(j['padre']),
      _str(j['padre_descrizione']),
      _bool(j['completato']),
      _bool(j['modificato']),
      _bool(j['revisionato']),
      _num(j['data_creazione']).toInt(),
      _num(j['ora_creazione']).toInt(),
      _num(j['data_completamento']).toInt(),
      _num(j['ora_completamento']).toInt(),
      _str(j['utente_completamento']),
      raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [],
    );
  }
}

/// Giacenza di un magazzino (selectGiacenzeInventario.php) per gli utenti CQC.
class GiacenzaPrecarico {
  final String articolo;
  final String descrizione;
  final String um;
  final num qtaGiacente;
  const GiacenzaPrecarico(this.articolo, this.descrizione, this.um, this.qtaGiacente);
}

/// Articolo con le giacenze per magazzino (selectSingoloArticolo.php).
class ArticoloPrecarico {
  final String codice;
  final String descrizione;
  final String unitaMisura;

  /// (magazzino, giacente, impegnato)
  final List<(String, num, num)> magazzini;
  const ArticoloPrecarico(this.codice, this.descrizione, this.unitaMisura, this.magazzini);
}

/// Service di Produzione → Lista Pre-Carico.
/// Porting di Pagine/ListaPrecarico (uploadListaPrecarico, modifyListaPrecarico,
/// getStoriaPrecarico, eliminaListaPrecarico,
/// updateListaPrecaricoSegnaComeRevisionata, convertPDF, trasferimenti con
/// APIMovMagMobileApp) e della creazione dell'Attività per ACEMA.
class ListaPrecaricoService {
  ListaPrecaricoService(this._api);

  final ApiClient _api;

  String get _p => AppConfig.produzioneUrl;
  String get _g => AppConfig.giacenzeUrl;

  /// null se l'articolo non esiste.
  Future<ArticoloPrecarico?> getArticolo(String codice) async {
    dynamic res;
    try {
      res = await _api.postJson('$_g/selectSingoloArticolo',
          data: {'codiceArticolo': codice, 'societa': AuthToken.societa, 'needCompleteInfo': false});
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
    if (res is! Map || res['codice'] == null) return null;
    final mags = <(String, num, num)>[];
    final raw = res['listaMagazzini'];
    if (raw is List) {
      for (final m in raw.whereType<Map>()) {
        mags.add((_str(m['codice']), _num(m['giacente']), _num(m['impegnato'])));
      }
    }
    return ArticoloPrecarico(
        _str(res['codice']), _str(res['descrizione']), _str(res['unitaMisura']), mags);
  }

  /// Padre dell'ODL (checkOdlListaPrelievoMgautAndGetFasi.php); null se non è un ODL.
  Future<(String, String)?> getPadreOdl(String odl) async {
    final res = await _api
        .postJson('$_g/checkOdlListaPrelievoMgautAndGetFasi', data: {'odl': odl});
    if (res is! Map) return null;
    return (_str(res['padre']), _str(res['desc_padre']));
  }

  /// Giacenze del magazzino, ordinate per articolo (selectGiacenzeInventario.php).
  Future<List<GiacenzaPrecarico>> getGiacenze(String magazzino) async {
    final res =
        await _api.postJson('$_g/selectGiacenzeInventario', data: {'magazzino': magazzino});
    if (res is! List) return [];
    final l = res
        .whereType<Map>()
        .map((m) => GiacenzaPrecarico(_str(m['articolo']), _str(m['descrizione']),
            _str(m['um']), _num(m['qta_giacente'])))
        .toList()
      ..sort((a, b) => a.articolo.toUpperCase().compareTo(b.articolo.toUpperCase()));
    return l;
  }

  /// Invio di una nuova lista. Ritorna la sequenza assegnata.
  /// POST produzione/uploadListaPrecarico.php
  Future<String> upload(ListaPrecarico l, String utente) async => (await _api.postText(
        '$_p/uploadListaPrecarico',
        data: {
          'utente': utente.isEmpty ? 'CPR006' : utente,
          'odl': l.odl,
          'fase': l.fase,
          'magazzino': l.magazzino,
          'padre': l.padre,
          'padre_descrizione': l.padreDescrizione,
          'listaPrecarico': (l.righe.map((r) => r.toJson()).toList()),
        },
      ))
          .trim();

  /// Aggiornamento di una lista già inviata e non completata.
  /// POST produzione/modifyListaPrecarico.php
  Future<void> modify(ListaPrecarico l) async {
    await _api.postText('$_p/modifyListaPrecarico', data: {
      'odl': l.odl,
      'fase': l.fase,
      'sequenza': l.sequenza,
      'newListaPrecarico': (l.righe.map((r) => r.toJson()).toList()),
    });
  }

  /// Attività "Inviare Lista Precarico: ..." per ACEMA.
  /// POST avvisi/uploadAvviso.php
  Future<void> creaAttivitaAcema(String nomeLista, String utente, String timest) async {
    await _api.postText('${AppConfig.avvisiUrl}/uploadAvviso', data: {
      'timest': timest,
      'utente': utente,
      'avviso': 'Inviare Lista Precarico: $nomeLista'.replaceAll("'", '`'),
      'dest': 'ACEMA',
      'urgente': '0',
      'scadenza': 0,
    });
  }

  /// POST produzione/getStoriaPrecarico.php {utente}
  Future<List<StoricoPrecarico>> getStorico(String utente) async {
    final res = await _api.postJson('$_p/getStoriaPrecarico', data: {'utente': utente});
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => StoricoPrecarico.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Elimina la lista e l'Attività per ACEMA che la cita.
  /// POST produzione/eliminaListaPrecarico.php + avvisi/eliminaAvviso.php
  Future<void> elimina(StoricoPrecarico s, String nomePortale) async {
    await _api.postText('$_p/eliminaListaPrecarico',
        data: {'odl': s.odl, 'fase': s.fase, 'sequenza': s.sequenza});
    try {
      final avvisi = await _api.postJson('${AppConfig.avvisiUrl}/selectAllAvvisi',
          data: {'utente_creazione_portale': nomePortale});
      if (avvisi is! List) return;
      for (final a in avvisi.whereType<Map>()) {
        if (_str(a['avviso']).contains(s.nome)) {
          await _api.postText('${AppConfig.avvisiUrl}/eliminaAvviso',
              data: {'timest': _str(a['timest']), 'utente': _str(a['utente'])});
          break;
        }
      }
    } catch (_) {
      // Come l'originale: l'Attività è best-effort.
    }
  }

  /// POST produzione/updateListaPrecaricoSegnaComeRevisionata.php {id}
  Future<void> segnaRevisionata(String id) async {
    await _api.postText('$_p/updateListaPrecaricoSegnaComeRevisionata', data: {'id': id});
  }

  /// Converte la tabella HTML in PDF e ritorna l'URL del file.
  /// POST queryDesktop/giacenze/convertPDF.php {table, filename, magazzino}
  Future<String> creaPdf(String table, String testata, String utente) async =>
      (await _api.postText(
        '${AppConfig.queryDesktopUrl}/giacenze/convertPDF',
        data: {
          'table': table,
          'filename': 'Precarico_${testata}_$utente',
          'magazzino': testata,
        },
      ))
          .trim();

  /// Trasferimento sincrono verso il magazzino della lista. Successo: '0043I...'.
  /// POST api/APIMovMagMobileApp.php
  Future<String> trasferisci({
    required String articolo,
    required String daMagazzino,
    required String aMagazzino,
    required num qta,
    required String nota,
    required String utente,
    required String dataOggi,
  }) async =>
      (await _api.postText('${AppConfig.movimentiUrl}/APIMovMagMobileApp', data: {
        'articolo': articolo,
        'datamov': dataOggi,
        'causale': 'TNAV2',
        'damag': daMagazzino,
        'amag': aMagazzino,
        'qta': qta,
        'davano': '',
        'avano': '',
        'odl': '',
        'commessa': '',
        'nota': nota,
        'id': utente,
        'societa': AuthToken.societa,
      }))
          .trim();
}
