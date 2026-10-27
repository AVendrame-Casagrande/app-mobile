import 'package:intl/intl.dart';

/// Modelli Situazione ODV — porting di www/scripts/SituazioneOdv + Classi/SituazioneOdv.js.

/// Stato di una singola riga d'ordine.
enum StatoOdv { disponibile, disponibilePrel, inOda, inOdl, mancante, sconosciuto }

StatoOdv statoOdvFromString(String s) {
  switch (s) {
    case 'disponibile':
      return StatoOdv.disponibile;
    case 'disponibile_prel':
      return StatoOdv.disponibilePrel;
    case 'in_oda':
      return StatoOdv.inOda;
    case 'in_odl':
      return StatoOdv.inOdl;
    case 'mancante':
      return StatoOdv.mancante;
    default:
      return StatoOdv.sconosciuto;
  }
}

/// Una testata d'ordine (OR oppure OM) con le sue righe.
class OdvLista {
  final String numero;
  final String causale;
  final String dtcons; // raw YYYYMMDD
  final String cliente;
  final String nomecliente;
  final List<OdvRiga> righe;

  OdvLista({
    this.numero = '',
    this.causale = '',
    this.dtcons = '',
    this.cliente = '',
    this.nomecliente = '',
    this.righe = const [],
  });

  static final DateFormat _in = DateFormat('yyyyMMdd');
  static final DateFormat _out = DateFormat('dd/MM/yyyy');

  int get dtconsInteger => int.tryParse(dtcons) ?? 0;

  String get dataConsegnaFmt {
    try {
      return _out.format(_in.parse(dtcons));
    } catch (_) {
      return dtcons;
    }
  }

  /// True se almeno una riga non è completamente disponibile.
  bool get haProblemi => righe.any((r) => r.haProblemi);

  factory OdvLista.fromJson(Map<String, dynamic> json) {
    final righeRaw = json['righe'];
    final righe = <OdvRiga>[];
    if (righeRaw is List) {
      for (final r in righeRaw) {
        if (r is Map) {
          righe.add(OdvRiga.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }
    return OdvLista(
      numero: (json['numero'] ?? '').toString(),
      causale: (json['causale'] ?? '').toString(),
      dtcons: (json['dtcons'] ?? '').toString(),
      cliente: (json['cliente'] ?? '').toString(),
      nomecliente: (json['nomecliente'] ?? '').toString(),
      righe: righe,
    );
  }
}

/// Una riga d'ordine. Può avere più stati contemporaneamente (stato_odv array).
class OdvRiga {
  final String pos;
  final String articolo;
  final String descarticolo;
  final String magazzino;
  final String giacmag;
  final String qtaape;
  final String magdispo;
  final String giacdispo;
  final String psdesdt; // data consegna ODA (YYYYMMDD)
  final String numsoda;
  final String qtaisoda;
  final String qtafab;
  final String duedate; // data consegna ODL (YYYYMMDD)
  final String numodl;
  final String qtaiodl;
  final String qtaMancante;
  final List<StatoOdv> statoOdv;

  OdvRiga({
    this.pos = '',
    this.articolo = '',
    this.descarticolo = '',
    this.magazzino = '',
    this.giacmag = '',
    this.qtaape = '',
    this.magdispo = '',
    this.giacdispo = '',
    this.psdesdt = '',
    this.numsoda = '',
    this.qtaisoda = '',
    this.qtafab = '',
    this.duedate = '',
    this.numodl = '',
    this.qtaiodl = '',
    this.qtaMancante = '',
    this.statoOdv = const [],
  });

  static final DateFormat _in = DateFormat('yyyyMMdd');
  static final DateFormat _out = DateFormat('dd/MM/yyyy');

  static String _fmtDate(String raw) {
    try {
      return _out.format(_in.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String get dataConsegnaOda => _fmtDate(psdesdt);
  String get dataConsegnaOdl => _fmtDate(duedate);

  bool get haProblemi => statoOdv.any(
      (s) => s != StatoOdv.disponibile && s != StatoOdv.disponibilePrel);

  bool matchFiltro(String filtro) {
    if (filtro == 'Tutti') return true;
    for (final s in statoOdv) {
      switch (filtro) {
        case 'disp_tutti':
          if (s == StatoOdv.disponibile || s == StatoOdv.disponibilePrel) {
            return true;
          }
          break;
        case 'disp_reparto':
          if (s == StatoOdv.disponibile) return true;
          break;
        case 'disp_prel':
          if (s == StatoOdv.disponibilePrel) return true;
          break;
        case 'odl':
          if (s == StatoOdv.inOdl) return true;
          break;
        case 'oda':
          if (s == StatoOdv.inOda) return true;
          break;
        case 'mancanti':
          if (s == StatoOdv.mancante) return true;
          break;
      }
    }
    return false;
  }

  factory OdvRiga.fromJson(Map<String, dynamic> json) {
    final statiRaw = json['stato_odv'];
    final stati = <StatoOdv>[];
    if (statiRaw is List) {
      for (final s in statiRaw) {
        stati.add(statoOdvFromString(s.toString()));
      }
    } else if (statiRaw != null) {
      stati.add(statoOdvFromString(statiRaw.toString()));
    }
    return OdvRiga(
      pos: (json['pos'] ?? '').toString(),
      articolo: (json['articolo'] ?? '').toString(),
      descarticolo: (json['descarticolo'] ?? '').toString(),
      magazzino: (json['magazzino'] ?? '').toString(),
      giacmag: (json['giacmag'] ?? '').toString(),
      qtaape: (json['qtaape'] ?? '').toString(),
      magdispo: (json['magdispo'] ?? '').toString(),
      giacdispo: (json['giacdispo'] ?? '').toString(),
      psdesdt: (json['psdesdt'] ?? '').toString(),
      numsoda: (json['numsoda'] ?? '').toString(),
      qtaisoda: (json['qtaisoda'] ?? '').toString(),
      qtafab: (json['qtafab'] ?? '').toString(),
      duedate: (json['duedate'] ?? '').toString(),
      numodl: (json['numodl'] ?? '').toString(),
      qtaiodl: (json['qtaiodl'] ?? '').toString(),
      qtaMancante: (json['qta_mancante'] ?? '').toString(),
      statoOdv: stati,
    );
  }
}
