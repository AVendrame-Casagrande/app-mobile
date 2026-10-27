import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../chat/chat_service.dart';
import '../giacenze/inventario_dialogs.dart';
import '../scanner/barcode_scanner_page.dart';
import 'lista_precarico_service.dart';

/// Lista di Pre-Carico corrente: come in Cordova (produzione.listaPrecaricoCorrente)
/// resta finché l'app è aperta, anche uscendo dalla pagina.
class PrecaricoStore {
  PrecaricoStore._();
  static ListaPrecarico corrente = ListaPrecarico();
}

/// Pagina Produzione → Lista Pre-Carico — porting di
/// www/scripts/Produzione-Odl/Pagine/ListaPrecarico.
///
/// Si compila una lista di articoli da ricaricare su un magazzino (ODL/fase o
/// nome libero), la si invia (con un'Attività per ACEMA e il PDF) e la si può
/// ritrovare nello storico per visualizzarla, modificarla, eliminarla o
/// segnarla come revisionata. Gli utenti CQC lavorano in EN-V/Arm e scelgono
/// gli articoli dalle giacenze di MGCQ001.
class ListaPrecaricoPage extends StatefulWidget {
  const ListaPrecaricoPage({super.key});

  @override
  State<ListaPrecaricoPage> createState() => _ListaPrecaricoPageState();
}

class _ListaPrecaricoPageState extends State<ListaPrecaricoPage> {
  late final ListaPrecaricoService _service;
  late final AppState _app;
  bool _busy = false;
  Map<String, String>? _nomiUtenti;

  ListaPrecarico get _lista => PrecaricoStore.corrente;
  String get _utente => _app.utenteLoggato.codiceUtente;
  bool get _isCqc => _utente.startsWith('CQC');
  bool get _isCpr => _utente.startsWith('CPR');
  String get _enx => _isCqc ? 'ENV' : 'ENX';
  String get _labelNota => _isCqc ? 'Arm o Nota' : 'Nota';

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _service = ListaPrecaricoService(_app.api);
  }

  void _setBusy(bool v) {
    if (mounted) setState(() => _busy = v);
  }

  /// checkBottomButtons(): svuotando la lista si azzera tutto.
  void _dopoModificaRighe() {
    if (_lista.righe.isEmpty) PrecaricoStore.corrente = ListaPrecarico();
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Nuova lista (emptyListAddOdlFaseMagazzino)
  // ---------------------------------------------------------------------------

  /// Chiede ODL/nome, fase e magazzino quando la lista è vuota.
  Future<bool> _impostaTestata() async {
    final now = DateTime.now();
    final r = await invPrompt(
      context,
      'Nuova Lista di Pre-Carico',
      _isCqc
          ? 'Digita un Nome libero ( max 10 caratteri ) per questa Lista:\n\n'
              'Se premi OK con il campo vuoto, il nome verrà generato automaticamente'
          : 'Digita un ODL o un Nome libero ( max 10 caratteri ) per questa Lista:\n\n'
              'Se premi OK con il campo vuoto, il nome verrà generato automaticamente',
      ['OK', 'Annulla'],
      uppercase: true,
    );
    if (r == null || r.button != 0 || !mounted) return false;

    var odl = r.text.trim();
    if (odl.length > 10) odl = odl.substring(0, 10);
    odl = odl.replaceAll(' ', '_');
    var fase = _isCqc ? DateFormat('ddMM').format(now) : '';
    var padre = '';
    var padreDesc = '';

    if (odl.isEmpty) {
      odl = DateFormat('yyyyMMdd').format(now);
      fase = DateFormat('HHmm').format(now);
    } else if (fase.isEmpty) {
      try {
        final info = await _service.getPadreOdl(odl);
        if (info != null) {
          padre = info.$1;
          padreDesc = info.$2;
        }
      } catch (_) {}
      if (!mounted) return false;
      final f = await invPrompt(context, 'Fase',
          'Digita la Fase o un Nome secondario ( max 4 caratteri ) per questa lista:',
          ['OK', 'Annulla'],
          initial: '0065');
      if (f == null || f.button != 0 || !mounted) return false;
      fase = f.text.trim();
      if (fase.length > 4) fase = fase.substring(0, 4);
      if (fase.isEmpty) fase = DateFormat('HHmm').format(now);
    }

    final predefinito = _utente == 'CPR010'
        ? 'MGPUL01'
        : _isCqc
            ? 'MGCQ001'
            : 'MG00020';
    final m = await invPrompt(context, 'Magazzino', 'Digita il Magazzino:', ['OK', 'Annulla'],
        initial: predefinito, uppercase: true);
    if (m == null || m.button != 0 || !mounted) return false;

    _lista
      ..odl = odl.replaceAll('/', '_')
      ..fase = fase.replaceAll('/', '_')
      ..magazzino = m.text.trim().toUpperCase()
      ..padre = padre
      ..padreDescrizione = padreDesc;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Aggiunta articoli
  // ---------------------------------------------------------------------------

  Future<void> _aggiungiDaDialog() async {
    if (_lista.righe.isEmpty && !await _impostaTestata()) return;
    if (!mounted) return;
    final r = await invPrompt(context, 'Aggiungi al Pre-Carico',
        'Digita il codice Articolo da aggiungere:', ['Aggiungi', 'Annulla'],
        uppercase: true);
    if (r == null || r.button != 0 || !mounted) return;
    await _verificaEAggiungi(r.text.trim());
  }

  Future<void> _aggiungiDaScanner() async {
    if (_lista.righe.isEmpty && !await _impostaTestata()) return;
    if (!mounted) return;
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra articolo');
    if (code == null || !mounted) return;
    await _verificaEAggiungi(code.trim());
  }

  /// checkAndAddArticolo: non duplicato, esistente; poi (CQC) Arm e quantità.
  Future<void> _verificaEAggiungi(String codice) async {
    codice = codice.toUpperCase();
    if (codice.isEmpty) return;
    if (_lista.righe.any((r) => r.articolo == codice)) {
      await invAlert(context, 'Articolo Duplicato', "L'articolo $codice è già presente nella Lista");
      return;
    }
    _setBusy(true);
    ArticoloPrecarico? a;
    try {
      a = await _service.getArticolo(codice);
    } catch (_) {
      a = null;
    }
    _setBusy(false);
    if (!mounted) return;
    if (a == null) {
      await invAlert(
          context, 'Articolo Non trovato', "L'articolo con codice $codice non esiste. Riprova");
      return;
    }

    var nota = '';
    if (_isCqc) {
      final n = await invPrompt(context, 'Inserisci ARM',
          "Inserisci l'Arm di riferimento o una Nota per l'Articolo ${a.codice}:",
          ['Inserisci', 'Annulla']);
      if (n == null || n.button != 0 || !mounted) return;
      nota = n.text;
    }

    final q = await invPromptNumber(
      context,
      _isCqc ? 'Inserisci EN-V' : 'Inserisci Quantità',
      '${_isCqc ? 'Digita il numero di EN-V per questo Articolo' : 'Digita la Quantità'}'
          '\n\nUsa il . per i decimali (Es: 12.15)',
      initial: 1,
      confirmText: 'Inserisci',
    );
    if (q == null || !mounted) return;
    if (q.isNaN) {
      await invAlert(context, 'Errore', 'Quantità non digitata correttamente');
      return;
    }

    final riga = _isCqc
        ? RigaPrecarico(
            articolo: a.codice, descrizione: a.descrizione, um: a.unitaMisura, qta: 0, qtaEnx: q)
        : RigaPrecarico(articolo: a.codice, descrizione: a.descrizione, um: a.unitaMisura, qta: q);
    riga.nota = nota;
    _impostaTrasferimenti(a, riga);
    setState(() => _lista.righe.add(riga));
  }

  /// setRigalistaRientriTrasferimenti: magazzini (non MISK/MGAUT/della lista)
  /// con disponibilità da cui trasferire l'articolo.
  void _impostaTrasferimenti(ArticoloPrecarico a, RigaPrecarico riga) {
    for (final (mag, giacente, impegnato) in a.magazzini) {
      final disponibile = giacente - (impegnato < 0 ? 0 : impegnato);
      if (disponibile <= 0) continue;
      if (mag.startsWith('MISK') || mag.startsWith('MGAUT') || mag == _lista.magazzino) continue;
      riga.trasferimenti.add(Trasferimento(mag, disponibile));
    }
  }

  /// CQC: scelta dell'articolo dalle giacenze del magazzino (MGCQ001).
  Future<void> _aggiungiDaGiacenze() async {
    final magazzino = _lista.magazzino.isEmpty ? 'MGCQ001' : _lista.magazzino;
    _setBusy(true);
    List<GiacenzaPrecarico> giacenze;
    try {
      giacenze = await _service.getGiacenze(magazzino);
    } catch (_) {
      _setBusy(false);
      if (mounted) {
        await invAlert(context, 'Errore di Rete',
            'Errore di Rete o del Server: impossibile scaricare la Lista delle Giacenze per $magazzino');
      }
      return;
    }
    _setBusy(false);
    if (!mounted) return;

    final etichette = [
      for (final g in giacenze)
        '${g.articolo} (${g.descrizione.toLowerCase().length > 10 ? g.descrizione.toLowerCase().substring(0, 10) : g.descrizione.toLowerCase()})'
    ];
    final s = await invSelect(context, 'Seleziona Articolo', etichette);
    if (s == null || !mounted) return;
    final g = giacenze[etichette.indexOf(s)];

    if (_lista.righe.any((r) => r.articolo == g.articolo)) {
      await invAlert(context, 'Articolo Duplicato',
          "L'articolo ${g.articolo} è già presente nella Lista");
      return;
    }
    final q = await invPromptNumber(context, 'Quantità',
        '${g.descrizione.toLowerCase()}\n\nDigita la Quantità\n\nUsa il . per i decimali (Es: 12.15)');
    if (q == null || !mounted) return;
    if (q.isNaN) {
      await invAlert(context, 'Quantità Errata', 'La quantità inputata non è un numero');
      return;
    }
    if (q > g.qtaGiacente) {
      await invAlert(context, 'Quantità Errata',
          'La quantità inputata ( ${formatQta(q)} ) è superiore alla giacenza attuale ( ${formatQta(g.qtaGiacente)} )');
      return;
    }

    if (_lista.righe.isEmpty) {
      final n = await invPrompt(
        context,
        'Nome Lista',
        'Dai un nome a questa lista. Max 10 caratteri. Se lasci il campo vuoto: '
            'verrà creato un nome automatico',
        ['OK', 'Annulla'],
      );
      if (n == null || n.button != 0 || !mounted) return;
      final now = DateTime.now();
      var nome = n.text.trim();
      var secondario = DateFormat('ddMM').format(now);
      if (nome.isEmpty) {
        nome = DateFormat('yyyyMMdd').format(now);
        secondario = DateFormat('HHmm').format(now);
      }
      if (nome.length > 10) nome = nome.substring(0, 10);
      _lista
        ..odl = nome.replaceAll(' ', '_').replaceAll('/', '_')
        ..magazzino = 'MGCQ001'
        ..fase = secondario;
    }
    setState(() => _lista.righe.add(
        RigaPrecarico(articolo: g.articolo, descrizione: g.descrizione, um: g.um, qta: q)));
  }

  // ---------------------------------------------------------------------------
  // Modifica righe
  // ---------------------------------------------------------------------------

  Future<void> _modificaQta(RigaPrecarico r) async {
    final q = await invPromptNumber(context, 'Modifica Quantità',
        "Modifica la Quantità per l'Articolo ${r.articolo}\n\nUsa il . per i decimali (Es: 12.15)",
        initial: r.qtaOriginale, confirmText: 'Aggiorna');
    if (q == null || !mounted) return;
    if (q.isNaN) {
      await invAlert(context, 'Errore Quantità', 'La quantità non è stata digitata correttamente');
      return;
    }
    final cambiata = q != r.qta;
    setState(() => r.qta = q);
    if (cambiata) invToast(context, 'Quantità aggiornata');
  }

  Future<void> _modificaEnx(RigaPrecarico r) async {
    final enx = _isCqc ? 'EN-V' : 'EN-X';
    final q = await invPromptNumber(context, 'Modifica $enx',
        "Modifica la Quantità ( $enx ) per l'Articolo ${r.articolo}\n\nUsa il . per i decimali (Es: 12.15)",
        initial: r.qtaEnx, confirmText: 'Aggiorna');
    if (q == null || !mounted) return;
    if (q.isNaN) {
      await invAlert(context, 'Errore Quantità', 'La quantità non è stata digitata correttamente');
      return;
    }
    final cambiata = q != r.qtaEnx;
    setState(() => r.qtaEnx = q);
    if (cambiata) invToast(context, 'Quantità $enx aggiornata');
  }

  Future<void> _modificaNota(RigaPrecarico r) async {
    final azione = r.nota.isEmpty ? 'Aggiungi' : 'Modifica';
    final n = await invPrompt(
      context,
      '$azione $_labelNota',
      "$azione $_labelNota per l' Articolo ${r.articolo}\n\n$_labelNota corrente: ${r.nota}",
      [azione, 'Chiudi'],
      initial: r.nota,
    );
    if (n == null || n.button != 0 || !mounted) return;
    setState(() => r.nota = n.text);
    invToast(context, '$_labelNota di ${r.articolo} modificata');
  }

  Future<void> _rimuovi(RigaPrecarico r) async {
    final s = await invChoice(context, 'Rimuovi Articolo',
        "Vuoi rimuovere l'Articolo ${r.articolo} dalla Lista?", ['Rimuovi', 'Chiudi']);
    if (s != 0 || !mounted) return;
    _lista.righe.remove(r);
    _dopoModificaRighe();
    invToast(context, 'Articolo ${r.articolo} rimosso');
  }

  Future<void> _svuota() async {
    final s = await invChoice(context, 'Svuota Lista',
        'Vuoi svuotare la Lista e rimuovere tutti gli Articoli?', ['Svuota', 'Chiudi']);
    if (s != 0 || !mounted) return;
    _lista.righe.clear();
    _dopoModificaRighe();
    invToast(context, 'Lista svuotata');
  }

  // ---------------------------------------------------------------------------
  // Info / trasferimenti
  // ---------------------------------------------------------------------------

  Future<void> _tapRiga(RigaPrecarico r) async {
    if (!(_isCpr && r.trasferimenti.isNotEmpty)) {
      await invAlert(context, 'Info ${r.articolo}',
          'Articolo: ${r.articolo} ( ${r.um} )\n\nDescrizione: ${r.descrizione}');
      return;
    }
    String etichetta(Trasferimento t) => t.disponibile != t.disponibileOriginale
        ? '${t.magazzino} (${formatQta(t.disponibile)}/${formatQta(t.disponibileOriginale)})'
        : '${t.magazzino} (${formatQta(t.disponibile)})';
    final disponibili = r.trasferimenti.where((t) => t.disponibile > 0).toList();
    final etichette = disponibili.map(etichetta).toList();
    final s = await invSelect(
        context,
        "Trasferisci ${r.articolo} al ${_lista.magazzino} da:",
        etichette);
    if (s == null || !mounted) return;
    await _trasferisci(r, disponibili[etichette.indexOf(s)]);
  }

  Future<void> _trasferisci(RigaPrecarico r, Trasferimento t) async {
    final predefinita = t.disponibile < r.qta ? t.disponibile : r.qta;
    final q = await invPromptNumber(
      context,
      'Trasferimento ${r.articolo}',
      'Stai per effettuare il seguente Movimento:\n\nArticolo: ${r.articolo}\n'
          'Da: ${t.magazzino} ( max.${formatQta(t.disponibile)} )\nA: ${_lista.magazzino}'
          '\n\nDigita la Q.tà da trasferire:',
      initial: predefinita,
      confirmText: 'Esegui Trasferimento',
    );
    if (q == null || !mounted) return;
    if (q.isNaN) {
      await invAlert(context, 'Errore Quantità', 'La quantità non è stata digitata correttamente');
      return;
    }
    if (q > t.disponibile) {
      await invAlert(context, 'Quantità eccessiva',
          'Impossibile eseguire un Movimento con q.tà superiore a quella Disponibile.');
      return;
    }
    invToast(context, 'Trasferimento in corso..');
    _setBusy(true);
    String risposta;
    try {
      risposta = await _service.trasferisci(
        articolo: r.articolo,
        daMagazzino: t.magazzino,
        aMagazzino: _lista.magazzino,
        qta: q,
        nota: '${_lista.odl}_${_lista.fase}',
        utente: _utente,
        dataOggi: DateFormat('yyyyMMdd').format(DateTime.now()),
      );
    } catch (_) {
      _setBusy(false);
      if (mounted) {
        await invAlert(context, 'Errore nel Trasferimento',
            "Errore di Rete o del Server\n\nImpossibile trasferire l'Articolo ${r.articolo}");
      }
      return;
    }
    _setBusy(false);
    if (!mounted) return;
    if (risposta.startsWith('0043I')) {
      setState(() => t.disponibile -= q);
      await invAlert(context, 'Movimento di ${r.articolo} eseguito', risposta);
    } else {
      await invAlert(context, 'Errore Trasferimento ${r.articolo}', risposta);
    }
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  /// Tabella HTML del PDF (pdfTable di drawListaPrecaricoRighe).
  String _tabellaPdf(ListaPrecarico l) {
    final nota = _isCqc ? 'Arm o Nota' : 'Nota';
    final tbody = StringBuffer();
    for (final r in l.righe) {
      tbody.write('<tr>'
          '<td style="width:18%;text-align:center;">${r.articolo}</td>'
          '<td style="width:8%;text-align:center;">${r.um}</td>'
          '<td style="width:36%;text-align:center;text-transform: capitalize;font-size: 12pt;">${r.descrizione.toLowerCase()}</td>'
          '<td style="width:10%;text-align:center;">${formatQta(r.qta)}</td>'
          '<td style="width:10%;text-align:center;">${formatQta(r.qtaEnx)}</td>'
          '<td style="width:18%;text-align:center;font-size: 12pt;">${r.nota}</td>'
          '</tr>');
    }
    return '<table cellpadding="10px" autosize="1" border="1" width="98%" style="overflow: wrap; font-size: 12pt;">'
        '<thead><tr>'
        '<th style="width:18%;text-align:center;">${l.odl}</th>'
        '<th style="width:8%;text-align:center;"></th>'
        '<th style="width:36%;text-align:center;text-transform: capitalize;">${l.padreDescrizione}</th>'
        '<th style="width:10%;text-align:center;">${l.fase}</th>'
        '<th style="width:10%;text-align:center;"></th>'
        '<th style="width:18%;text-align:center;">${l.padre}</th>'
        '</tr><tr style="background-color:rgba(0,0,0,0.1)">'
        '<th style="width:18%;text-align:center;">Articolo</th>'
        '<th style="width:8%;text-align:center;">UM</th>'
        '<th style="width:36%;text-align:center;">Descrizione</th>'
        '<th style="width:10%;text-align:center;">Q.tà</th>'
        '<th style="width:10%;text-align:center;">$_enx</th>'
        '<th style="width:18%;text-align:center;">$nota</th>'
        '</tr></thead><tbody>$tbody</tbody></table>';
  }

  Future<void> _scaricaPdf(String tabella, String testata) async {
    invToast(context, 'Scaricamento PDF in corso..');
    try {
      final url = await _service.creaPdf(tabella, testata, _utente);
      // Il server risponde 'error_pdf' se la conversione fallisce.
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) throw Exception();
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        await invAlert(context, 'Errore', 'Errore di Rete o del Server: Impossibile scaricare il PDF');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Invio / aggiornamento
  // ---------------------------------------------------------------------------

  Future<void> _invia() async {
    final l = _lista;
    final modifica = l.modificaInCorso;
    final s = await invChoice(
      context,
      modifica ? 'Aggiorna Lista' : 'Lista di Pre-Carico',
      modifica
          ? 'Vuoi Aggiornare la Lista di Pre-Carico ${l.nome}?'
          : 'Vuoi inviare questa Lista di Pre-Carico contenente ${l.righe.length} Articoli?'
              "\n\nVerrà creata anche un'Attività per ACEMA",
      [modifica ? 'Aggiorna' : 'Invia', 'Chiudi'],
    );
    if (s != 0 || !mounted) return;

    _setBusy(true);
    if (modifica) {
      try {
        await _service.modify(l);
        _setBusy(false);
        if (mounted) invToast(context, '${l.nome} Aggiornata');
      } catch (e) {
        _setBusy(false);
        if (mounted) {
          await invAlert(context, 'Errore di Rete',
              "Errore di Rete o del Server durante l'Aggiornamento della Lista di Pre-Carico:\n\n$e");
        }
      }
      return;
    }

    String sequenza;
    try {
      sequenza = await _service.upload(l, _utente);
    } catch (e) {
      _setBusy(false);
      if (mounted) {
        await invAlert(context, 'Errore di Rete',
            "Errore di Rete o del Server durante l'invio della Lista di Pre-Carico:\n\n$e");
      }
      return;
    }

    l.sequenza = sequenza;
    final nomeLista = l.nome;
    final tabella = _tabellaPdf(l);
    var utente = _app.utenteLoggato.nomePortale.toLowerCase();
    if (utente.isEmpty) utente = 'm.demarchi';
    var attivitaCreata = true;
    try {
      await _service.creaAttivitaAcema(
          nomeLista, utente, DateFormat('yyyyMMddHHmmss').format(DateTime.now()));
    } catch (_) {
      attivitaCreata = false;
    }

    // La lista inviata si chiude.
    PrecaricoStore.corrente = ListaPrecarico();
    _setBusy(false);
    if (!mounted) return;
    final pdf = await invChoice(
      context,
      'Lista Pre-Carico inviata',
      'La Lista di Pre-Carico è stata inviata con Successo\n\n'
          '${attivitaCreata ? "É stata creata l'Attività per ACEMA" : "NON è stata creata l'Attività per ACEMA"}'
          '\n\nVuoi scaricare il PDF della Lista appena inviata?',
      ['Scarica PDF', 'Chiudi'],
    );
    if (pdf == 0 && mounted) await _scaricaPdf(tabella, nomeLista);
  }

  // ---------------------------------------------------------------------------
  // Storico
  // ---------------------------------------------------------------------------

  Future<void> _apriStorico() async {
    _setBusy(true);
    List<StoricoPrecarico> storico;
    try {
      storico = await _service.getStorico(_utente);
    } catch (_) {
      _setBusy(false);
      if (mounted) {
        await invAlert(context, 'Errore di Rete o del Server',
            'Non puoi accedere allo Storico delle Liste di Precarico se sei Offline o il Server non risponde. Riprova');
      }
      return;
    }
    _setBusy(false);
    if (!mounted) return;
    if (storico.isEmpty) {
      await invAlert(context, 'Lista Storico Vuota',
          'Lo Storico delle Liste di Precarico inviate è ancora vuoto');
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _StoricoPrecaricoPage(storico: storico, onAzione: _azioneStorico),
    ));
    if (mounted) setState(() {});
  }

  /// Ritorna true se la pagina dello storico va chiusa.
  Future<bool> _azioneStorico(BuildContext ctx, StoricoPrecarico s) async {
    if (s.completato) {
      await _visualizza(ctx, s);
      return false;
    }
    final scelta = await invSelect(ctx, 'La lista ${s.nome} è Aperta. Cosa vuoi fare?',
        ['Visualizza', 'Scarica PDF', 'Modifica', 'Elimina']);
    if (scelta == null || !ctx.mounted) return false;
    switch (scelta) {
      case 'Visualizza':
        await _visualizza(ctx, s);
        return false;
      case 'Scarica PDF':
        final l = ListaPrecarico()
          ..odl = s.odl
          ..fase = s.fase
          ..sequenza = s.sequenza
          ..padre = s.padre
          ..padreDescrizione = s.padreDescrizione;
        l.righe.addAll(s.righe.map(RigaPrecarico.fromStorico));
        await _scaricaPdf(_tabellaPdf(l), s.nome);
        return false;
      case 'Modifica':
        await _caricaPerModifica(s);
        return true;
      default:
        final ok = await invChoice(ctx, 'Elimina Lista',
            'Sei sicuro di voler Eliminare la Lista ${s.nome}?', ['Elimina', 'Chiudi']);
        if (ok != 0 || !ctx.mounted) return false;
        try {
          await _service.elimina(s, _app.utenteLoggato.nomePortale);
          if (ctx.mounted) {
            await invAlert(ctx, 'Lista Eliminata',
                'La Lista ${s.nome} è stata Eliminata con Successo.');
          }
          return true;
        } catch (_) {
          if (ctx.mounted) {
            await invAlert(ctx, 'Errore di Rete o del Server',
                'Errore di Rete o del Server: Impossibile Eliminare la Lista ${s.nome}.');
          }
          return false;
        }
    }
  }

  Future<void> _caricaPerModifica(StoricoPrecarico s) async {
    final l = ListaPrecarico()
      ..magazzino = s.magazzino
      ..odl = s.odl
      ..fase = s.fase
      ..sequenza = s.sequenza
      ..padre = s.padre
      ..padreDescrizione = s.padreDescrizione
      ..modificaInCorso = true;
    l.righe.addAll(s.righe.map(RigaPrecarico.fromStorico));
    PrecaricoStore.corrente = l;
    _setBusy(true);
    for (final r in l.righe) {
      try {
        final a = await _service.getArticolo(r.articolo);
        if (a != null) _impostaTrasferimenti(a, r);
      } catch (_) {}
    }
    _setBusy(false);
    if (mounted) invToast(context, 'Lista Importata');
  }

  Future<String> _nomeUtente(String codice) async {
    if (codice == _utente) return _app.utenteLoggato.nomePortale;
    try {
      _nomiUtenti ??= {
        for (final u in await ChatService(_app.api).getUsersList()) u.codiceUtente: u.nomePortale
      };
    } catch (_) {
      _nomiUtenti = {};
    }
    return _nomiUtenti![codice] ?? codice;
  }

  /// visualizzaStoricoCompletato: riepilogo righe con esito del carico.
  Future<void> _visualizza(BuildContext ctx, StoricoPrecarico s) async {
    final testo = StringBuffer();
    if (s.completato) {
      final ora = s.oraCompletamento.toString().padLeft(6, '0');
      final data = s.dataCompletamento.toString();
      final dataFmt = data.length == 8
          ? '${data.substring(6, 8)}/${data.substring(4, 6)}/${data.substring(0, 4)}'
          : data;
      testo.writeln('Caricato da: ${await _nomeUtente(s.utenteCompletamento)} il $dataFmt '
          'alle ore ${ora.substring(0, 2)}:${ora.substring(2, 4)}');
    } else {
      testo.writeln('Caricato: NO');
    }

    num n(dynamic v) => num.tryParse((v ?? '').toString().replaceAll(',', '.')) ?? 0;
    for (final r in s.righe) {
      final qta = n(r['qta']);
      final caricata = n(r['qta_caricata']);
      final enx = n(r['qta_enx']);
      final enxText = enx != 0 ? ' + ${formatQta(enx)} ${_isCqc ? 'env' : 'enx'}' : '';
      var qtaText = '${formatQta(qta)}$enxText';
      var simbolo = '✔️';
      var azione = (r['azione_riga'] ?? '').toString();
      // Caricato con quantità 0 = riga rimossa.
      if (caricata == 0) azione = 'riga_rimossa';
      switch (azione) {
        case 'riga_aggiunta':
          simbolo = '➕';
        case 'riga_rimossa':
          simbolo = '❌';
        case 'qta_modificata':
          if (qta != caricata || caricata != qta + enx) {
            qtaText = '${formatQta(qta)}$enxText ➔ ${formatQta(caricata)}';
            if (caricata != qta + enx) simbolo = '✏️';
          }
      }
      testo.writeln(s.completato
          ? '\n$simbolo  | $qtaText | ${r['articolo']}'
          : '\n| ${formatQta(qta)}$enxText | ${r['articolo']}');
    }
    if (!ctx.mounted) return;

    if (!s.daRevisionare) {
      await invAlert(ctx, s.nome, testo.toString());
      return;
    }
    final scelta = await invChoice(ctx, s.nome, testo.toString(), ['Chiudi', 'Segna come Revisionato']);
    if (scelta != 1 || !ctx.mounted) return;
    try {
      await _service.segnaRevisionata(s.id);
      s.revisionato = true;
      if (ctx.mounted) invToast(ctx, '${s.nome} Revisionato');
    } catch (_) {
      if (ctx.mounted) invToast(ctx, 'ERRORE: Impossibile Revisionare la Lista ${s.nome}');
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = _lista;
    final vuota = l.righe.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(vuota ? 'PRE-CARICO' : l.odl),
        actions: [
          IconButton(
            tooltip: 'Storico liste',
            icon: const Icon(Icons.history),
            onPressed: _busy ? null : _apriStorico,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!vuota)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFEDEDED),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    [
                      'Mag: ${l.magazzino}',
                      'Fase: ${l.fase}',
                      if (l.padre.isNotEmpty) 'Padre: ${l.padre}',
                      if (l.modificaInCorso) 'Modifica di ${l.nome}',
                    ].join('   ·   '),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(
                child: vuota
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Lista vuota.\nAggiungi un articolo per iniziare una nuova Lista di Pre-Carico.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: l.righe.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _rigaWidget(l.righe[i], i),
                      ),
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator(color: AppColors.spinner)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Svuota lista',
                icon: const Icon(Icons.delete_sweep),
                onPressed: vuota || _busy ? null : _svuota,
              ),
              IconButton(
                tooltip: _isCqc ? 'Scegli dalle giacenze' : 'Scansiona articolo',
                icon: Icon(_isCqc ? Icons.folder_open : Icons.qr_code_scanner),
                onPressed: _busy ? null : (_isCqc ? _aggiungiDaGiacenze : _aggiungiDaScanner),
              ),
              IconButton(
                tooltip: 'Aggiungi articolo',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _busy ? null : _aggiungiDaDialog,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(l.modificaInCorso ? Icons.cloud_upload : Icons.send),
                  label: Text(l.modificaInCorso ? 'Aggiorna' : 'Invia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.casagrandeDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: vuota || _busy ? null : _invia,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rigaWidget(RigaPrecarico r, int i) {
    final qtaModificata = r.qta != r.qtaOriginale;
    return InkWell(
      onTap: () => _tapRiga(r),
      child: Container(
        color: i.isEven ? Colors.white : const Color(0xFFF2F2F2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_isCpr && r.trasferimenti.isNotEmpty ? '↪️ ' : ''}${r.articolo}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(r.descrizione.toLowerCase(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            _cella(
              'Q.tà',
              formatQta(r.qta),
              qtaModificata ? const Color(0xFF8B0000) : Colors.black,
              () => _modificaQta(r),
            ),
            _cella(
              _enx,
              formatQta(r.qtaEnx),
              r.qtaEnx > 0 ? Colors.purple : Colors.black,
              () => _modificaEnx(r),
            ),
            InkWell(
              onTap: () => _modificaNota(r),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(r.nota.isEmpty ? '✏️' : '📃', style: const TextStyle(fontSize: 20)),
              ),
            ),
            IconButton(
              tooltip: 'Rimuovi',
              icon: const Icon(Icons.close, color: Color(0xFFC62828)),
              onPressed: () => _rimuovi(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cella(String etichetta, String valore, Color colore, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Text(etichetta, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            Text(valore, style: TextStyle(fontWeight: FontWeight.bold, color: colore)),
          ],
        ),
      ),
    );
  }
}

/// Storico delle liste inviate (popup "Storico Liste Precarico").
class _StoricoPrecaricoPage extends StatefulWidget {
  const _StoricoPrecaricoPage({required this.storico, required this.onAzione});

  final List<StoricoPrecarico> storico;
  final Future<bool> Function(BuildContext, StoricoPrecarico) onAzione;

  @override
  State<_StoricoPrecaricoPage> createState() => _StoricoPrecaricoPageState();
}

class _StoricoPrecaricoPageState extends State<_StoricoPrecaricoPage> {
  @override
  Widget build(BuildContext context) {
    final oggi = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
    final children = <Widget>[_header('OGGI', const Color(0xFFDFF5D8))];
    var storicoMostrato = false;
    for (final s in widget.storico) {
      String data;
      if (s.dataCreazione == oggi) {
        final o = s.oraCreazione.toString().padLeft(6, '0');
        data = '${o.substring(0, 2)}:${o.substring(2, 4)}';
      } else {
        final d = s.dataCreazione.toString();
        data = d.length == 8 ? '${d.substring(6, 8)}/${d.substring(4, 6)}/${d.substring(0, 4)}' : d;
        if (!storicoMostrato) {
          children.add(_header('STORICO', const Color(0xFFFFF9C4)));
          storicoMostrato = true;
        }
      }
      final colore = s.daRevisionare
          ? const Color(0xFF8B0000)
          : s.completato
              ? const Color(0xFF2E7D32)
              : Colors.black;
      children.add(ListTile(
        title: Text.rich(TextSpan(children: [
          if (s.completato) const TextSpan(text: '✔️  '),
          TextSpan(text: s.nome, style: TextStyle(fontWeight: FontWeight.bold, color: colore)),
          if (s.daRevisionare)
            const TextSpan(
                text: ' ( MOD )',
                style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold)),
        ])),
        trailing: Text(data),
        onTap: () async {
          final chiudi = await widget.onAzione(context, s);
          if (!context.mounted) return;
          if (chiudi) {
            Navigator.of(context).pop();
          } else {
            setState(() {});
          }
        },
      ));
      children.add(const Divider(height: 1));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Storico Liste Precarico')),
      body: ListView(children: children),
    );
  }

  Widget _header(String t, Color c) => Container(
        color: c,
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}
