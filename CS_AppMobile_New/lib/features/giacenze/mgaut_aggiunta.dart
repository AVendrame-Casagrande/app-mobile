import 'package:flutter/material.dart';

import '../../models/riga_lista_aut.dart';
import 'inventario_dialogs.dart';
import 'mgaut_service.dart';

/// Liste MGAUT00 / MGAUT10 in memoria. Come nell'originale
/// (giacenze.currentMgautPage) restano finché l'app è aperta e non vengono
/// salvate sul dispositivo.
class MgautStore {
  MgautStore._();
  static final List<RigaListaAut> mgaut00 = [];
  static final List<RigaListaAut> mgaut10 = [];

  static List<RigaListaAut> lista(String magazzino) =>
      magazzino == 'MGAUT10' ? mgaut10 : mgaut00;
}

String _s(dynamic v) => (v ?? '').toString();
num _n(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

int _i(dynamic v) => _n(v).toInt();

List<String> _unici(Iterable<String> v) {
  final out = <String>[];
  for (final s in v) {
    if (!out.contains(s)) out.add(s);
  }
  return out;
}

/// Aggiunta di una riga a una lista MGAUT00/MGAUT10 — porting di
/// giacenze.mgautPageFunctions.addArticoloManualeToMgaut (Mgaut.js).
///
/// La catena di popup dell'originale (tipo prelievo → articolo → magazzino
/// destinazione → ODL/fase o ODV/POS → vano → quantità) è resa come una
/// sequenza di dialog; annullare un passo interrompe l'aggiunta.
class MgautAggiunta {
  MgautAggiunta({
    required this.context,
    required this.service,
    required this.magazzinoOrigine,
    required this.nomePortale,
  }) : lista = MgautStore.lista(magazzinoOrigine);

  final BuildContext context;
  final MgautService service;
  final String magazzinoOrigine; // MGAUT00 / MGAUT10
  final String nomePortale;
  final List<RigaListaAut> lista;

  // Variabili locali dell'originale.
  String _tipo = '';
  ArticoloAut? _articolo;
  String _magDest = '';
  String _vanoDest = '';
  num _qta = 0;
  String _odl = '';
  String _padre = '';
  String _padreDesc = '';
  String _fase = '';
  String _faseDesc = '';
  String _cliente = '';
  String _nomeCliente = '';
  int _pos = 0;
  int _seq = 0;
  bool _vanoRequired = false;


  /// Avvia l'aggiunta. Ritorna true se le liste sono cambiate.
  Future<bool> avvia() async {
    if (lista.isNotEmpty) {
      _tipo = lista.first.tipoprel;
      return _aggiungiArticolo();
    }
    const tipi = [
      'Manuale',
      'Prelievo ODL',
      'Prelievo ODV',
      'Prelievo ODV ( Immediato )',
    ];
    final scelta = await invSelect(context, 'Seleziona il tipo di Prelievo', tipi);
    if (scelta == null || !context.mounted) return false;
    switch (scelta) {
      case 'Manuale':
        _tipo = 'MAN';
      case 'Prelievo ODL':
        _tipo = 'ODL';
      case 'Prelievo ODV':
        _tipo = 'ODV';
      default:
        _tipo = 'ODV';
        return _prelievoImmediato();
    }
    return _aggiungiArticolo();
  }

  // ---------------------------------------------------------------------------
  // Prelievo ODV immediato (pre bolla)
  // ---------------------------------------------------------------------------

  Future<bool> _prelievoImmediato([String testoPrima = '']) async {
    const attenzione = '- Attenzione: il Prelievo ODV ( Immediato ) svuoterà '
        'entrambe le Liste MGAUT00 e MGAUT10 per ricompilarle automaticamente -';
    final testo = testoPrima.isEmpty
        ? 'Digita il codice della Pre Bolla:\n\n$attenzione'
        : '$testoPrima\nDigita il codice della Pre Bolla per importare '
            "l'elenco degli Articoli in tempo reale:\n\n$attenzione";
    final r = await invPrompt(context, 'Inserisci Pre Bolla', testo,
        ['Conferma', 'Annulla'],
        uppercase: true);
    if (r == null || r.button != 0 || !context.mounted) return false;
    final prebolla = r.text.trim().toUpperCase();

    List<String> odvs;
    try {
      odvs = await service.odvDaPrebolla(prebolla);
    } catch (_) {
      if (context.mounted) {
        await invAlert(context, 'Pre Bolla non trovata',
            'Non è stata trovata nessuna Pre Bolla Aperta con il codice $prebolla');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (odvs.isEmpty) {
      await invAlert(context, 'Nessun Ordine',
          'Non è stato trovato nessun ODV per la Pre Bolla $prebolla');
      return false;
    }
    final odv = await invSelect(context, "Seleziona l'Odv per questa Lista", odvs);
    if (odv == null || !context.mounted) return false;

    List<Map<String, dynamic>> righe;
    try {
      righe = await service.righeDaOdv(odv);
    } catch (_) {
      if (context.mounted) {
        await invAlert(
            context, 'Errore del Server', 'Errore di connessione o del Server');
      }
      return false;
    }
    if (!context.mounted) return false;

    MgautStore.mgaut00.clear();
    MgautStore.mgaut10.clear();
    final scartati = <String>[];
    var n00 = 0, n10 = 0;
    for (final r in righe) {
      final magfrom = r['magfrom'];
      if (magfrom != 'MGAUT00' && magfrom != 'MGAUT10') {
        scartati.add(_s(r['articolo']));
        continue;
      }
      magfrom == 'MGAUT00' ? n00++ : n10++;
      MgautStore.lista(magfrom as String).insert(
        0,
        RigaListaAut(
          tipoprel: 'ODV',
          rifprel: odv,
          usrcrea: nomePortale,
          articolo: _s(r['articolo']),
          descarticolo: _s(r['descarticolo']),
          qta: _n(r['qta']),
          umis: _s(r['umis']),
          qtaconf: _n(r['qta']),
          magfrom: magfrom,
          magto: _s(r['magto']),
          cliente: _s(r['cliente']),
          nomecliente: _s(r['nomecliente']),
          pos: _i(r['pos']),
          seq: _i(r['seq']),
        ),
      );
    }
    await invAlert(
      context,
      'Lista Importata',
      'Sono stati aggiunti:\n\n$n00 Articoli alla Lista MGAUT00\n$n10 Articoli alla Lista MGAUT10\n\n'
          'Elenco degli Articoli SCARTATI perchè non hanno abbastanza giacenza su '
          'MGAUT00 o MGAUT10:\n\n${scartati.join('\n')}',
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Articolo
  // ---------------------------------------------------------------------------

  /// rigaIsValid('articolo', codice): gli ODV possono ripetere l'articolo
  /// con POS diverse.
  bool _articoloGiaPresente(String codice) =>
      lista.any((r) => r.tipoprel != 'ODV' && r.articolo == codice);

  Future<bool> _aggiungiArticolo() async {
    if (lista.isNotEmpty && _tipo == 'ODL') return _articoloDaOdl();
    if (lista.isNotEmpty && _tipo == 'ODV') return _articoloDaOdv();
    return _articoloManuale();
  }

  Future<bool> _articoloManuale() async {
    final r = await invPrompt(context, 'Aggiungi Prelievo MGAUT',
        'Digita il codice Articolo da aggiungere:', ['Aggiungi', 'Annulla'],
        uppercase: true);
    if (r == null || r.button != 0 || !context.mounted) return false;
    return _verificaArticolo(r.text.trim().toUpperCase());
  }

  Future<bool> _articoloDaOdl() async {
    final primo = lista.first;
    List<Map<String, dynamic>> art;
    try {
      art = await service.odlGetArticoli(
          primo.rifprel, primo.subrifprel, magazzinoOrigine, primo.magto);
    } catch (_) {
      if (context.mounted) {
        await invAlert(
            context, 'Errore di Rete', 'Impossibile scaricare gli Articoli Disponibili');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (art.isEmpty) return _articoloManuale();

    const manuale = 'Aggiungi articolo manualmente';
    final codici = [
      manuale,
      ..._unici(art.map((a) => _s(a['articolo']))
          .where((c) => !lista.any((r) => r.articolo == c))),
    ];
    final scelto = await invSelect(context, "Seleziona l'Articolo da aggiungere", codici,
        extraButton: "Non trovo l'Articolo");
    if (scelto == null || !context.mounted) return false;
    if (scelto == manuale || scelto == invSelectExtra) return _articoloManuale();
    final riga = art.firstWhere((a) => _s(a['articolo']) == scelto);
    return _verificaArticolo(scelto, qtaDispo: _n(riga['qta']));
  }

  Future<bool> _articoloDaOdv() async {
    final primo = lista.first;
    List<Map<String, dynamic>> art;
    try {
      art = await service.odvGetArticoli(primo.rifprel, magazzinoOrigine, primo.magto);
    } catch (_) {
      if (context.mounted) {
        await invAlert(
            context, 'Errore di Rete', 'Impossibile scaricare gli Articoli Disponibili');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (art.isEmpty) {
      await invAlert(context, 'Nessun Articolo', 'Nessun Articolo disponibile');
      return false;
    }
    final disponibili = art
        .where((a) => !lista.any(
            (r) => r.articolo == _s(a['articolo']) && r.pos == _i(a['pos'])))
        .toList();
    if (disponibili.isEmpty) {
      await invAlert(context, 'Nessun Articolo', 'Nessun altro Articolo disponibile');
      return false;
    }
    final etichette = [
      for (final a in disponibili) '${_s(a['articolo'])} | ${_i(a['pos'])}'
    ];
    final scelto = await invSelect(
        context, "Seleziona l'Articolo e la POS da aggiungere", etichette);
    if (scelto == null || !context.mounted) return false;
    final a = disponibili[etichette.indexOf(scelto)];
    _pos = _i(a['pos']);
    _seq = _i(a['seq']);
    return _verificaArticolo(_s(a['articolo']), qtaDispo: _n(a['qta']));
  }

  /// checkAndAddArticolo: esiste, non è duplicato, ha giacenza sull'origine.
  Future<bool> _verificaArticolo(String codice, {num? qtaDispo}) async {
    if (codice.isEmpty) return false;
    ArticoloAut? a;
    try {
      a = await service.getArticolo(codice);
    } catch (_) {
      a = null;
    }
    if (!context.mounted) return false;
    if (a == null) {
      await invAlert(context, 'Articolo Non trovato',
          "L'articolo con codice $codice non esiste. Riprova");
      return false;
    }
    if (_articoloGiaPresente(a.codice)) {
      await invAlert(
          context, 'Articolo Duplicato', "L'articolo $codice è già stato inserito");
      return false;
    }
    if (a.giacenteSu(magazzinoOrigine) <= 0) {
      await invAlert(context, 'Errore Giacenza',
          "L'articolo $codice non ha nessuna Giacenza su $magazzinoOrigine");
      return false;
    }
    _articolo = a;
    return _magazzinoHub(qtaDispo);
  }

  // ---------------------------------------------------------------------------
  // Magazzino di destinazione
  // ---------------------------------------------------------------------------

  Future<bool> _magazzinoHub(num? qtaDispo) async {
    if (lista.isNotEmpty) {
      // La lista ha già testata: si ricopiano i dati della prima riga.
      final p = lista.first;
      _magDest = p.magto;
      _odl = p.rifprel;
      _fase = p.subrifprel;
      _padre = p.artpadre;
      _padreDesc = p.descartpadre;
      _faseDesc = p.descfase;
      _cliente = p.cliente;
      _nomeCliente = p.nomecliente;
      _vanoRequired = p.vanoRequired;
      _vanoDest = p.vanoto;
      return _quantita(qtaDispo);
    }
    switch (_tipo) {
      case 'ODL':
        return _magazzinoDaElenco('ODL');
      case 'ODV':
        return _magazzinoDaElenco('ODV');
      default:
        return _magazzinoManuale('MAN');
    }
  }

  Future<bool> _magazzinoManuale(String tipo, {bool nessunoTrovato = false}) async {
    final testo = tipo != 'MAN' && nessunoTrovato
        ? 'Non è stato trovato nessun Magazzino di Destinazione in nessun $tipo '
            "per l'Articolo ${_articolo!.codice}\n\nDigita manualmente il Magazzino di Destinazione:"
        : 'Digita manualmente il Magazzino di Destinazione:';
    final r = await invPrompt(context, 'Aggiungi Magazzino Destinazione', testo,
        ['Aggiungi', 'Annulla'],
        uppercase: true);
    if (r == null || r.button != 0 || !context.mounted) return false;
    final mag = r.text.trim().toUpperCase();

    (bool, bool) esito;
    try {
      esito = await service.checkMagazzino(mag);
    } catch (_) {
      if (context.mounted) {
        await invAlert(
            context, 'Errore di Rete', 'Impossibile verificare se il Magazzino Esiste');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (!esito.$1) {
      await invAlert(context, 'Magazzino Inesistente', 'Questo Magazzino non Esiste');
      return false;
    }
    _magDest = mag;
    _vanoRequired = esito.$2;
    switch (tipo) {
      case 'ODL':
        return _sceltaOdl(filtraArticolo: false);
      case 'ODV':
        return _sceltaOdv(filtraArticolo: false);
      default:
        return _quantita(null);
    }
  }

  Future<bool> _magazzinoDaElenco(String tipo) async {
    List<String> mags;
    try {
      mags = await service.getMagazziniDestinazione(
          tipo, _articolo!.codice, magazzinoOrigine);
    } catch (_) {
      if (context.mounted) {
        await invAlert(
            context, 'Errore di Rete', 'Impossibile scaricare i Magazzini Disponibili');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (mags.isEmpty) {
      if (tipo == 'ODV') {
        return _prelievoImmediato('Non è stato trovato nessun ODV e nessun magazzino '
            "di Destinazione per l'Articolo ${_articolo!.codice}\n");
      }
      return _magazzinoManuale('ODL', nessunoTrovato: true);
    }
    final scelto = await invSelect(
        context, 'Seleziona il Magazzino di Destinazione', _unici(mags),
        extraButton: 'Non trovo il Magazzino');
    if (scelto == null || !context.mounted) return false;
    if (scelto == invSelectExtra) return _magazzinoManuale(tipo);
    _magDest = scelto;
    return tipo == 'ODL' ? _sceltaOdl() : _sceltaOdv();
  }

  // ---------------------------------------------------------------------------
  // ODL / fase
  // ---------------------------------------------------------------------------

  Future<bool> _sceltaOdl({bool filtraArticolo = true}) async {
    List<Map<String, dynamic>> odl;
    try {
      odl = await service.odlGetOdl(
          filtraArticolo ? _articolo!.codice : '', magazzinoOrigine, _magDest);
    } catch (_) {
      if (context.mounted) {
        await invAlert(context, 'Errore di Rete',
            'Impossibile scaricare gli ODL per questo Articolo');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (odl.isEmpty) return _odlManuale(nessunoTrovato: true);

    final scelto = await invSelect(context, "Seleziona l'Odl per questa Lista",
        _unici(odl.map((o) => _s(o['odl']))),
        extraButton: "Non trovo l'ODL");
    if (scelto == null || !context.mounted) return false;
    if (scelto == invSelectExtra) return _odlManuale();

    final righe = odl.where((o) => _s(o['odl']) == scelto).toList();
    _odl = scelto;
    _padre = _s(righe.first['padre']);
    _padreDesc = _s(righe.first['des_padre']);
    return _sceltaFase(righe);
  }

  Future<bool> _odlManuale({bool nessunoTrovato = false}) async {
    final prima =
        nessunoTrovato ? 'Nessun ODL disponibile per il Magazzino $_magDest\n\n' : '';
    final testo = "${prima}Imposta manualmente l'ODL di questa Lista:";
    final r = await invPrompt(context, 'Aggiungi ODL', testo, ['Imposta', 'Annulla'],
        uppercase: true);
    if (r == null || r.button != 0 || !context.mounted) return false;
    final odl = r.text.trim().toUpperCase();

    Map<String, dynamic>? info;
    try {
      info = await service.checkOdlGetFasi(odl);
    } catch (_) {
      if (context.mounted) {
        await invAlert(
            context, 'Errore di Rete', "Impossibile verificare se l' ODL Esiste");
      }
      return false;
    }
    if (!context.mounted) return false;
    if (info == null) {
      await invAlert(context, 'ODL Inesistente', 'Questo ODL non Esiste');
      return false;
    }
    _odl = odl;
    _padre = _s(info['padre']);
    _padreDesc = _s(info['desc_padre']);
    final fasi = info['listaFasi'];
    return _sceltaFase(fasi is List
        ? fasi.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : []);
  }

  Future<bool> _sceltaFase(List<Map<String, dynamic>> fasi) async {
    final scelta = await invSelect(context, 'Seleziona la Fase per questa Lista',
        _unici(fasi.map((f) => _s(f['fase']))));
    if (scelta == null || !context.mounted) return false;
    final f = fasi.firstWhere((f) => _s(f['fase']) == scelta);
    _fase = scelta;
    _faseDesc = _s(f['descrizionefase']);
    return _quantita(_n(f['qta']));
  }

  // ---------------------------------------------------------------------------
  // ODV / POS
  // ---------------------------------------------------------------------------

  Future<bool> _sceltaOdv({bool filtraArticolo = true}) async {
    List<Map<String, dynamic>> odv;
    try {
      odv = await service.odvGetOdv(
          filtraArticolo ? _articolo!.codice : '', magazzinoOrigine, _magDest);
    } catch (_) {
      if (context.mounted) {
        await invAlert(context, 'Errore di Rete',
            'Impossibile scaricare gli ODV per questo Articolo');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (odv.isEmpty) {
      await invAlert(
          context, 'Nessun ODV', 'Nessun ODV disponibile per il Magazzino $_magDest');
      return false;
    }
    final scelto = await invSelect(context, "Seleziona l'Odv per questa Lista",
        _unici(odv.map((o) => _s(o['odv']))));
    if (scelto == null || !context.mounted) return false;

    final posList = odv.where((o) => _s(o['odv']) == scelto).toList();
    _odl = scelto;
    _cliente = _s(posList.last['cliente']);
    _nomeCliente = _s(posList.last['nomecliente']);

    var p = posList.first;
    if (posList.length > 1) {
      final etichette = [for (final x in posList) '${_i(x['pos'])}'];
      final s = await invSelect(
          context, "L'Articolo ha POS multipli. Seleziona la POS", etichette);
      if (s == null || !context.mounted) return false;
      p = posList[etichette.indexOf(s)];
    }
    _pos = _i(p['pos']);
    _seq = _i(p['seq']);
    return _quantita(_n(p['qta']));
  }

  // ---------------------------------------------------------------------------
  // Vano / quantità / riga
  // ---------------------------------------------------------------------------

  Future<bool> _vano() async {
    final r = await invPrompt(
      context,
      'Inserisci Vano di Destinazione',
      'Il Magazzino $_magDest richiede un Vano di Destinazione.\n\nDigita manualmente il Vano:',
      ['Inserisci', 'Annulla'],
      initial: _magDest == 'MGH0001' ? 'UFFICIO' : '',
      uppercase: true,
    );
    if (r == null || r.button != 0 || !context.mounted) return false;
    final vano = r.text.trim().toUpperCase();
    bool esiste;
    try {
      esiste = await service.checkVanoExists(vano);
    } catch (_) {
      if (context.mounted) {
        await invAlert(context, 'Errore di Connessione',
            'Errore di Rete: impossibile verificare se il Vano $vano esiste');
      }
      return false;
    }
    if (!context.mounted) return false;
    if (!esiste) {
      await invAlert(context, 'Vano Inesistente', 'Errore: il Vano $vano non esiste');
      return false;
    }
    _vanoDest = vano;
    return true;
  }

  Future<bool> _quantita(num? qtaDispo) async {
    if (_vanoRequired && _vanoDest.isEmpty) {
      if (!await _vano()) return false;
    }
    if (!context.mounted) return false;
    final a = _articolo!;
    final massimo = a.giacenteSu(magazzinoOrigine);
    final q = await invPromptNumber(
      context,
      'Aggiungi Quantità',
      'Digita la Quantità\n\nUsa il . per i decimali (Es: 12.15)\n\n'
          'Massima giacenza su $magazzinoOrigine: ${formatQta(massimo)}',
      initial: qtaDispo ?? 1,
      confirmText: 'Aggiungi',
    );
    if (q == null || !context.mounted) return false;
    if (q.isNaN) {
      await invAlert(context, 'Errore', 'Quantità non digitata correttamente');
      return false;
    }
    if (q > massimo) {
      await invAlert(
          context, 'Errore', 'La quantità non può essere superiore a quella giacente');
      return false;
    }
    _qta = q;

    lista.insert(
      0,
      RigaListaAut(
        tipoprel: _tipo,
        rifprel: _odl,
        subrifprel: _fase,
        usrcrea: nomePortale,
        articolo: a.codice,
        descarticolo: a.descrizione,
        qta: _qta,
        umis: a.unitaMisura,
        vanoto: _vanoDest,
        qtaconf: _qta,
        magfrom: magazzinoOrigine,
        magto: _magDest,
        fase: _fase,
        descfase: _faseDesc,
        artpadre: _padre,
        descartpadre: _padreDesc,
        cliente: _cliente,
        nomecliente: _nomeCliente,
        pos: _pos,
        seq: _seq,
        vanoRequired: _vanoRequired,
      ),
    );
    invToast(context, 'Articolo ${a.codice} aggiunto');
    return true;
  }
}

