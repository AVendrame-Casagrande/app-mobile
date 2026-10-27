import 'package:intl/intl.dart';

import '../core/utils/date_format.dart';

// Modelli Mancanti/Prelievi — porting di
// www/scripts/Giacenze-Magazzino/Classi/MancanteCorrente.js.

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

int _int(dynamic v) => _num(v).toInt();
String _str(dynamic v) => (v ?? '').toString();

String _fmtData(dynamic raw) => formatData(raw);

/// Data in formato D/M/YY (moment(..., "YYYY-MM-DD").format('D/M/YY')),
/// come viene inviata nei movimenti dell'originale.
String _fmtDMYY(dynamic raw) {
  final s = _str(raw).trim();
  if (s.isEmpty) return '';
  for (final f in ['yyyy-MM-dd', 'yyyyMMdd']) {
    try {
      return DateFormat('d/M/yy').format(DateFormat(f).parseStrict(s));
    } catch (_) {}
  }
  return s;
}

/// dtrun/hrrun dell'ultimo aggiornamento del DB mancanti.
class DataLogMancanti {
  final String dtrun;
  final String hrrun;
  DataLogMancanti({this.dtrun = '', this.hrrun = ''});

  factory DataLogMancanti.fromJson(Map<String, dynamic> json) => DataLogMancanti(
        dtrun: _str(json['dtrun']),
        hrrun: _str(json['hrrun']),
      );

  bool sameAs(DataLogMancanti o) => dtrun == o.dtrun && hrrun == o.hrrun;

  /// Ora dell'aggiornamento in formato HH:mm:ss.
  String get oraFormattata {
    final h = hrrun.padLeft(6, '0');
    if (h.length != 6) return hrrun;
    return '${h.substring(0, 2)}:${h.substring(2, 4)}:${h.substring(4, 6)}';
  }
}

class ArticoloMancante {
  final String articolo;
  final String descArticolo;
  final String magazzinoImpegno;
  final String odl;
  final String padre;
  final String desPadre;
  final String magdispo;
  final String vanodispo;
  final num giacdispo;
  final String fase;
  final String descrizioneFase;
  final String fabbdate;
  final num prioprel;
  final String stato;
  final String statopick;
  final String umis;
  final num pesol;
  final String descColore;
  final String iscritico;
  final String nomefornlastdispo;
  final String fornlastdispo;
  final String bollanolastdispo;
  final String bolladtlastdispo; // D/M/YY
  final int fabbdateInteger;
  final int pos; // posizione riga ODV (0 per gli ODL)
  bool selezionato;

  ArticoloMancante({
    this.articolo = '',
    this.descArticolo = '',
    this.magazzinoImpegno = '',
    this.odl = '',
    this.padre = '',
    this.desPadre = '',
    this.magdispo = '',
    this.vanodispo = '',
    this.giacdispo = 0,
    this.fase = '',
    this.descrizioneFase = '',
    this.fabbdate = '',
    this.prioprel = 0,
    this.stato = '',
    this.statopick = '',
    this.umis = '',
    this.pesol = 0,
    this.descColore = '',
    this.iscritico = '',
    this.nomefornlastdispo = '',
    this.fornlastdispo = '',
    this.bollanolastdispo = '',
    this.bolladtlastdispo = '',
    this.fabbdateInteger = 0,
    this.pos = 0,
    this.selezionato = false,
  });

  bool get isCritico => iscritico == '1' || iscritico == 'S';

  /// Nell'originale le righe con iscritico === '0' sono nascoste finché
  /// non si attiva la visualizzazione dei "non critici".
  bool get isNonCritico => iscritico == '0';

  /// Le righe da questi magazzini non possono essere selezionate.
  static const magazziniNonSelezionabili = {'MGAUT01', 'MISP001', 'MISP002'};
  bool get selezionabile => !magazziniNonSelezionabili.contains(magdispo);

  /// Chiave usata per riconoscere un mancante già inviato
  /// (isArticoloInviato: articolo + odl + fase + pos).
  bool corrispondeA(Map<String, dynamic> inviato) =>
      articolo == _str(inviato['articolo']) &&
      odl == _str(inviato['odl']) &&
      fase == _str(inviato['fase']) &&
      pos == _int(inviato['pos']);

  factory ArticoloMancante.fromJson(Map<String, dynamic> json) {
    final comuni = (
      nomeforn: _str(json['nomefornlastdispo']),
      forn: _str(json['fornlastdispo']),
      bollano: _str(json['bollanolastdispo']),
      bolladt: _fmtDMYY(json['bolladtlastdispo']),
    );
    // Supporta sia il formato ODL sia il formato ODV (campi diversi):
    // porting di convertArticoloMancanteODVtoODL().
    final isOdv = json['odl'] == null && json['numero'] != null;
    if (isOdv) {
      return ArticoloMancante(
        articolo: _str(json['articolo']),
        descArticolo: _str(json['descarticolo']),
        magazzinoImpegno: _str(json['magazzino']),
        odl: _str(json['numero']),
        padre: _str(json['cliente']),
        desPadre: _str(json['nomecliente']),
        magdispo: _str(json['magdispo']),
        vanodispo: _str(json['vanodispo']),
        giacdispo: _num(json['giacdispo']),
        fabbdate: _fmtData(json['dtcons']),
        prioprel: _num(json['prioprel']),
        iscritico: '1',
        umis: _str(json['umis']),
        nomefornlastdispo: comuni.nomeforn,
        fornlastdispo: comuni.forn,
        bollanolastdispo: comuni.bollano,
        bolladtlastdispo: comuni.bolladt,
        fabbdateInteger: _int(json['dtcons']),
        pos: _int(json['pos']),
      );
    }
    return ArticoloMancante(
      articolo: _str(json['articolo']),
      descArticolo: _str(json['descarticolo']),
      magazzinoImpegno: _str(json['magazzinoimpegno']),
      odl: _str(json['odl']),
      padre: _str(json['padre']),
      desPadre: _str(json['des_padre']),
      magdispo: _str(json['magdispo']),
      vanodispo: _str(json['vanodispo']),
      giacdispo: _num(json['giacdispo']),
      fase: _str(json['fase']),
      descrizioneFase: _str(json['descrizionefase']),
      fabbdate: _fmtData(json['fabbdate']),
      prioprel: _num(json['prioprel']),
      stato: _str(json['stato']),
      statopick: _str(json['statopick']),
      umis: _str(json['umis']),
      pesol: _num(json['pesol']),
      descColore: _str(json['desccolore']),
      iscritico: _str(json['iscritico']),
      nomefornlastdispo: comuni.nomeforn,
      fornlastdispo: comuni.forn,
      bollanolastdispo: comuni.bollano,
      bolladtlastdispo: comuni.bolladt,
      // Come parseInt() dell'originale: solo le cifre iniziali.
      fabbdateInteger:
          _int(RegExp(r'^\d+').stringMatch(_str(json['fabbdate'])) ?? '0'),
      pos: 0,
    );
  }
}

/// Risultato di selectMancantiDaMag.php.
class MancantiResult {
  final DataLogMancanti dataLog;
  final List<ArticoloMancante> lista;
  final List<ArticoloMancante> listaAut;

  MancantiResult({
    DataLogMancanti? dataLog,
    List<ArticoloMancante>? lista,
    List<ArticoloMancante>? listaAut,
  })  : dataLog = dataLog ?? DataLogMancanti(),
        lista = lista ?? [],
        listaAut = listaAut ?? [];

  static List<ArticoloMancante> _parseList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ArticoloMancante.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory MancantiResult.fromJson(Map<String, dynamic> json) {
    final dl = json['dataLog'];
    return MancantiResult(
      dataLog: dl is Map
          ? DataLogMancanti.fromJson(Map<String, dynamic>.from(dl))
          : DataLogMancanti(),
      lista: _parseList(json['listaArticoliMancanti']),
      listaAut: _parseList(json['listaArticoliMancantiAUT']),
    );
  }
}

/// Movimento già inviato (getStoriaMovimento.php) — tab "Inviati".
class StoricoMancante {
  final String articolo;
  final String descArticolo;
  final String magazzinoImpegno; // mag_des
  final String odl;
  final String padre;
  final String magdispo; // mag_ori
  final String vanodispo; // vano
  final num qta;
  final String fase;
  final String umis;
  final String utenteMov;
  int statoMov; // 0 = in corso, 1 = errore, 2 = completato
  final int dataSalvataggio; // yyyyMMdd
  final int oraSalvataggio; // HHmmss
  final int dtrun;
  final int hrrun;

  StoricoMancante({
    this.articolo = '',
    this.descArticolo = '',
    this.magazzinoImpegno = '',
    this.odl = '',
    this.padre = '',
    this.magdispo = '',
    this.vanodispo = '',
    this.qta = 0,
    this.fase = '',
    this.umis = '',
    this.utenteMov = '',
    this.statoMov = 0,
    this.dataSalvataggio = 0,
    this.oraSalvataggio = 0,
    this.dtrun = 0,
    this.hrrun = 0,
  });

  factory StoricoMancante.fromJson(Map<String, dynamic> json) => StoricoMancante(
        articolo: _str(json['articolo']),
        descArticolo: _str(json['desc_articolo']),
        magazzinoImpegno: _str(json['mag_des']),
        odl: _str(json['odl']),
        padre: _str(json['padre']),
        magdispo: _str(json['mag_ori']),
        vanodispo: _str(json['vano']),
        qta: _num(json['qta']),
        fase: _str(json['fase']),
        umis: _str(json['um']),
        utenteMov: _str(json['utente_mov']),
        statoMov: _int(json['stato_mov']),
        dataSalvataggio: _int(json['data_salvataggio']),
        oraSalvataggio: _int(json['ora_salvataggio']),
        dtrun: _int(json['dtrun']),
        hrrun: _int(json['hrrun']),
      );

  bool get isOggi =>
      dataSalvataggio == int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));

  String get iconaStato => switch (statoMov) {
        0 => '⏳',
        1 => '❌',
        2 => '✔️',
        _ => '',
      };

  /// Ora (oggi) o data (storico) del salvataggio.
  String get dataDisplay {
    if (isOggi) {
      final o = oraSalvataggio.toString().padLeft(6, '0');
      return '${o.substring(0, 2)}:${o.substring(2, 4)}:${o.substring(4, 6)}';
    }
    final d = dataSalvataggio.toString();
    if (d.length != 8) return d;
    return '${d.substring(6, 8)}/${d.substring(4, 6)}/${d.substring(2, 4)}';
  }
}

/// ODL/ODV proposto per i prelievi (getOdlListFromMagDest.php).
class OdlPrelievo {
  final String odl;
  final String padre;
  final String desPadre;
  const OdlPrelievo(this.odl, this.padre, this.desPadre);

  bool get isOdv => odl.startsWith('OM') || odl.startsWith('OR');

  factory OdlPrelievo.fromJson(Map<String, dynamic> json) => OdlPrelievo(
        _str(json['odl']),
        _str(json['padre']),
        _str(json['des_padre']),
      );
}
