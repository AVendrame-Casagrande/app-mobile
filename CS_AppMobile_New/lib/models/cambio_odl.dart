// Modelli Cambio ODL — porting di
// www/scripts/Giacenze-Magazzino/Classi/CambioOdl.js.

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();

/// Risultato base (ricerca per padre/magazzino → scelta ODL).
class CambioOdlBase {
  final String odl;
  final String padre;
  final String desPadre;
  final String tipoRicerca;

  CambioOdlBase({
    this.odl = '',
    this.padre = '',
    this.desPadre = '',
    this.tipoRicerca = '',
  });

  factory CambioOdlBase.fromJson(Map<String, dynamic> json) => CambioOdlBase(
        odl: _str(json['odl']),
        padre: _str(json['padre']),
        desPadre: _str(json['des_padre']),
        tipoRicerca: _str(json['tipoRicerca']),
      );
}

/// Riga di cambio ODL (ricerca per ODL).
class CambioOdlRiga {
  final String odl;
  String fase;
  final String articolo;
  final String descArticolo;
  final num qtatrasftot;
  final num qta;
  final String magOri;
  final String vanoOri;
  String magDes;
  String vanoDes;
  final String padre;
  final String desPadre;
  final String colore;
  final num pesoLordo;
  final num rientro;
  final String queryMagDes;
  final String queryVanoDes;
  final String tipoRicerca;
  bool selezionato;

  CambioOdlRiga({
    this.odl = '',
    this.fase = '',
    this.articolo = '',
    this.descArticolo = '',
    this.qtatrasftot = 0,
    this.qta = 0,
    this.magOri = '',
    this.vanoOri = '',
    this.magDes = '',
    this.vanoDes = '',
    this.padre = '',
    this.desPadre = '',
    this.colore = '',
    this.pesoLordo = 0,
    this.rientro = 0,
    this.queryMagDes = '',
    this.queryVanoDes = '',
    this.tipoRicerca = 'odl',
    this.selezionato = false,
  });

  bool get isRientro => rientro > 0;

  factory CambioOdlRiga.fromJson(Map<String, dynamic> json) {
    var magDes = _str(json['mag_des']);
    var fase = _str(json['fase']);
    final rientro = _num(json['rientro']);
    // Caso rientro (come nell'originale): fase 'Rientro', mag_des MIRC001.
    if (rientro > 0) {
      fase = 'Rientro';
      magDes = 'MIRC001';
    }
    return CambioOdlRiga(
      odl: _str(json['odl']),
      fase: fase,
      articolo: _str(json['articolo']),
      descArticolo: _str(json['descarticolo']),
      qtatrasftot: _num(json['qtatrasftot']),
      qta: _num(json['qta']),
      magOri: _str(json['mag_ori']),
      vanoOri: _str(json['vano_ori']),
      magDes: magDes,
      vanoDes: _str(json['vano_des']),
      padre: _str(json['padre']),
      desPadre: _str(json['des_padre']),
      colore: _str(json['colore']),
      pesoLordo: _num(json['pesoLordo']),
      rientro: rientro,
      // query_mag_des/query_vano_des = mag_des/vano_des originali (PRIMA del fix rientro)
      queryMagDes: _str(json['mag_des']),
      queryVanoDes: _str(json['vano_des']),
      tipoRicerca: 'odl',
    );
  }
}

/// Fase possibile per il nuovo ODL (validateOdlSelectFasi.php).
class FasePossibile {
  final String fase;
  final String magDes;
  final String vanoDes;

  FasePossibile({this.fase = '', this.magDes = '', this.vanoDes = ''});

  factory FasePossibile.fromJson(Map<String, dynamic> json) => FasePossibile(
        fase: _str(json['fase']),
        magDes: _str(json['mag_des']),
        vanoDes: _str(json['vano_des']),
      );
}

/// Risultato della ricerca cambio ODL.
class CambioOdlResult {
  final bool isOdl; // true = righe ODL; false = lista multipla da scegliere
  final List<CambioOdlBase> listaBase;
  final List<CambioOdlRiga> righe;
  final List<String> listaPossibiliOdl;

  CambioOdlResult({
    this.isOdl = false,
    this.listaBase = const [],
    this.righe = const [],
    this.listaPossibiliOdl = const [],
  });

  bool get vuoto => listaBase.isEmpty && righe.isEmpty;

  factory CambioOdlResult.fromJson(Map<String, dynamic> json) {
    final rawCambio = json['listaCambioOdl'];
    final lista = (rawCambio is List)
        ? rawCambio.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    if (lista.isEmpty) {
      return CambioOdlResult();
    }

    final tipo = _str(lista.first['tipoRicerca']);
    if (tipo != 'odl') {
      return CambioOdlResult(
        isOdl: false,
        listaBase: lista.map(CambioOdlBase.fromJson).toList(),
      );
    }

    final possibili = <String>[];
    final rawPossibili = json['listaPossibiliOdl'];
    if (rawPossibili is List) {
      for (final p in rawPossibili) {
        if (p is Map && p['odl'] != null) {
          possibili.add(p['odl'].toString());
        } else if (p != null) {
          possibili.add(p.toString());
        }
      }
    }

    return CambioOdlResult(
      isOdl: true,
      righe: lista.map(CambioOdlRiga.fromJson).toList(),
      listaPossibiliOdl: possibili,
    );
  }
}
