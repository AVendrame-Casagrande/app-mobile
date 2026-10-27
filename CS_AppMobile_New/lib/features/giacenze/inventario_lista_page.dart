import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/inventario.dart';
import '../../state/app_state.dart';
import '../media/photo_picker.dart';
import 'cerca_page.dart';
import 'inventario_dialogs.dart';
import 'inventario_service.dart';

/// Voce visualizzata: una giacenza ancora da confermare o una riga confermata.
class _Voce {
  final InventarioRiga riga;
  final bool confermata;
  const _Voce(this.riga, this.confermata);
}

/// Lista di inventario aperta — porting di drawInnerPageTab1GiacenzeRimaste
/// e activeInnerPageTab1GiacenzeRimasteListeners
/// (www/scripts/Giacenze-Magazzino/Pagine/Inventario).
///
/// Come l'originale mostra un'unica lista: per ogni giacenza rimasta, la riga
/// già confermata (verde) se esiste, altrimenti la giacenza da confermare.
/// Sulle giacenze stato/quantità/foto si modificano in locale e si salvano
/// con "+"; sulle righe confermate le modifiche vanno subito al server.
class InventarioListaPage extends StatefulWidget {
  const InventarioListaPage({
    super.key,
    required this.service,
    required this.testata,
    required this.nomiUtenti,
  });

  final InventarioService service;
  final InventarioTestata testata;
  final Map<String, String> nomiUtenti;

  @override
  State<InventarioListaPage> createState() => _InventarioListaPageState();
}

class _InventarioListaPageState extends State<InventarioListaPage> {
  late final AppState _app;

  InventarioService get _service => widget.service;
  InventarioTestata get _testata => widget.testata;
  String get _utente => _app.utenteLoggato.codiceUtente;

  bool _loading = false;
  String? _error;

  /// listaGiacenzeRimaste (include anche le righe aggiunte manualmente).
  List<InventarioRiga> _giacenze = [];

  /// elencoRigheLista (righe confermate).
  List<InventarioRiga> _righe = [];

  bool _mostraConfermati = true;
  String _filtroArticolo = '';

  /// Righe con un'operazione in corso (clessidra nell'originale).
  final Set<InventarioRiga> _busy = Set.identity();

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _carica();
  }

  Future<void> _carica() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await _service.getContenuto(_testata);
      if (!mounted) return;
      // Le righe manuali vanno anche tra le giacenze (stessa istanza),
      // altrimenti non verrebbero visualizzate.
      final righe = List<InventarioRiga>.of(c.righe);
      final giacenze = <InventarioRiga>[
        ...righe.where((r) => r.aggiuntaManualmente),
        ...c.giacenzeRimaste,
      ];
      setState(() {
        _righe = righe;
        _giacenze = giacenze;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Impossibile scaricare la Lista o l'Elenco delle Giacenze Rimaste";
        _loading = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Supporto
  // -------------------------------------------------------------------------

  String _nomeUtente(String codice) {
    final me = _app.utenteLoggato;
    if (codice == me.codiceUtente) return me.nomeUtente;
    return widget.nomiUtenti[codice] ?? 'Utente Inesistente';
  }

  static String _chiave(InventarioRiga r) =>
      '${r.articolo}|${r.magazzino}|${r.vanoOriginale}';

  /// Porting di getDisplayListHtml(): giacenze filtrate con, al loro posto,
  /// le righe confermate corrispondenti.
  List<_Voce> _voci() {
    final confermate = <String, List<InventarioRiga>>{};
    for (final r in _righe) {
      confermate.putIfAbsent(_chiave(r), () => []).add(r);
    }
    final filtro = _filtroArticolo.toLowerCase();
    final out = <_Voce>[];
    final mostrate = Set<InventarioRiga>.identity();
    for (final g in _giacenze) {
      if (!g.articolo.toLowerCase().startsWith(filtro)) continue;
      final conf = confermate[_chiave(g)];
      if (conf != null && conf.isNotEmpty) {
        if (_mostraConfermati) {
          // Più righe manuali con la stessa chiave non vanno ripetute.
          out.addAll(conf.where(mostrate.add).map((r) => _Voce(r, true)));
        }
      } else {
        out.add(_Voce(g, false));
      }
    }
    return out;
  }

  /// Porting di checkForUncommittedChanges(): modifiche locali non salvate.
  bool get _modifichePresenti => _giacenze.any((g) =>
      !g.aggiuntaManualmente &&
      (g.stato > 1 ||
          g.vanoModificato != g.vanoOriginale ||
          g.qtaOriginale != g.qtaModificata ||
          g.urlFoto.isNotEmpty));

  Future<bool> _confermaPerditaModifiche(String azione, String bottone) async {
    if (!_modifichePresenti) return true;
    final r = await invChoice(
      context,
      'Modifiche non salvate',
      'Hai effettuato delle modifiche alle righe di questa Lista che non sono '
          'state ancora Salvate\n\nSei sicuro di voler $azione e perdere queste modifiche?',
      [bottone, 'Annulla'],
    );
    return r == 0;
  }

  /// Ripete la richiesta finché la rete non torna (come l'originale, che
  /// ritenta ogni secondo). Gli errori HTTP del server vengono propagati.
  Future<T> _conRetry<T>(Future<T> Function() fn, String toastOffline) async {
    var tentativi = 0;
    while (true) {
      try {
        return await fn();
      } on ApiException {
        rethrow;
      } catch (_) {
        tentativi++;
        if (tentativi >= 300) rethrow; // ~5 minuti
        if (tentativi == 1 && mounted) invToast(context, toastOffline);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  void _setBusy(InventarioRiga r, bool busy) {
    if (!mounted) return;
    setState(() => busy ? _busy.add(r) : _busy.remove(r));
  }

  /// Chiude la lista quando il server segnala che non è più attiva.
  Future<void> _gestisciEsitoNonNumerico(String esito) async {
    String? titolo;
    String? msg;
    switch (esito) {
      case 'lista_archiviata':
        titolo = 'LISTA ARCHIVIATA';
        msg = 'Questa Lista è stata Archiviata ed è ora INATTIVA';
      case 'lista_eliminata':
        titolo = 'LISTA ELIMINATA';
        msg = 'Questa Lista è stata Eliminata ed è ora INACCESSIBILE';
      case 'error':
        titolo = 'ERRORE';
        msg = 'Questa Lista ha riscontrato un Errore Imprevisto';
    }
    if (!mounted) return;
    if (titolo != null) {
      await invAlert(context, titolo, msg!);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    // Altrimenti il server ha restituito il codice dell'utente che aveva
    // già confermato la riga.
    await invAlert(context, 'Attenzione',
        'Questo Articolo è già stato Confermato da ${_nomeUtente(esito)}\n\n'
        'Si consiglia di Aggiornare la Pagina');
  }

  bool _bloccaSeAnalizzato(InventarioRiga r) {
    if (!r.analizzato) return false;
    invAlert(context, 'Stato: Analizzato',
        'Non puoi modificare un Articolo già Analizzato');
    return true;
  }

  bool _bloccaSeNonMia(_Voce v) {
    if (!v.confermata || v.riga.utenteInserimento == _utente) return false;
    invAlert(context, 'Impossibile Modificare',
        "Solo l'Utente originale che ha confermato questa riga "
        "( ${_nomeUtente(v.riga.utenteInserimento)} ) può modificarla");
    return true;
  }

  // -------------------------------------------------------------------------
  // Conferma riga (.add → Query.ajaxWriteRigaLista)
  // -------------------------------------------------------------------------

  Future<void> _scriviRiga(InventarioRiga riga, InventarioRiga originale,
      {bool loading = true}) async {
    if (loading) _setBusy(originale, true);
    String esito;
    try {
      esito = await _conRetry(() => _service.writeRigaLista(riga, _utente),
          'Sei offline: Richiesta di conferma Salvata');
    } catch (_) {
      _setBusy(originale, false);
      if (mounted) {
        await invAlert(context, 'Errore di Rete',
            'Impossibile salvare ed aggiungere la Riga');
      }
      return;
    }
    if (!mounted) return;

    final nuova = riga.copy()..utenteInserimento = _utente;

    // La giacenza torna "pulita": verrà nascosta dalla riga confermata.
    originale
      ..stato = 1
      ..urlFoto = ''
      ..qtaModificata = originale.qtaOriginale
      ..vanoModificato = originale.vanoOriginale;

    final id = int.tryParse(esito);
    if (id == null) {
      _setBusy(originale, false);
      await _gestisciEsitoNonNumerico(esito);
      return;
    }
    nuova.id = id;
    setState(() {
      _busy.remove(originale);
      _righe.add(nuova);
    });
    invToast(context, 'Riga Articolo ${riga.articolo} salvata ed aggiunta');
  }

  Future<void> _aggiungi(InventarioRiga g) async {
    if (g.stato == 0) {
      await invAlert(context, 'Stato non Selezionato',
          'Devi selezionare uno Stato prima di poter aggiungere questo Articolo');
      return;
    }
    if (g.stato == 1) {
      await _scriviRiga(g, g);
      return;
    }
    if (!g.haFoto) {
      await invAlert(context, 'Foto Richiesta',
          'Per gli stati Ricondizionato e da Rottamare è richiesto il caricamento di 1 Foto');
      return;
    }

    // Non conforme: si chiede come suddividere la quantità tra gli stati.
    final qtaOriginale = g.qtaOriginale;
    var stato1 = 3, stato2 = 2;
    var testo1 = 'Rottamare', testo2 = 'Ricondizionare';
    if (g.stato == 2) {
      stato1 = 2;
      testo1 = 'Ricondizionare';
      stato2 = 3;
      testo2 = 'Rottamare';
    }

    Future<bool> erroreQta(String msg) async {
      await invAlert(context, 'Errore Quantità', msg);
      return false;
    }

    final qtaRossi = await invPromptNumber(context, 'Quantità $testo1',
        'Quanti Articoli in Stato da $testo1 sono presenti?',
        initial: qtaOriginale);
    if (qtaRossi == null || !mounted) return;
    if (qtaRossi.isNaN) {
      await erroreQta('La quantità non è stata digitata correttamente');
      return;
    }
    if (qtaRossi <= 0) {
      await erroreQta('La quantità dello stato da $testo1 non può essere 0 o inferiore');
      return;
    }
    final riga1 = g.copy()
      ..qtaOriginale = 0
      ..qtaModificata = qtaRossi
      ..stato = stato1;

    if (!mounted) return;
    final qtaArancioni = await invPromptNumber(context, 'Quantità $testo2',
        'Tra questi, ci sono anche Articoli da $testo2? Quanti?',
        initial: 0);
    if (qtaArancioni == null || !mounted) return;
    if (qtaArancioni.isNaN) {
      await erroreQta('La quantità non è stata digitata correttamente');
      return;
    }
    if (qtaArancioni < 0) {
      await erroreQta('La quantità non può essere inferiore a 0');
      return;
    }
    InventarioRiga? riga2;
    if (qtaArancioni > 0) {
      riga2 = g.copy()
        ..qtaOriginale = 0
        ..qtaModificata = qtaArancioni
        ..stato = stato2;
    }

    var defaultConformi = qtaOriginale - qtaRossi - qtaArancioni;
    if (defaultConformi < 0) defaultConformi = 0;
    if (!mounted) return;
    final qtaConformi = await invPromptNumber(context, 'Quantità Conformi',
        'Quanti Articoli Conformi rimangono?',
        initial: defaultConformi);
    if (qtaConformi == null || !mounted) return;
    if (qtaConformi.isNaN) {
      await erroreQta('La quantità non è stata digitata correttamente');
      return;
    }
    if (qtaConformi < 0) {
      await erroreQta('La quantità dei Conformi non può essere inferiore a 0');
      return;
    }

    InventarioRiga conforme() => g.copy()
      ..qtaOriginale = qtaOriginale
      ..qtaModificata = qtaConformi
      ..stato = 1
      ..urlFoto = '';

    InventarioRiga? riga3;
    if (qtaConformi > 0) {
      riga3 = conforme();
    } else if (qtaRossi + qtaArancioni == g.qtaModificata) {
      riga1.qtaOriginale = riga1.qtaModificata;
    } else {
      riga3 = conforme();
    }

    // Il secondo stato non conforme richiede una sua foto.
    if (riga2 != null) {
      final nome = await _caricaFotoFile(riga2, g);
      if (nome == null) return;
      riga2.urlFoto = nome;
      await Future.wait([
        _scriviRiga(riga1, g),
        _scriviRiga(riga2, g, loading: false),
        if (riga3 != null) _scriviRiga(riga3, g, loading: false),
      ]);
      return;
    }

    await Future.wait([
      _scriviRiga(riga1, g),
      if (riga3 != null) _scriviRiga(riga3, g, loading: false),
    ]);
  }

  // -------------------------------------------------------------------------
  // Elimina riga confermata (.delete → eliminaRiga.php)
  // -------------------------------------------------------------------------

  Future<void> _elimina(InventarioRiga r) async {
    if (_bloccaSeAnalizzato(r)) return;

    final altriStati = _righe
        .where((x) =>
            !identical(x, r) &&
            x.articolo == r.articolo &&
            x.vanoModificato == r.vanoModificato &&
            x.magazzino == r.magazzino &&
            x.stato != r.stato)
        .toList();

    List<InventarioRiga> daEliminare;
    if (altriStati.isEmpty) {
      final scelta = await invChoice(
        context,
        'Elimina Riga',
        "Vuoi Eliminare e Ripristinare la Riga dell'Articolo ${r.articolo} "
            'e farla tornare sui Non Confermati?',
        ['Elimina', 'Annulla'],
      );
      if (scelta != 0) return;
      daEliminare = [r];
    } else {
      final n = altriStati.length + 1;
      final scelta = await invChoice(
        context,
        'Elimina Riga',
        'Sono stati trovati $n Articoli ${r.articolo} con Stato diverso.\n\n'
            'Vuoi Eliminare e Ripristinare solo questo o tutti e $n ( consigliato ) '
            "e riportare l'Articolo sui Non Confermati?",
        ['Elimina Questo', 'Elimina Tutti', 'Annulla'],
      );
      if (scelta == null || scelta == 2) return;
      daEliminare = scelta == 0 ? [r] : [r, ...altriStati];
    }

    for (final riga in daEliminare) {
      if (!mounted) return;
      if (riga.utenteInserimento != _utente) {
        await invAlert(context, 'Impossibile Eliminare',
            'Solo chi ha inserito questa Riga ha i permessi di Eliminarla');
        continue;
      }
      await _eliminaRiga(riga);
    }
  }

  Future<void> _eliminaRiga(InventarioRiga riga) async {
    _setBusy(riga, true);
    bool ok;
    try {
      ok = await _conRetry(() => _service.eliminaRiga(riga.id),
          'Sei offline: Richiesta di eliminazione Salvata');
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      _setBusy(riga, false);
      await invAlert(context, 'Errore',
          "Errore dell'API inventario: Riga non Eliminata. Riprova");
      return;
    }
    setState(() {
      _busy.remove(riga);
      _righe.removeWhere((x) => identical(x, riga));
      if (riga.aggiuntaManualmente) {
        _giacenze.removeWhere((x) => identical(x, riga));
      }
    });
    invToast(context, '${riga.articolo} eliminato');
  }

  // -------------------------------------------------------------------------
  // Foto (.foto → openCameraDialog 'inventario' / updateRigaInventario url_foto)
  // -------------------------------------------------------------------------

  /// Scatta/sceglie e carica una foto per [riga]. Ritorna il nome del file
  /// caricato, o null se annullato/errore. [busyRow] mostra il caricamento.
  Future<String?> _caricaFotoFile(InventarioRiga riga, InventarioRiga busyRow) async {
    final bytes = await PhotoPicker.pick(context);
    if (bytes == null || !mounted) return null;
    final nome = InventarioService.nomeFoto(riga, _utente);
    _setBusy(busyRow, true);
    bool ok;
    try {
      ok = await _service.uploadFoto(riga, nome, bytes);
    } catch (_) {
      ok = false;
    }
    _setBusy(busyRow, false);
    if (!ok) {
      if (mounted) {
        await invAlert(context, 'Errore di Rete',
            'Foto di ${riga.articolo} non caricata. Riprova');
      }
      return null;
    }
    return nome;
  }

  Future<void> _caricaFoto(_Voce v) async {
    final riga = v.riga;
    final nome = await _caricaFotoFile(riga, riga);
    if (nome == null || !mounted) return;
    setState(() => riga.urlFoto = nome);
    if (!v.confermata) {
      invToast(context, 'Foto di ${riga.articolo} caricata con successo');
      return;
    }
    bool ok;
    try {
      ok = await _service.updateRiga(riga.id,
          tipoModifica: 'url_foto', urlFoto: nome);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      invToast(context, 'Foto di ${riga.articolo} caricata con successo');
    } else {
      await invAlert(context, 'Errore',
          'Errore di Rete: Foto non Caricata sul Database. Riprova');
    }
  }

  Future<void> _foto(_Voce v) async {
    final riga = v.riga;
    if (!riga.haFoto) {
      await _caricaFoto(v);
      return;
    }
    final scelta = await invChoice(
      context,
      'Foto ${riga.articolo}',
      "La Foto dell' Articolo ${riga.articolo} è già stata scattata.\n\nCosa vuoi fare?",
      ['Visualizza', 'Cambia', 'Rimuovi'],
    );
    if (!mounted) return;
    switch (scelta) {
      case 0:
        await _apriUrl(InventarioService.urlFoto(riga.urlFoto));
      case 1:
        await _caricaFoto(v);
      case 2:
        if (!v.confermata) {
          setState(() => riga.urlFoto = '');
          invToast(context, 'Foto rimossa con Successo');
          return;
        }
        bool ok;
        try {
          ok = await _service.updateRiga(riga.id,
              tipoModifica: 'url_foto', urlFoto: '');
        } catch (_) {
          ok = false;
        }
        if (!mounted) return;
        if (ok) {
          setState(() => riga.urlFoto = '');
          invToast(context, 'Foto rimossa con Successo');
        } else {
          await invAlert(context, 'Errore', 'Errore di Rete: Foto non rimossa');
        }
    }
  }

  // -------------------------------------------------------------------------
  // Quantità (.qta)
  // -------------------------------------------------------------------------

  Future<void> _modificaQta(_Voce v) async {
    final riga = v.riga;
    if (_bloccaSeAnalizzato(riga) || _bloccaSeNonMia(v)) return;
    if (riga.aggiuntaManualmente) {
      await invAlert(context, 'Impossibile Modificare Quantità',
          'Non puoi modificare la Quantità di un Articolo aggiunto manualmente');
      return;
    }
    if (riga.stato != 1) {
      await invAlert(context, 'Impossibile Modificare Quantità',
          'Puoi modificare la Quantità solo per gli articoli Conformi');
      return;
    }

    final qta = await invPromptNumber(
      context,
      'Modifica Quantità',
      'Modifica la Quantità per questo articolo\n\nUsa il . per i decimali (Es: 12.15)',
      initial: riga.qtaModificata,
      confirmText: 'Modifica',
    );
    if (qta == null || !mounted) return;
    if (qta.isNaN) {
      await invAlert(context, 'Errore', 'Quantità non digitata correttamente');
      return;
    }

    if (!v.confermata) {
      setState(() => riga.qtaModificata = qta);
      return;
    }

    _setBusy(riga, true);
    bool ok;
    try {
      ok = await _conRetry(
          () => _service.updateRiga(riga.id, tipoModifica: 'qta', qtaModificata: qta),
          'Sei offline: Richiesta di aggiornamento Salvata');
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    _setBusy(riga, false);
    if (!ok) {
      await invAlert(context, 'Errore',
          "Errore dell'API inventario: Riga non aggiornata. Riprova");
      return;
    }
    setState(() => riga.qtaModificata = qta);
    invToast(context, 'Quantità di ${riga.articolo} aggiornata');
  }

  // -------------------------------------------------------------------------
  // Stato + nota (.stato)
  // -------------------------------------------------------------------------

  Future<void> _modificaStato(_Voce v) async {
    final riga = v.riga;
    if (_bloccaSeAnalizzato(riga) || _bloccaSeNonMia(v)) return;
    if (riga.qtaOriginale != riga.qtaModificata) {
      await invAlert(context, 'Impossibile Aggiornare Stato',
          'Non puoi cambiare lo stato Conforme di questo Articolo se ne hai modificato le Quantità');
      return;
    }

    final r = await invPrompt(
      context,
      'Aggiorna lo Stato',
      'Seleziona il nuovo Stato per questo Articolo\n\nPuoi anche inserire una '
          'Nota Opzionale:\n(oppure scrivi solo E per eliminarla)',
      ['Conforme', 'Ricondizionato', 'Rottamare', 'Annulla'],
      initial: riga.nota,
    );
    if (r == null || r.button == 3 || !mounted) return;
    final stato = r.button + 1;
    final nota = r.text.toUpperCase() == 'E' ? '' : r.text;

    if (!v.confermata) {
      setState(() {
        riga.stato = stato;
        riga.nota = nota;
      });
      return;
    }

    final duplicato = _righe.any((x) =>
        x.articolo == riga.articolo &&
        x.vanoModificato == riga.vanoModificato &&
        x.id != riga.id &&
        x.stato == stato);
    if (duplicato) {
      await invAlert(context, 'Impossibile Aggiornare Stato',
          'Esiste già un Articolo ${riga.articolo} con questo Stato nella Lista');
      return;
    }
    if (stato > 1 && !riga.haFoto) {
      await invAlert(context, 'Foto Richiesta',
          'Per gli stati Ricondizionato e da Rottamare è richiesto il caricamento di 1 Foto');
      return;
    }

    bool ok;
    try {
      ok = await _service.updateRiga(riga.id,
          tipoModifica: 'stato_nota', stato: stato, nota: nota);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      await invAlert(context, 'Errore', 'Errore di Rete: Riga non aggiornata. Riprova');
      return;
    }
    setState(() {
      riga.stato = stato;
      riga.nota = nota;
    });
    invToast(context, 'Stato / Nota di ${riga.articolo} aggiornato');
  }

  // -------------------------------------------------------------------------
  // Link articolo / disegno (.linkArticolo)
  // -------------------------------------------------------------------------

  Future<void> _link(InventarioRiga riga) async {
    final scelta = await invChoice(
      context,
      'Articolo ${riga.articolo}',
      'Descrizione: ${riga.descrizione.toLowerCase()}',
      ['Link Articolo', 'Apri Disegno', 'Chiudi'],
    );
    if (!mounted) return;
    if (scelta == 0) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CercaPage(codiceArticolo: riga.articolo)));
    } else if (scelta == 1) {
      await _apriDisegno(riga.articolo);
    }
  }

  Future<void> _apriDisegno(String articolo) async {
    List<PdfArticolo> pdf;
    try {
      pdf = await _service.getPdfList(articolo);
    } catch (_) {
      if (mounted) invToast(context, 'Errore durante lo scaricamento del PDF');
      return;
    }
    if (!mounted) return;
    if (pdf.isEmpty) {
      await invAlert(
          context, 'Nessun PDF', "Non esiste nessun disegno PDF per l'articolo $articolo");
      return;
    }
    if (pdf.length == 1) {
      await _apriUrl(pdf.first.url);
      return;
    }
    final scelto = await invSelect(context,
        'PDF Multipli. Seleziona il PDF che vuoi aprire:', [for (final p in pdf) p.shortUrl]);
    if (scelto == null) return;
    final match = pdf.where((p) => p.shortUrl == scelto);
    if (match.isNotEmpty) await _apriUrl(match.first.url);
  }

  Future<void> _apriUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) invToast(context, 'Impossibile aprire il file');
  }

  // -------------------------------------------------------------------------
  // Riga manuale (#addRigaManuale → addArticoloManuale → writeCustomRigaLista)
  // -------------------------------------------------------------------------

  Future<void> _rigaManuale() async {
    final r = await invPrompt(
      context,
      'Aggiunta Articolo Manuale',
      'Aggiungi un Articolo manualmente\n\nDigita il codice Articolo da aggiungere:',
      ['Aggiungi', 'Annulla'],
      uppercase: true,
    );
    if (r == null || r.button != 0 || !mounted) return;
    final codice = r.text.trim().toUpperCase();
    if (codice.isEmpty) return;

    var articolo = codice;
    var descrizione = '';
    var um = '';
    var offline = '';
    try {
      final a = await _service.getArticolo(codice);
      if (!mounted) return;
      if (a == null) {
        await invAlert(context, 'Articolo Non trovato',
            "L'articolo con codice $codice non esiste. Riprova");
        return;
      }
      articolo = a.codice;
      descrizione = a.descrizione;
      um = a.um;
    } on ApiException {
      if (mounted) {
        await invAlert(context, 'Errore', 'Errore del Server: articolo non verificato');
      }
      return;
    } catch (_) {
      // Offline: si procede col solo codice, come l'originale.
      descrizione = 'descrizione non trovata (offline)';
      offline = '(offline) ';
    }
    if (!mounted) return;

    final qta = await invPromptNumber(
      context,
      '${offline}Imposta Quantità',
      'Imposta la Quantità per questo Articolo Manuale\n\nUsa il . per i decimali (Es: 12.15)',
      initial: 1,
      confirmText: 'Imposta',
    );
    if (qta == null || !mounted) return;
    if (qta.isNaN) {
      await invAlert(context, 'Errore', 'Quantità non digitata correttamente');
      return;
    }

    // Vano / magazzino in base al tipo di lista.
    final tipo = _testata.tipoLista;
    var magazzino = '';
    var vano = '';
    if (tipo == 'magazzino') magazzino = _testata.nomeLista;
    if (tipo == 'vano_preciso') vano = _testata.nomeLista;

    if (tipo == 'magazzino' || tipo == 'vano_radice') {
      final v = await _chiediValore('Vano', offline,
          [..._giacenze.map((g) => g.vanoModificato), ..._righe.map((g) => g.vanoModificato)]);
      if (v == null || !mounted) return;
      final vuotoAmmesso = tipo == 'magazzino' && v.isEmpty;
      if (!vuotoAmmesso && offline.isEmpty) {
        bool esiste;
        try {
          esiste = await _service.checkVanoExists(v);
        } catch (_) {
          if (mounted) {
            await invAlert(context, 'Error di Connessione',
                'Errore di Rete: impossibile verificare se il Vano $v esiste');
          }
          return;
        }
        if (!mounted) return;
        if (!esiste) {
          await invAlert(context, 'Vano Inesistente', 'Errore: il Vano $v non esiste');
          return;
        }
      }
      vano = v;
    }

    if (tipo == 'vano_preciso' || tipo == 'vano_radice') {
      final m = await _chiediValore('Magazzino', offline,
          [..._giacenze.map((g) => g.magazzino), ..._righe.map((g) => g.magazzino)]);
      if (m == null || !mounted) return;
      if (offline.isEmpty) {
        bool esiste;
        try {
          esiste = await _service.checkMagazzinoExists(m);
        } catch (_) {
          if (mounted) {
            await invAlert(context, 'Error di Connessione',
                'Errore di Rete: impossibile verificare se il Magazzino $m esiste');
          }
          return;
        }
        if (!mounted) return;
        if (!esiste) {
          await invAlert(
              context, 'Magazzino Inesistente', 'Errore: il Magazzino $m non esiste');
          return;
        }
      }
      magazzino = m;
    }

    final giaPresente = _giacenze.any((g) =>
        g.articolo == articolo && g.magazzino == magazzino && g.vanoOriginale == vano);
    if (giaPresente) {
      await invAlert(context, 'Attenzione',
          "Questo Articolo è già presente nella lista delle Giacenze Non Confermate e non necessita l'aggiunta Manuale");
      return;
    }

    final s = await invChoice(context, '${offline}Imposta Stato',
        'Seleziona lo Stato di questo Articolo', ['Conforme', 'Ricondizionato', 'Rottamare']);
    if (s == null || !mounted) return;
    final stato = s + 1;

    final riga = InventarioRiga(
      idListaTestata: _testata.id,
      articolo: articolo,
      descrizione: descrizione,
      magazzino: magazzino,
      vanoOriginale: vano,
      vanoModificato: vano,
      qtaOriginale: 0,
      qtaModificata: qta,
      stato: stato,
      utenteInserimento: _utente,
      rigaAggiuntaManualmente: 1,
      um: um,
    );

    if (stato > 1) {
      // Per gli stati non conformi la foto è obbligatoria.
      final nome = await _caricaFotoFile(riga, riga);
      if (nome == null) return;
      riga.urlFoto = nome;
    }
    await _scriviRigaManuale(riga);
  }

  /// Selettore valori esistenti con "Non trovo il …" → inserimento manuale.
  Future<String?> _chiediValore(
      String proprieta, String offline, Iterable<String> valori) async {
    final unici = <String>[];
    for (final v in valori) {
      if (!unici.contains(v)) unici.add(v);
    }
    final scelto = await invSelect(context, '${offline}Imposta il $proprieta', unici,
        extraButton: 'Non trovo il $proprieta');
    if (scelto == null || !mounted) return null;
    if (scelto != invSelectExtra) return scelto.toUpperCase();
    final r = await invPrompt(context, '${offline}Imposta $proprieta',
        'Imposta il $proprieta per questo Articolo', ['Imposta', 'Annulla'],
        uppercase: true);
    if (r == null || r.button != 0) return null;
    return r.text.trim().toUpperCase();
  }

  Future<void> _scriviRigaManuale(InventarioRiga riga) async {
    invToast(context, 'Caricamento Articolo ${riga.articolo} in corso..');
    String esito;
    try {
      esito = await _conRetry(() => _service.writeRigaLista(riga, _utente),
          'Sei offline: Richiesta di aggiunta Articolo Salvata');
    } catch (_) {
      if (mounted) {
        await invAlert(context, 'Errore di Rete', 'Impossibile Aggiungere la Riga');
      }
      return;
    }
    if (!mounted) return;
    final id = int.tryParse(esito);
    if (id == null) {
      await _gestisciEsitoNonNumerico(esito);
      return;
    }
    final nuova = riga.copy()..id = id;
    setState(() {
      // Una riga manuale va in entrambe le liste (stessa istanza).
      _giacenze.add(nuova);
      _righe.add(nuova);
    });
    invToast(context, 'Riga Articolo ${riga.articolo} salvata ed aggiunta');
  }

  // -------------------------------------------------------------------------
  // Filtro / refresh
  // -------------------------------------------------------------------------

  Future<void> _filtro() async {
    final r = await invPrompt(
      context,
      'Filtro',
      'Filtra per Articolo (anche parziale).\n\nNascondi o Visualizza gli '
          'Articoli già Confermati\n\nFiltro Articolo corrente: $_filtroArticolo',
      ['Filtra Articolo', 'Visualizza i confermati', 'Nascondi i confermati'],
      initial: _filtroArticolo,
      uppercase: true,
    );
    if (r == null || !mounted) return;
    switch (r.button) {
      case 0:
        setState(() => _filtroArticolo = r.text.trim());
        invToast(context, 'Filtro articolo per: ${r.text.trim()}');
      case 1:
        setState(() => _mostraConfermati = true);
        invToast(context, 'Visualizzati anche gli articoli già Confermati');
      case 2:
        setState(() => _mostraConfermati = false);
        invToast(context, 'Nascosti gli articoli già Confermati');
    }
  }

  Future<void> _refresh() async {
    if (await _confermaPerditaModifiche('aggiornare', 'Aggiorna')) {
      await _carica();
    }
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final voci = _loading || _error != null ? const <_Voce>[] : _voci();
    final filtroAttivo = !_mostraConfermati || _filtroArticolo.isNotEmpty;

    return PopScope(
      canPop: !_modifichePresenti,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confermaPerditaModifiche('uscire', 'Esci') && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_testata.nomeLista} ( ${_testata.tipoAbbreviato} )'),
              if (!_loading && _error == null)
                Text('Articoli: ${voci.length}',
                    style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Filtro',
              icon: Icon(Icons.filter_alt,
                  color: filtroAttivo ? Colors.amberAccent : null),
              onPressed: _filtro,
            ),
            IconButton(
              tooltip: 'Aggiorna',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
        ),
        floatingActionButton: _loading || _error != null
            ? null
            : FloatingActionButton(
                tooltip: 'Aggiungi Articolo manuale',
                onPressed: _rigaManuale,
                child: const Icon(Icons.add),
              ),
        body: _buildBody(voci),
      ),
    );
  }

  Widget _buildBody(List<_Voce> voci) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _carica, child: const Text('Riprova')),
          ],
        ),
      );
    }
    if (voci.isEmpty) {
      return const Center(child: Text('Nessun articolo'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: voci.length,
      itemBuilder: (_, i) => _rigaWidget(voci[i], i),
    );
  }

  static Color _coloreStato(int stato) {
    switch (stato) {
      case 1:
        return const Color(0xFF7CFC00); // lawngreen
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
    }
    return Colors.white;
  }

  Widget _rigaWidget(_Voce v, int index) {
    final r = v.riga;
    final busy = _busy.contains(r);
    final bg = v.confermata
        ? const Color(0xFFDFF5D8)
        : (index.isEven ? Colors.white : const Color(0xFFF2F2F2));

    String vanoText;
    String? magazzinoText;
    switch (_testata.tipoLista) {
      case 'vano_preciso':
        vanoText = r.magazzino;
      case 'vano_radice':
        vanoText = r.vanoModificato;
        magazzinoText = r.magazzino;
      default:
        vanoText = r.vanoModificato;
    }

    final descr = r.descrizione.toLowerCase();
    final descrBreve = descr.length > 35 ? descr.substring(0, 35) : descr;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // Stato + foto
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: busy ? null : () => _modificaStato(v),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _coloreStato(r.stato),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black38),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: busy ? null : () => _foto(v),
                icon: Icon(r.haFoto ? Icons.photo_library : Icons.photo_camera,
                    color: const Color(0xFF5966A8)),
              ),
            ],
          ),
          // Articolo / descrizione
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.articolo}${r.um.isNotEmpty ? ' (${r.um})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(descrBreve, style: const TextStyle(fontSize: 13)),
                if (r.nota.isNotEmpty)
                  Text('Nota: ${r.nota}',
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          // Quantità / vano / magazzino
          SizedBox(
            width: 96,
            child: Column(
              children: [
                InkWell(
                  onTap: busy ? null : () => _modificaQta(v),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _qtaWidget(r),
                  ),
                ),
                Text(vanoText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13)),
                if (magazzinoText != null)
                  Text(magazzinoText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          // Link + conferma/elimina
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _link(r),
                icon: const Icon(Icons.link, color: Color(0xFF5966A8)),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (v.confermata)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Elimina',
                  onPressed: () => _elimina(r),
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Conferma',
                  onPressed: () => _aggiungi(r),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2E7D32)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtaWidget(InventarioRiga r) {
    if (r.qtaModificata == r.qtaOriginale) {
      return Text(formatQta(r.qtaModificata),
          style: const TextStyle(fontWeight: FontWeight.bold));
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: formatQta(r.qtaModificata),
            style: const TextStyle(
                color: Color(0xFF8B0000), fontWeight: FontWeight.bold)),
        const TextSpan(text: '  '),
        TextSpan(
            text: '( ${formatQta(r.qtaOriginale)} )',
            style: const TextStyle(decoration: TextDecoration.lineThrough)),
      ]),
      textAlign: TextAlign.center,
    );
  }
}
