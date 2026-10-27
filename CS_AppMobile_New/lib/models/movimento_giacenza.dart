// Modelli Movimento Giacenza — porting di
// www/scripts/Giacenze-Magazzino/Classi/Movimento.js e MovimentoAPI.js.

String _str(dynamic v) => (v ?? '').toString();

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

/// Magazzino in cui è presente l'articolo (origine possibile).
class MagazzinoMovimento {
  final String codice;
  final String vano;
  final num giacente;
  final num impegnato;

  MagazzinoMovimento({
    this.codice = '',
    this.vano = '',
    this.giacente = 0,
    this.impegnato = 0,
  });

  factory MagazzinoMovimento.fromJson(Map<String, dynamic> json) =>
      MagazzinoMovimento(
        codice: _str(json['codice']),
        vano: _str(json['vano']),
        giacente: _num(json['giacente']),
        impegnato: _num(json['impegnato']),
      );
}

/// Magazzino preferenziale (con vano preimpostato).
class MagazzinoPreferenziale {
  final String codice;
  final String vano;
  MagazzinoPreferenziale({this.codice = '', this.vano = ''});

  factory MagazzinoPreferenziale.fromJson(Map<String, dynamic> json) =>
      MagazzinoPreferenziale(
        codice: _str(json['codice']),
        vano: _str(json['vano']),
      );
}

/// ODL possibile per il movimento (con magazzino associato).
class OdlMagazzino {
  final String odl;
  final String magazzino;
  OdlMagazzino({this.odl = '', this.magazzino = ''});

  factory OdlMagazzino.fromJson(Map<String, dynamic> json) => OdlMagazzino(
        odl: _str(json['odl']),
        magazzino: _str(json['mag']),
      );
}

/// Risultato di selectArticoloMagazzini.php.
class ArticoloMovimento {
  final String articoloId;
  final String descrizioneArticolo;
  final String unitaMisura;
  final num pesoLordoBackup;
  final List<MagazzinoMovimento> listaMagazziniArticolo;
  final List<String> listaPossibiliMagazzini;
  final List<MagazzinoPreferenziale> listaMagazziniPreferenziali;
  final List<OdlMagazzino> listaPossibiliOdl;

  ArticoloMovimento({
    this.articoloId = '',
    this.descrizioneArticolo = '',
    this.unitaMisura = '',
    this.pesoLordoBackup = 0,
    this.listaMagazziniArticolo = const [],
    this.listaPossibiliMagazzini = const [],
    this.listaMagazziniPreferenziali = const [],
    this.listaPossibiliOdl = const [],
  });

  bool get trovato => articoloId.isNotEmpty;

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => f(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory ArticoloMovimento.fromJson(Map<String, dynamic> json) {
    final possibiliMag = <String>[];
    final rawMag = json['listaPossibiliMagazzini'];
    if (rawMag is List) {
      for (final m in rawMag) {
        if (m is Map && m['codice'] != null) {
          possibiliMag.add(m['codice'].toString());
        }
      }
    }
    return ArticoloMovimento(
      articoloId: _str(json['articolo_id']),
      descrizioneArticolo: _str(json['descrizioneArticolo']),
      unitaMisura: _str(json['unitaMisura']),
      pesoLordoBackup: _num(json['pesoLordoBackup']),
      listaMagazziniArticolo:
          _list(json['listaMagazziniArticolo'], MagazzinoMovimento.fromJson),
      listaPossibiliMagazzini: possibiliMag,
      listaMagazziniPreferenziali: _list(
          json['listaMagazziniPreferenziali'], MagazzinoPreferenziale.fromJson),
      listaPossibiliOdl:
          _list(json['listaPossibiliOdl'], OdlMagazzino.fromJson),
    );
  }
}

/// Payload del movimento per WriteMovimentiMultipliAPI (MovimentoAPI.js).
class MovimentoApi {
  final String idApi;
  final String causale;
  final String societa;
  final String utente;
  final String articolo;
  final num qta;
  final String damag;
  final String davano;
  final String amag;
  final String avano;
  final String odl;
  final String commessa;
  final String ambiente;
  final String nota;
  final String sezione;

  // Campi extra per le liste di prelievo automatico (mgaut01).
  final String rifprel;
  final String subrifprel;
  final String seqprel;
  final String seq;

  MovimentoApi({
    required this.idApi,
    this.causale = 'TNAV2',
    required this.societa,
    required this.utente,
    required this.articolo,
    required this.qta,
    this.damag = '',
    this.davano = '',
    this.amag = '',
    this.avano = '',
    this.odl = '',
    this.commessa = '',
    this.ambiente = 'PRODUZIONE',
    this.nota = '',
    this.sezione = 'mov_singolo',
    this.rifprel = '',
    this.subrifprel = '',
    this.seqprel = '',
    this.seq = '',
    this.extra = const {},
  });

  /// Proprietà aggiuntive che sovrascrivono quelle di default in [toJson]
  /// (es. dtrun/hrrun/descarticolo/... per mancanti e prelievi).
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => {
        ..._baseJson(),
        ...extra,
      };

  Map<String, dynamic> _baseJson() => {
        'id_api': idApi,
        'causale': causale,
        'societa': societa,
        'utente': utente,
        'articolo': articolo,
        'qta': qta,
        'damag': damag,
        'davano': davano,
        'amag': amag,
        'avano': avano,
        'odl': odl,
        'commessa': commessa,
        'ambiente': ambiente,
        'nota': nota,
        'sezione': sezione,
        // Campi extra previsti dalla classe MovimentoAPI (liste di prelievo)
        'rifprel': rifprel,
        'subrifprel': subrifprel,
        'seqprel': seqprel,
        'seq': seq,
        'dtrun': '',
        'hrrun': '',
        'descarticolo': '',
        'padre': '',
        'des_padre': '',
        'pesol': '',
        'desccolore': '',
        'fase': '',
        'fabbdate_integer': '',
        'nomefornlastdispo': '',
        'bollanolastdispo': '',
        'bolladtlastdispo': '',
        'umis': '',
        'descrizionefase': '',
        'pos': 0,
      };
}

/// Esito di un movimento ricevuto via SSE (MovimentiMagazzinoSSE.php).
class EsitoMovimento {
  final String id;
  final String nomeLista;
  final String response;
  final String sezione;
  final int movimentiCompletati;
  final int movimentiTotali;

  EsitoMovimento({
    this.id = '',
    this.nomeLista = '',
    this.response = '',
    this.sezione = '',
    this.movimentiCompletati = 0,
    this.movimentiTotali = 0,
  });

  bool get completato =>
      movimentiTotali > 0 && movimentiCompletati >= movimentiTotali;

  /// Successo = la risposta Diapason inizia con '0043I'.
  bool get isSuccess => response.trim().length >= 5 &&
      response.trim().substring(0, 5) == '0043I';

  factory EsitoMovimento.fromJson(Map<String, dynamic> json) => EsitoMovimento(
        id: _str(json['id']),
        nomeLista: _str(json['nome_lista']),
        response: _str(json['response']),
        sezione: _str(json['sezione']),
        movimentiCompletati: _num(json['movimenti_completati']).toInt(),
        movimentiTotali: _num(json['movimenti_totali']).toInt(),
      );
}
