import '../../core/config.dart';
import '../../core/network/api_client.dart';

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();

/// ODL/fase su cui impegnare (selectImpegniOdl.php) — classe ImpegnoOdl.
class ImpegnoOdl {
  final String odl;
  final String padre;
  final String descPadre;
  final String fase;
  final String descFase;
  String magazzinoDestinazione; // 'Nessuno' se vuoto
  final String responsabile;
  List<ArticoloImpegno> listaArticoli = [];

  ImpegnoOdl({
    required this.odl,
    this.padre = '',
    this.descPadre = '',
    required this.fase,
    this.descFase = '',
    this.magazzinoDestinazione = 'Nessuno',
    this.responsabile = '',
  });

  /// Fasi 006x: le quantità sono negative.
  bool get isFase006 => fase.startsWith('006');
  bool get isFase0027o0034 => fase == '0027' || fase == '0034';

  bool get magazzinoValido =>
      magazzinoDestinazione.isNotEmpty && magazzinoDestinazione != 'Nessuno';

  factory ImpegnoOdl.fromJson(Map<String, dynamic> j) {
    final mag = _str(j['mag_des']);
    return ImpegnoOdl(
      odl: _str(j['odl']),
      padre: _str(j['padre']),
      descPadre: _str(j['desc_padre']),
      fase: _str(j['fase']),
      descFase: _str(j['desc_fase']),
      magazzinoDestinazione: mag.isEmpty ? 'Nessuno' : mag,
      responsabile: _str(j['responsabile']),
    );
  }
}

/// Articolo già impegnato sull'ODL (addArticoliImpegnoOdl.php).
class ArticoloImpegno {
  final String codice;
  final String descrizione;
  final String um;
  final num qta;
  final String fase;
  const ArticoloImpegno(this.codice, this.descrizione, this.um, this.qta, this.fase);

  factory ArticoloImpegno.fromJson(Map<String, dynamic> j) => ArticoloImpegno(
        _str(j['codice']),
        _str(j['descrizione']),
        _str(j['um']),
        _num(j['qta']),
        _str(j['fase']),
      );
}

/// Articolo da impegnare (selectSingoloArticolo.php).
class ArticoloDaImpegnare {
  final String codice;
  final String descrizione;
  final String unitaMisura;
  const ArticoloDaImpegnare(this.codice, this.descrizione, this.unitaMisura);
}

/// Chiavi dell'Attività legata a un impegno (getAttivitaKeysFromImpegnoOdl.php).
class ChiaviAttivita {
  final String timest;
  final String utente;
  const ChiaviAttivita(this.timest, this.utente);
}

/// Service di Produzione → Impegno ODL.
/// Porting di Produzione-Odl/Classi/Query.js (querySelectImpegnoOdl,
/// getArticoloFromDB), Pagine/ImpegnoOdl/EventHandlers.js e delle funzioni
/// Attività usate da qui (ajaxInviaAvviso, ajaxModificaAvviso).
class ImpegnoOdlService {
  ImpegnoOdlService(this._api);

  final ApiClient _api;

  String get _p => AppConfig.produzioneUrl;
  String get _a => AppConfig.avvisiUrl;

  /// POST produzione/selectImpegniOdl.php {codiceOdl_Padre_Mag, fase, utente}
  Future<List<ImpegnoOdl>> selectImpegni(String codice, String fase, String utente) async {
    final res = await _api.postJson('$_p/selectImpegniOdl',
        data: {'codiceOdl_Padre_Mag': codice, 'fase': fase, 'utente': utente});
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ImpegnoOdl.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST produzione/addArticoliImpegnoOdl.php {odl, fase, magazzino}
  Future<List<ArticoloImpegno>> getArticoli(ImpegnoOdl i) async {
    final res = await _api.postJson('$_p/addArticoliImpegnoOdl',
        data: {'odl': i.odl, 'fase': i.fase, 'magazzino': i.magazzinoDestinazione});
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ArticoloImpegno.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Tipo articolo ('N' = kanban, non impegnabile in fase 0027).
  /// POST casagrande-app-web/.../getTipoArticolo.php {codice}
  Future<String> getTipoArticolo(String codice) async {
    final res = await _api.postJson(
      '${AppConfig.produzioneUrl}/getTipoArticolo',
      data: {'codice': codice},
    );
    return res is Map ? _str(res['tipoArticolo']) : '';
  }

  /// null se l'articolo non esiste.
  /// POST giacenze/selectSingoloArticolo.php {codiceArticolo, societa, needCompleteInfo:false}
  Future<ArticoloDaImpegnare?> getArticolo(String codice) async {
    dynamic res;
    try {
      res = await _api.postJson('${AppConfig.giacenzeUrl}/selectSingoloArticolo',
          data: {'codiceArticolo': codice, 'societa': AuthToken.societa, 'needCompleteInfo': false});
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
    if (res is! Map || res['codice'] == null) return null;
    return ArticoloDaImpegnare(
        _str(res['codice']), _str(res['descrizione']), _str(res['unitaMisura']));
  }

  /// True se almeno un magazzino (MGAUT00, MGAUT10, MISK) ha [qta] disponibile.
  /// POST produzione/checkImpegnoGiacenzaArticolo.php {codiceArticolo}
  Future<bool> giacenzaDisponibile(String codice, num qta) async {
    final res = await _api.postJson('$_p/checkImpegnoGiacenzaArticolo',
        data: {'codiceArticolo': codice});
    if (res is! List) return false;
    return res.whereType<Map>().any((m) => _num(m['disponibile']) >= qta);
  }

  /// POST produzione/returnMagazzinoFromImpegnoOdl.php {odl, fase}
  Future<String> returnMagazzino(String odl, String fase) async =>
      (await _api.postText('$_p/returnMagazzinoFromImpegnoOdl',
              data: {'odl': odl, 'fase': fase}))
          .trim();

  /// POST giacenze/checkMagazzinoExists.php {magazzino}
  Future<bool> checkMagazzinoExists(String magazzino) async {
    // Il C# risponde 400 a magazzino vuoto: qui vale "non esiste".
    if (magazzino.trim().isEmpty) return false;
    final res = await _api.postJson('${AppConfig.giacenzeUrl}/checkMagazzinoExists',
        data: {'magazzino': magazzino});
    return res == true || res == 1 || res == '1';
  }

  /// Impegno su Diapason. Successo: '0000 OPERAZIONE ESEGUITA'.
  /// POST http://10.0.2.1/applicazioni/produzione/UpdateSOSACPN.php {parametri}
  Future<String> updateSOSACPN(String parametri) async => (await _api.postText(
          '${AppConfig.produzioneUrl}/updateSOSACPN',
          data: {'parametri': parametri}))
      .trim();

  /// Statistiche fase 0027: write/deleteInserimentoFase0027.php
  Future<void> aggiornaStatistica0027({
    required bool elimina,
    required String articolo,
    required String odl,
    required String padre,
    required String fase,
    required String magazzino,
    required String responsabile,
    required num qta,
  }) async {
    final script = elimina ? 'deleteInserimentoFase0027' : 'writeInserimentoFase0027';
    await _api.postText('$_p/$script', data: {
      'articolo': articolo,
      'odl': odl,
      'padre': padre,
      'fase': fase,
      'magazzino': magazzino,
      'responsabile': responsabile,
      'qta': qta,
    });
  }

  /// POST produzione/sendImpegniEmail.php {emailTarget, titolo, messaggio, nomeUtente}
  Future<void> sendEmail({
    required String emailTarget,
    required String titolo,
    required String messaggio,
    required String nomeUtente,
  }) async {
    await _api.postText('$_p/sendImpegniEmail', data: {
      'emailTarget': emailTarget,
      'titolo': titolo,
      'messaggio': messaggio,
      'nomeUtente': nomeUtente,
    });
  }

  // ---------------------------------------------------------------------------
  // Attività
  // ---------------------------------------------------------------------------

  /// POST avvisi/uploadAvviso.php
  Future<void> uploadAvviso({
    required String timest,
    required String utente,
    required String avviso,
    required String dest,
  }) async {
    await _api.postText('$_a/uploadAvviso', data: {
      'timest': timest,
      'utente': utente,
      'avviso': avviso.replaceAll("'", '`'),
      'dest': dest,
      'urgente': '0',
      'scadenza': 0,
    });
  }

  /// Collega l'Attività all'impegno. true se 'uploaded'.
  /// POST avvisi/writeAttivitaSezione.php
  Future<bool> writeAttivitaSezione({
    required String timest,
    required String utente,
    required String articolo,
    required String odl,
    required String fase,
    required num qta,
    required String magazzino,
  }) async {
    final res = await _api.postText('$_a/writeAttivitaSezione', data: {
      'timest': timest,
      'utente': utente,
      'sezione': 'impegno_odl',
      'articolo': articolo,
      'odl': odl,
      'fase': fase,
      'qta': qta,
      'magazzino': magazzino,
      'custom_variable': '',
    });
    return res.trim() == 'uploaded';
  }

  /// null se nessuna Attività è legata all'impegno.
  /// POST avvisi/getAttivitaKeysFromImpegnoOdl.php
  Future<ChiaviAttivita?> getChiaviAttivita({
    required String articolo,
    required String odl,
    required String fase,
    required String magazzino,
    required num qta,
    required String operazione,
  }) async {
    final res = await _api.postJson('$_a/getAttivitaKeysFromImpegnoOdl', data: {
      'sezione': 'impegno_odl',
      'articolo': articolo,
      'odl': odl,
      'fase': fase,
      'magazzino': magazzino,
      'qta': qta,
      'operazione': operazione,
    });
    if (res is! Map) return null;
    return ChiaviAttivita(_str(res['timest']), _str(res['utente']));
  }

  /// Attività grezza (timest, avviso, utente, attivo, urgente, dest, scadenza, completato).
  /// POST avvisi/selectSingoloAvviso.php {timest, utente}
  Future<Map<String, dynamic>?> selectSingoloAvviso(ChiaviAttivita k) async {
    final res = await _api
        .postJson('$_a/selectSingoloAvviso', data: {'timest': k.timest, 'utente': k.utente});
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  /// POST avvisi/modificaAvviso.php
  Future<void> modificaAvviso({
    required String timest,
    required String utente,
    required String avviso,
    required String dest,
    required String urgente,
    required String scadenza,
  }) async {
    await _api.postText('$_a/modificaAvviso', data: {
      'timest': timest,
      'utente': utente,
      'avviso': avviso.replaceAll("'", '`'),
      'dest': dest,
      'urgente': urgente,
      'scadenza': scadenza,
    });
  }
}
