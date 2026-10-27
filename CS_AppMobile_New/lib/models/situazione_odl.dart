import '../core/utils/date_format.dart';

/// Modelli Situazione ODL — porting di
/// www/scripts/Produzione-Odl/Classi/SituazioneOdl.js +
/// la logica di suddivisione in sezioni di Query.js
/// (querySelectSituazioneOdl).

String fmtDateOdl(String raw) {
  final f = formatData(raw);
  return f.isEmpty ? '-' : f;
}

String _dataPadreFmt(String raw) {
  final f = formatData(raw);
  return f.isEmpty ? raw : f;
}

num _toNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();

/// Sezione di appartenenza di una riga ODL.
enum SezioneOdl { rep, prel, oda, odl, mancanti }

extension SezioneOdlLabel on SezioneOdl {
  String get label {
    switch (this) {
      case SezioneOdl.rep:
        return 'REP';
      case SezioneOdl.prel:
        return 'PREL';
      case SezioneOdl.oda:
        return 'ODA';
      case SezioneOdl.odl:
        return 'ODL';
      case SezioneOdl.mancanti:
        return 'MANCANTI';
    }
  }
}

/// Risultato della ricerca padre/odl (selectSituazioneCheckOdl.php).
class CheckOdl {
  final String odl;
  final String scadenza; // YYYY-MM-DD
  CheckOdl({this.odl = '', this.scadenza = ''});

  factory CheckOdl.fromJson(Map<String, dynamic> json) => CheckOdl(
        odl: _str(json['odl']),
        scadenza: _str(json['scadenza']),
      );

  String get scadenzaFmt {
    final f = formatData(scadenza);
    return f.isEmpty ? '-' : f;
  }
}

/// Riga della situazione ODL (selectSituazioneOdl.php), già assegnata
/// a una sezione (REP/PREL/ODA/ODL/MANCANTI).
class SituazioneOdlRiga {
  final SezioneOdl sezione;

  // Comuni
  final String odl;
  final String padre;
  final String descPadre;
  final String statoPadre;
  final num qtaResPadre;
  final String dataPadre;

  final String articolo;
  final String descArticolo;
  final String fase;
  final String stato;
  final String statoPick;
  final String magazzino;
  final num qtaRes;
  final String note;

  // REP
  final num giacMagazzino;

  // PREL
  final num giacDispo;
  final num inTransito;
  final String magazzinoDispo;

  // ODA
  final num odaImp;
  final String oda;
  final String fornitore;
  final String dataOrdine;
  final String dtconf;

  // ODL
  final num odlImp;
  final String odlFiglio;
  final String dataOdlFiglio;

  SituazioneOdlRiga({
    required this.sezione,
    this.odl = '',
    this.padre = '',
    this.descPadre = '',
    this.statoPadre = '',
    this.qtaResPadre = 0,
    this.dataPadre = '',
    this.articolo = '',
    this.descArticolo = '',
    this.fase = '',
    this.stato = '',
    this.statoPick = '',
    this.magazzino = '',
    this.qtaRes = 0,
    this.note = '',
    this.giacMagazzino = 0,
    this.giacDispo = 0,
    this.inTransito = 0,
    this.magazzinoDispo = '',
    this.odaImp = 0,
    this.oda = '',
    this.fornitore = '',
    this.dataOrdine = '',
    this.dtconf = '',
    this.odlImp = 0,
    this.odlFiglio = '',
    this.dataOdlFiglio = '',
  });

  bool get haNota => note.trim().isNotEmpty;

  /// Crea una riga assegnata a [sezione] a partire dal JSON grezzo.
  factory SituazioneOdlRiga.fromJson(
    Map<String, dynamic> json,
    SezioneOdl sezione,
  ) {
    var magDispo = _str(json['magazzinoDispo']);
    if (json['magazzinoDispo'] == null) {
      magDispo = _str(json['magazzinoTransitoDispo']);
    }
    var fornitore = _str(json['fornitore']);
    if (json['fornitore'] == null) fornitore = '-';

    return SituazioneOdlRiga(
      sezione: sezione,
      odl: _str(json['odl']),
      padre: _str(json['padre']),
      descPadre: _str(json['descPadre']),
      statoPadre: _str(json['statoPadre']),
      qtaResPadre: _toNum(json['qtaResPadre']),
      dataPadre: _str(json['dataPadre']),
      articolo: _str(json['articolo']),
      descArticolo: _str(json['descArticolo']),
      fase: _str(json['fase']),
      stato: _str(json['stato']),
      statoPick: _str(json['statoPick']),
      magazzino: _str(json['magazzino']),
      qtaRes: _toNum(json['qtaRes']),
      note: _str(json['note']),
      giacMagazzino: _toNum(json['giacMagazzino']),
      giacDispo: _toNum(json['giacDispo']),
      inTransito: _toNum(json['inTransito']),
      magazzinoDispo: magDispo,
      odaImp: _toNum(json['odaImp']),
      oda: _str(json['oda']),
      fornitore: fornitore,
      dataOrdine: _str(json['dataOrdine']),
      dtconf: _str(json['dtconf']),
      odlImp: _toNum(json['odlImp']),
      odlFiglio: _str(json['odlFiglio']),
      dataOdlFiglio: _str(json['dataOdlFiglio']),
    );
  }

  /// Stringa "ordine" mostrata nella colonna centrale (come l'originale).
  String get ordine {
    switch (sezione) {
      case SezioneOdl.rep:
        return magazzino;
      case SezioneOdl.prel:
        return magazzinoDispo;
      case SezioneOdl.oda:
        return oda;
      case SezioneOdl.odl:
        return odlFiglio;
      case SezioneOdl.mancanti:
        return '';
    }
  }

  /// Valore "Res - Gia/Dis/Imp" mostrato nella colonna di destra.
  String get dettaglioQuantita {
    final res = 'Res: ${_n(qtaRes)}';
    switch (sezione) {
      case SezioneOdl.rep:
        return '$res\nGia: ${_n(giacMagazzino)}';
      case SezioneOdl.prel:
        return '$res\nDis: ${_n(giacDispo)}';
      case SezioneOdl.oda:
        return '$res\nImp: ${_n(odaImp)}';
      case SezioneOdl.odl:
        return '$res\nImp: ${_n(odlImp)}';
      case SezioneOdl.mancanti:
        return res;
    }
  }

  static String _n(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }
}

/// Aggregato della situazione di un ODL (intestazione padre + righe).
class SituazioneOdlResult {
  final String odl;
  final String padre;
  final String descPadre;
  final String statoPadre;
  final num qtaResPadre;
  final String dataPadre; // dd/MM/yy
  final List<SituazioneOdlRiga> righe;

  SituazioneOdlResult({
    this.odl = '',
    this.padre = '',
    this.descPadre = '',
    this.statoPadre = '',
    this.qtaResPadre = 0,
    this.dataPadre = '',
    this.righe = const [],
  });

  bool get isEmpty => righe.isEmpty;

  List<SezioneOdl> get sezioniPresenti {
    final set = <SezioneOdl>{};
    for (final r in righe) {
      set.add(r.sezione);
    }
    final ordine = [
      SezioneOdl.rep,
      SezioneOdl.prel,
      SezioneOdl.oda,
      SezioneOdl.odl,
      SezioneOdl.mancanti,
    ];
    return ordine.where(set.contains).toList();
  }

  int conteggio(SezioneOdl? sezione) {
    if (sezione == null) return righe.length;
    return righe.where((r) => r.sezione == sezione).length;
  }

  /// Costruisce il risultato a partire dalla risposta grezza, replicando
  /// la suddivisione in sezioni di querySelectSituazioneOdl.
  factory SituazioneOdlResult.fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return SituazioneOdlResult();

    final first = rows.first;
    var maxData = ''; // confronto lessicografico su YYYY-MM-DD
    final righe = <SituazioneOdlRiga>[];

    for (final row in rows) {
      final data = _str(row['dataPadre']);
      if (data.compareTo(maxData) > 0) maxData = data;

      if (_toNum(row['qtaRes']) <= 0) continue;

      var sezioneFound = false;

      // REP
      if (_toNum(row['giacMagazzino']) > 0) {
        sezioneFound = true;
        righe.add(SituazioneOdlRiga.fromJson(row, SezioneOdl.rep));
      }
      // PREL
      if (_toNum(row['giacDispo']) > 0 || _toNum(row['inTransito']) > 0) {
        sezioneFound = true;
        righe.add(SituazioneOdlRiga.fromJson(row, SezioneOdl.prel));
      }
      // ODA
      if (_toNum(row['odaImp']) > 0) {
        sezioneFound = true;
        righe.add(SituazioneOdlRiga.fromJson(row, SezioneOdl.oda));
      }
      // ODL
      if (_toNum(row['odlImp']) > 0) {
        sezioneFound = true;
        righe.add(SituazioneOdlRiga.fromJson(row, SezioneOdl.odl));
      }
      // MANCANTI
      if (!sezioneFound) {
        righe.add(SituazioneOdlRiga.fromJson(row, SezioneOdl.mancanti));
      }
    }

    // Sort per articolo (come default dell'originale: sort = 'articolo').
    righe.sort((a, b) {
      final art = a.articolo.toUpperCase().compareTo(b.articolo.toUpperCase());
      if (art != 0) return art;
      // sezione decrescente come nell'originale
      return b.sezione.label.compareTo(a.sezione.label);
    });

    return SituazioneOdlResult(
      odl: _str(first['odl']),
      padre: _str(first['padre']),
      descPadre: _str(first['descPadre']),
      statoPadre: _str(first['statoPadre']),
      qtaResPadre: _toNum(first['qtaResPadre']),
      dataPadre: maxData.isNotEmpty ? _dataPadreFmt(maxData) : '-',
      righe: righe,
    );
  }
}
