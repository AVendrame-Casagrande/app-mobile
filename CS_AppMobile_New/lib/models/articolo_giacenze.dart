// Modelli Giacenze/Articolo — porting di
// www/scripts/Giacenze-Magazzino/Classi/Articolo.js.
// Include i dati base, magazzini, note, prezzi (con Tq/Tf), movimenti,
// ordini (acquisto/lavoro), impegni (ODL/ODV), fabbisogni, eccedenza,
// immagini e disegni (PDF). La distinta è caricata a parte (getListaDistinte).

String _str(dynamic v) => (v ?? '').toString();

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

/// Formatta una data in "dd/MM/yyyy". Gestisce sia "yyyy-MM-dd" sia "yyyyMMdd"
/// (e timestamp più lunghi) facendo slicing manuale delle cifre, senza
/// dipendere dal parsing di DateFormat (che falliva su certi valori).
String fmtDataArticolo(dynamic raw) {
  final s = _str(raw).trim();
  if (s.isEmpty || s == '0') return '';
  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 8) {
    final y = digits.substring(0, 4);
    final m = digits.substring(4, 6);
    final d = digits.substring(6, 8);
    final mi = int.tryParse(m) ?? 0;
    final di = int.tryParse(d) ?? 0;
    if (mi >= 1 && mi <= 12 && di >= 1 && di <= 31) {
      return '$d/$m/$y';
    }
  }
  return s;
}

/// Numero intero yyyyMMdd da una data grezza (per confronti con "oggi").
int dataIntFromRaw(dynamic raw) {
  final digits = _str(raw).replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 8) return int.tryParse(digits.substring(0, 8)) ?? 0;
  return int.tryParse(digits) ?? 0;
}

/// Formatta un orario "HHmmss" in "HH:mm".
String fmtOraArticolo(dynamic raw) {
  final s = _str(raw).replaceAll(RegExp(r'[^0-9]'), '');
  if (s.length >= 4) return '${s.substring(0, 2)}:${s.substring(2, 4)}';
  return _str(raw);
}

/// Risultato di una ricerca "like" (selectArticoloLike.php).
class ArticoloRicerca {
  final String codice;
  final String descrizione;
  ArticoloRicerca({this.codice = '', this.descrizione = ''});

  factory ArticoloRicerca.fromJson(Map<String, dynamic> json) => ArticoloRicerca(
        codice: _str(json['codice']),
        descrizione: _str(json['descrizione']),
      );
}

/// Articolo completo (selectSingoloArticolo.php, needCompleteInfo=true).
class ArticoloGiacenze {
  final String codice;
  final String descrizione;
  final String societa;
  final String tipoArticolo;
  final String unitaMisura;
  final String pesoLordo;
  final String pesoNetto;
  final String impegnatoTotale;
  final String disponibileTotale;
  final String giacenteTotale;
  final String inOrdineProduzione;
  final String inOrdineAcquisto;
  final String ultimoVersamento;
  final String ultimoConsumo;
  final String trattamento;
  final String colore;
  final String codiceDisegno;
  final String magazzinoVanoPreferenziale;
  final num eccedenza;

  final List<MagazzinoArticolo> listaMagazzini;
  final List<NotaArticolo> listaNote;
  final List<PrezzoListino> listaPrezzi;
  final List<MovimentoArticolo> listaMovimenti;
  final List<OrdineAcquisto> listaOrdini;
  final List<OrdineLavoro> listaOrdiniOdl;
  final List<ImpegnoOdl> listaImpegniOdl;
  final List<ImpegnoOdv> listaImpegniOdv;
  final List<Fabbisogno> listaFabbisogni;
  final List<MancanteArticolo> listaMancanti;
  final List<String> arrayImmagini;
  final List<PdfFileArticolo> arrayPdfFile;

  ArticoloGiacenze({
    this.codice = '',
    this.descrizione = '',
    this.societa = '',
    this.tipoArticolo = '',
    this.unitaMisura = '',
    this.pesoLordo = '',
    this.pesoNetto = '',
    this.impegnatoTotale = '',
    this.disponibileTotale = '',
    this.giacenteTotale = '',
    this.inOrdineProduzione = '',
    this.inOrdineAcquisto = '',
    this.ultimoVersamento = '',
    this.ultimoConsumo = '',
    this.trattamento = '',
    this.colore = '',
    this.codiceDisegno = '',
    this.magazzinoVanoPreferenziale = '',
    this.eccedenza = 0,
    this.listaMagazzini = const [],
    this.listaNote = const [],
    this.listaPrezzi = const [],
    this.listaMovimenti = const [],
    this.listaOrdini = const [],
    this.listaOrdiniOdl = const [],
    this.listaImpegniOdl = const [],
    this.listaImpegniOdv = const [],
    this.listaFabbisogni = const [],
    this.listaMancanti = const [],
    this.arrayImmagini = const [],
    this.arrayPdfFile = const [],
  });

  static List<T> _mapList<T>(
      dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory ArticoloGiacenze.fromJson(Map<String, dynamic> json) {
    final impegniOdl = _mapList(json['listaImpegniOdl'], ImpegnoOdl.fromJson);
    final impegniOdv = _mapList(json['listaImpegniOdv'], ImpegnoOdv.fromJson);
    final fabbisogni = _mapList(json['listaFabbisogni'], Fabbisogno.fromJson);

    // Eccedenza = disponibile - impegnatoOdl(stato 10) - impegnatoOdv - fabbisogni.
    final disponibile = _num(json['disponibileTotale']);
    num impOdl = 0;
    for (final i in impegniOdl) {
      if (i.stato == '10') impOdl += i.impegnato;
    }
    num impOdv = 0;
    for (final i in impegniOdv) {
      impOdv += i.impegnato;
    }
    num impFab = 0;
    for (final f in fabbisogni) {
      impFab += f.impegnato;
    }
    final eccedenza = disponibile - impOdl - impOdv - impFab;

    // arrayImmagini = lista di URL (stringhe).
    // magazzinoVanoPreferenziale = {magazzino, vano} oppure null.
    final rawPref = json['magazzinoVanoPreferenziale'];
    final vanoPref = rawPref is Map
        ? [_str(rawPref['magazzino']), _str(rawPref['vano'])]
            .where((s) => s.isNotEmpty)
            .join(' / ')
        : _str(rawPref);

    final immagini = <String>[];
    final rawImg = json['arrayImmagini'];
    if (rawImg is List) {
      for (final u in rawImg) {
        immagini.add(u.toString());
      }
    }

    return ArticoloGiacenze(
      codice: _str(json['codice']),
      descrizione: _str(json['descrizione']),
      societa: _str(json['societa']),
      tipoArticolo: _str(json['tipoArticolo']),
      unitaMisura: _str(json['unitaMisura']),
      pesoLordo: _str(json['pesoLordo']),
      pesoNetto: _str(json['pesoNetto']),
      impegnatoTotale: _str(json['impegnatoTotale']),
      disponibileTotale: _str(json['disponibileTotale']),
      giacenteTotale: _str(json['giacenteTotale']),
      inOrdineProduzione: _str(json['inOrdineProduzione']),
      inOrdineAcquisto: _str(json['inOrdineAcquisto']),
      ultimoVersamento: fmtDataArticolo(json['ultimoVersamento']),
      ultimoConsumo: fmtDataArticolo(json['ultimoConsumo']),
      trattamento: _str(json['trattamento']),
      colore: _str(json['colore']),
      codiceDisegno: _str(json['codiceDisegno']),
      magazzinoVanoPreferenziale: vanoPref,
      eccedenza: eccedenza,
      listaMagazzini:
          _mapList(json['listaMagazzini'], MagazzinoArticolo.fromJson),
      listaNote: _mapList(json['listaNote'], NotaArticolo.fromJson),
      listaPrezzi: _mapList(json['listaPrezzi'], PrezzoListino.fromJson),
      listaMovimenti:
          _mapList(json['listaMovimenti'], MovimentoArticolo.fromJson),
      listaOrdini: _mapList(json['listaOrdini'], OrdineAcquisto.fromJson),
      listaOrdiniOdl: _mapList(json['listaOrdiniOdl'], OrdineLavoro.fromJson),
      listaImpegniOdl: impegniOdl,
      listaImpegniOdv: impegniOdv,
      listaFabbisogni: fabbisogni,
      listaMancanti: _mapList(json['listaMancanti'], MancanteArticolo.fromJson),
      arrayImmagini: immagini,
      arrayPdfFile: _mapList(json['arrayPdfFile'], PdfFileArticolo.fromJson),
    );
  }
}

class MagazzinoArticolo {
  final String codice;
  final String vano;
  final String impegnato;
  final String giacente;
  final String categoria;

  MagazzinoArticolo({
    this.codice = '',
    this.vano = '',
    this.impegnato = '',
    this.giacente = '',
    this.categoria = '',
  });

  /// Magazzino con giacenza movimentabile (ST, non automatico).
  bool get movimentabile =>
      _num(giacente) > 0 && categoria == 'ST' && !codice.contains('MGAUT');

  bool get isAutomatico =>
      (codice == 'MGAUT00' || codice == 'MGAUT10') && _num(giacente) > 0;

  factory MagazzinoArticolo.fromJson(Map<String, dynamic> json) =>
      MagazzinoArticolo(
        codice: _str(json['codice']),
        vano: _str(json['vano']),
        impegnato: _str(json['impegnato']),
        giacente: _str(json['giacente']),
        categoria: _str(json['categoria']),
      );
}

class NotaArticolo {
  final String tipoNota;
  final String nota;

  NotaArticolo({this.tipoNota = '', this.nota = ''});

  factory NotaArticolo.fromJson(Map<String, dynamic> json) => NotaArticolo(
        tipoNota: _str(json['tipoNota']),
        nota: _str(json['nota']),
      );
}

class PrezzoListino {
  final String azienda;
  final String tq;
  final String tf;
  final String valuta;
  final String unitaMisura;
  final String prezzoNetto;
  final String dataInizio;

  PrezzoListino({
    this.azienda = '',
    this.tq = '',
    this.tf = '',
    this.valuta = '',
    this.unitaMisura = '',
    this.prezzoNetto = '',
    this.dataInizio = '',
  });

  /// Prezzo formattato "xxx,yy EUR".
  String get prezzoFmt {
    final p = _num(prezzoNetto);
    final valore = p.toStringAsFixed(2).replaceAll('.', ',');
    final val = valuta.isEmpty ? 'EUR' : valuta;
    return '$valore $val';
  }

  factory PrezzoListino.fromJson(Map<String, dynamic> json) => PrezzoListino(
        azienda: _str(json['azienda']),
        tq: _str(json['tq']),
        tf: _str(json['tf']),
        valuta: _str(json['valuta']),
        unitaMisura: _str(json['unitaMisura']),
        prezzoNetto: _str(json['prezzoNetto']),
        dataInizio: fmtDataArticolo(json['dataInizio']),
      );
}

class MovimentoArticolo {
  final String riferimento;
  final String magazzino;
  final String movCausale;
  final String movValore;
  final String movStorno;
  final String quantita;
  final String data;
  final int dataInteger;
  final String ora;
  final String codiceFornitore;
  final String descrizioneFornitore;
  final String codicePadre;
  final String descrizionePadre;
  /// Commessa (MASATRN.TRNI), mostrata nel dettaglio come "Comm | Bolla".
  final String trni;
  final String bolla;
  final String nota;
  final String responsabile;
  final String vano;

  /// Chiave usata dal filtro causali (come in Cordova: "causale-valore").
  String get chiaveCausale => '$movCausale-$movValore';

  MovimentoArticolo({
    this.riferimento = '',
    this.magazzino = '',
    this.movCausale = '',
    this.movValore = '',
    this.movStorno = '',
    this.quantita = '',
    this.data = '',
    this.dataInteger = 0,
    this.ora = '',
    this.codiceFornitore = '',
    this.descrizioneFornitore = '',
    this.codicePadre = '',
    this.descrizionePadre = '',
    this.trni = '',
    this.bolla = '',
    this.nota = '',
    this.responsabile = '',
    this.vano = '',
  });

  /// Data da mostrare: se il movimento è di oggi mostra solo l'ora.
  String dataDisplay(int oggiInt) =>
      dataInteger == oggiInt && ora.isNotEmpty ? ora : data;

  factory MovimentoArticolo.fromJson(Map<String, dynamic> json) =>
      MovimentoArticolo(
        riferimento: _str(json['riferimento']),
        magazzino: _str(json['magazzino']),
        movCausale: _str(json['movCausale']),
        movValore: _str(json['movValore']),
        movStorno: _str(json['movStorno']),
        quantita: _str(json['quantita']),
        data: fmtDataArticolo(json['data']),
        dataInteger: json['data_integer'] != null
            ? dataIntFromRaw(json['data_integer'])
            : dataIntFromRaw(json['data']),
        ora: fmtOraArticolo(json['ora']),
        codiceFornitore: _str(json['codiceFornitore']),
        descrizioneFornitore: _str(json['descrizioneFornitore']),
        codicePadre: _str(json['codicePadre']),
        descrizionePadre: _str(json['descrizionePadre']),
        trni: _str(json['trni']),
        bolla: _str(json['bolla']),
        nota: _str(json['nota']),
        responsabile: _str(json['responsabile']),
        vano: _str(json['vano']),
      );
}

class OrdineAcquisto {
  final String azienda;
  final String numeroOrdine;
  final String qtaInOrdine;
  final String dataConsegna;
  final String pos;
  final String sched;

  /// Date/quantità confermate dal fornitore (cs_fabbmanc_risp_soda2).
  final List<DettaglioOrdineAcquisto> dettagliOrdine;

  OrdineAcquisto({
    this.azienda = '',
    this.numeroOrdine = '',
    this.qtaInOrdine = '',
    this.dataConsegna = '',
    this.pos = '',
    this.sched = '',
    this.dettagliOrdine = const [],
  });

  factory OrdineAcquisto.fromJson(Map<String, dynamic> json) => OrdineAcquisto(
        azienda: _str(json['azienda']),
        numeroOrdine: _str(json['numeroOrdine']),
        qtaInOrdine: _str(json['qtaInOrdine']),
        dataConsegna: fmtDataArticolo(json['dataConsegna']),
        pos: _str(json['pos']),
        sched: _str(json['sched']),
        dettagliOrdine: ArticoloGiacenze._mapList(
            json['dettagliOrdine'], DettaglioOrdineAcquisto.fromJson),
      );
}

/// Riga di conferma di un ordine di acquisto (popup ODA di Cordova).
class DettaglioOrdineAcquisto {
  final String qtaConfermata;
  final String dataConfermata;
  final String note;

  DettaglioOrdineAcquisto({
    this.qtaConfermata = '',
    this.dataConfermata = '',
    this.note = '',
  });

  factory DettaglioOrdineAcquisto.fromJson(Map<String, dynamic> json) =>
      DettaglioOrdineAcquisto(
        qtaConfermata: _str(json['qtaConfermata']),
        dataConfermata: fmtDataArticolo(json['dataConfermata']),
        note: _str(json['note']),
      );
}

class OrdineLavoro {
  final String codiceOrdine;
  final String statoOrdine;
  final String qta;
  final String dataInizio;
  final String dataConsegna;
  final String magazzino;
  final String responsabileOrdine;

  OrdineLavoro({
    this.codiceOrdine = '',
    this.statoOrdine = '',
    this.qta = '',
    this.dataInizio = '',
    this.dataConsegna = '',
    this.magazzino = '',
    this.responsabileOrdine = '',
  });

  factory OrdineLavoro.fromJson(Map<String, dynamic> json) => OrdineLavoro(
        codiceOrdine: _str(json['codiceOrdine']),
        statoOrdine: _str(json['statoOrdine']),
        qta: _str(json['qta']),
        dataInizio: fmtDataArticolo(json['dataInizio']),
        dataConsegna: fmtDataArticolo(json['dataConsegna']),
        magazzino: _str(json['magazzino']),
        responsabileOrdine: _str(json['responsabileOrdine']),
      );
}

class ImpegnoOdl {
  final String odl;
  final String magazzino;
  final String data;
  final num impegnato;
  final String copertura;
  final String fase;
  final String padre;
  final String descrizione;
  final String tipologia;
  final String stato;

  ImpegnoOdl({
    this.odl = '',
    this.magazzino = '',
    this.data = '',
    this.impegnato = 0,
    this.copertura = '',
    this.fase = '',
    this.padre = '',
    this.descrizione = '',
    this.tipologia = '',
    this.stato = '',
  });

  factory ImpegnoOdl.fromJson(Map<String, dynamic> json) => ImpegnoOdl(
        odl: _str(json['odl']),
        magazzino: _str(json['magazzino']),
        data: fmtDataArticolo(json['data']),
        impegnato: _num(json['impegnato']),
        copertura: _str(json['copertura']),
        fase: _str(json['fase']),
        padre: _str(json['padre']),
        descrizione: _str(json['descrizione']),
        tipologia: _str(json['tipologia']),
        stato: _str(json['stato']),
      );
}

class ImpegnoOdv {
  final String odv;
  final String azienda;
  final num impegnato;
  final String dataConsegna;
  final String stato;

  ImpegnoOdv({
    this.odv = '',
    this.azienda = '',
    this.impegnato = 0,
    this.dataConsegna = '',
    this.stato = '',
  });

  factory ImpegnoOdv.fromJson(Map<String, dynamic> json) => ImpegnoOdv(
        odv: _str(json['odv']),
        azienda: _str(json['azienda']),
        impegnato: _num(json['impegnato']),
        dataConsegna: fmtDataArticolo(json['dataConsegna']),
        stato: _str(json['stato']),
      );
}

class Fabbisogno {
  final String codicePadre;
  final String descrizionePadre;
  final num impegnato;
  final String data;

  Fabbisogno({
    this.codicePadre = '',
    this.descrizionePadre = '',
    this.impegnato = 0,
    this.data = '',
  });

  factory Fabbisogno.fromJson(Map<String, dynamic> json) => Fabbisogno(
        codicePadre: _str(json['codicePadre']),
        descrizionePadre: _str(json['descrizionePadre']),
        impegnato: _num(json['impegnato']),
        data: fmtDataArticolo(json['data']),
      );
}

/// Riga "Mancanti" della scheda articolo (listaMancanti).
class MancanteArticolo {
  final String odl;
  final String mag;
  final String tipoodl;
  final String pickautorizzato;
  final String picklanciato;
  final String pickconcluso;
  final String statopick;
  final String dataFabb;

  MancanteArticolo({
    this.odl = '',
    this.mag = '',
    this.tipoodl = '',
    this.pickautorizzato = '',
    this.picklanciato = '',
    this.pickconcluso = '',
    this.statopick = '',
    this.dataFabb = '',
  });

  /// Stato prelievi P/R/W/Y.
  String get statoPrelievi =>
      '$pickautorizzato/$picklanciato/$pickconcluso/$statopick';

  factory MancanteArticolo.fromJson(Map<String, dynamic> json) => MancanteArticolo(
        odl: _str(json['odl']),
        mag: _str(json['mag']),
        tipoodl: _str(json['tipoodl']),
        pickautorizzato: _str(json['pickautorizzato']),
        picklanciato: _str(json['picklanciato']),
        pickconcluso: _str(json['pickconcluso']),
        statopick: _str(json['statopick']),
        dataFabb: fmtDataArticolo(json['data_fabb']),
      );
}

class PdfFileArticolo {
  final String url;
  final String tipoPdf;
  final String numeroFoglioPdfDisplay;
  final String estensione;

  PdfFileArticolo({
    this.url = '',
    this.tipoPdf = '',
    this.numeroFoglioPdfDisplay = '',
    this.estensione = '',
  });

  factory PdfFileArticolo.fromJson(Map<String, dynamic> json) => PdfFileArticolo(
        url: _str(json['url']),
        tipoPdf: _str(json['tipoPdf']),
        numeroFoglioPdfDisplay: _str(json['numeroFoglioPdfDisplay']).isEmpty
            ? _str(json['numeroFoglioPdf'])
            : _str(json['numeroFoglioPdfDisplay']),
        estensione: _str(json['estensione']).isEmpty
            ? 'pdf'
            : _str(json['estensione']),
      );
}

/// Riga di distinta (getListaDistinte.php).
class DistintaArticolo {
  final String assieme;
  final String componente;
  final String descrizioneAssieme;
  final String descrizioneComponente;
  final String disegno;
  final String mutms;
  final String pos;
  final String qta;
  final String em;

  DistintaArticolo({
    this.assieme = '',
    this.componente = '',
    this.descrizioneAssieme = '',
    this.descrizioneComponente = '',
    this.disegno = '',
    this.mutms = '',
    this.pos = '',
    this.qta = '',
    this.em = '',
  });

  factory DistintaArticolo.fromJson(Map<String, dynamic> json) => DistintaArticolo(
        assieme: _str(json['assieme']),
        componente: _str(json['componente']),
        descrizioneAssieme: _str(json['descrizioneAssieme']),
        descrizioneComponente: _str(json['descrizioneComponente']),
        disegno: _str(json['disegno']),
        mutms: _str(json['mutms']),
        pos: _str(json['pos']),
        qta: _str(json['qta']),
        em: _str(json['em']),
      );
}
