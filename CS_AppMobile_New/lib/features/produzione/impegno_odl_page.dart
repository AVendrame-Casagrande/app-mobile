import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/utente.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../chat/chat_service.dart';
import '../giacenze/inventario_dialogs.dart';
import '../scanner/barcode_scanner_page.dart';
import 'impegno_odl_service.dart';
import 'lista_precarico_page.dart';
import 'lista_precarico_service.dart';

/// Pagina Produzione → Impegno ODL — porting di
/// www/scripts/Produzione-Odl/Pagine/ImpegnoOdl.
///
/// Ricerca ODL / padre / magazzino → (scelta tra più ODL/fasi) → form:
/// operazione ADD / UPD / DEL, articolo, quantità → impegno su Diapason
/// (UpdateSOSACPN.php). Dopo l'impegno: statistiche fase 0027, email al
/// responsabile (fase 0027) e Attività per il magazzino (fasi 0027/0034).
class ImpegnoOdlPage extends StatefulWidget {
  const ImpegnoOdlPage({super.key});

  @override
  State<ImpegnoOdlPage> createState() => _ImpegnoOdlPageState();
}

class _ImpegnoOdlPageState extends State<ImpegnoOdlPage> {
  static const _sezione = 'impegno odl';

  /// Destinatario delle Attività di prelievo create dall'impegno.
  static const _targetAttivita = 'm.vicenzi';

  late final ImpegnoOdlService _service;
  late final AppState _app;
  final _controller = TextEditingController();

  bool _loading = false;
  bool _busy = false;
  bool _cercato = false;
  List<LastSearchedItem> _recenti = [];

  // ImpegnoOdlCorrente
  List<ImpegnoOdl> _lista = [];
  ImpegnoOdl? _impegno;
  String _operazione = 'ADD';
  ArticoloDaImpegnare? _articolo;
  num _qta = 0;
  num _qtaDaLista = 0;
  num _qtaUpdIncrementata = 0;

  List<Utente>? _utenti;

  Utente get _me => _app.utenteLoggato;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _service = ImpegnoOdlService(_app.api);
    _recenti = LastSearched.get(_sezione);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetCorrente() {
    _lista = [];
    _impegno = null;
    _operazione = 'ADD';
    _articolo = null;
    _qta = 0;
    _qtaDaLista = 0;
    _qtaUpdIncrementata = 0;
  }

  // ---------------------------------------------------------------------------
  // Ricerca (querySelectImpegnoOdl)
  // ---------------------------------------------------------------------------

  Future<void> _cerca(String codice, {String fase = '', bool salva = true}) async {
    codice = codice.trim().toUpperCase();
    if (codice.isEmpty) return;
    FocusScope.of(context).unfocus();
    _controller.text = codice;
    if (salva) await LastSearched.add(_sezione, codice);
    setState(() {
      _loading = true;
      _cercato = true;
      _resetCorrente();
      _recenti = LastSearched.get(_sezione);
    });
    try {
      final lista = await _service.selectImpegni(codice, fase, _me.codiceUtente);
      if (lista.length == 1) {
        lista.first.listaArticoli = await _service.getArticoli(lista.first);
      }
      if (!mounted) return;
      setState(() {
        _lista = lista;
        _impegno = lista.length == 1 ? lista.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resetCorrente();
        _loading = false;
      });
    }
  }

  /// resetForm(true): ricarica l'ODL/fase corrente.
  Future<void> _ricarica() async {
    final i = _impegno;
    if (i == null) return;
    await _cerca(i.odl, fase: i.fase, salva: false);
  }

  Future<List<Utente>> _getUtenti() async {
    _utenti ??= await ChatService(_app.api).getUsersList();
    return _utenti!;
  }

  // ---------------------------------------------------------------------------
  // Articolo
  // ---------------------------------------------------------------------------

  Future<void> _promptArticolo() async {
    if (_operazione != 'ADD') return;
    final cambia = _articolo != null;
    final r = await invPrompt(
      context,
      '${cambia ? 'Cambia' : 'Inserisci'} Articolo',
      "Digita L' Articolo che vuoi inserire:",
      ['Reimposta', 'Chiudi', cambia ? 'Cambia' : 'Inserisci'],
      initial: _articolo?.codice ?? '',
      uppercase: true,
    );
    if (r == null || !mounted) return;
    if (r.button == 0) {
      setState(() {
        _articolo = null;
        _qta = 0;
      });
    }
    if (r.button == 2) await _inserisciArticolo(r.text.trim().toUpperCase());
  }

  Future<void> _scansionaArticolo() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra articolo');
    if (code == null || !mounted) return;
    await _inserisciArticolo(code.trim().toUpperCase());
  }

  /// Gli articoli di tipo N (kanban) non si impegnano in fase 0027.
  Future<void> _inserisciArticolo(String codice) async {
    if (codice.isEmpty) return;
    String tipo;
    try {
      tipo = await _service.getTipoArticolo(codice);
    } catch (_) {
      if (mounted) {
        await invAlert(context, 'Errore',
            "Errore di Rete o del Server: Impossibile ottenere il tipo dell'articolo");
      }
      return;
    }
    if (!mounted) return;
    if (_lista.isNotEmpty && _lista.first.fase == '0027' && tipo == 'N') {
      await invAlert(context, 'Avviso',
          "L'inserimento di un articolo tipo N nelle fasi 27 è disabilitato");
      return;
    }
    await _caricaArticolo(codice);
  }

  /// getArticoloFromDB: verifica l'articolo e lo imposta nel form.
  Future<void> _caricaArticolo(String codice) async {
    final i = _impegno!;
    setState(() {
      _qta = 0;
      _busy = true;
    });
    ArticoloDaImpegnare? a;
    try {
      a = await _service.getArticolo(codice);
    } catch (_) {
      a = null;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    Future<void> errore(String titolo, String testo) async {
      setState(() => _articolo = null);
      await invAlert(context, titolo, testo);
    }

    if (a == null) {
      await errore('Articolo Non trovato', "L'articolo con codice $codice non esiste. Riprova");
      return;
    }
    final presenti = _operazione == 'ADD'
        ? i.listaArticoli.where((x) => x.codice == codice).toList()
        : <ArticoloImpegno>[];
    if (presenti.isNotEmpty) {
      if (i.isFase006) {
        final fasi = presenti.map((x) => '${x.fase} ( ${formatQta(x.qta)} )').join('\n');
        await errore('Articolo Presente',
            "L'articolo $codice è già presente in queste fasi:\n$fasi");
      } else {
        await errore('Articolo Duplicato', "L'articolo $codice è già presente in questo ODL");
      }
      return;
    }
    setState(() => _articolo = a);
  }

  /// Articoli selezionabili per UPD / DEL (ordinati per codice).
  List<ArticoloImpegno> get _articoliUpdDel {
    final i = _impegno!;
    final l = List<ArticoloImpegno>.of(i.listaArticoli)
      ..sort((a, b) => a.codice.toUpperCase().compareTo(b.codice.toUpperCase()));
    if (_operazione == 'UPD' && i.isFase006) {
      // In fase 006x l'elenco contiene tutte le fasi: per l'UPD solo le 006x.
      return l.where((a) => a.fase.startsWith('006')).toList();
    }
    return l;
  }

  Future<void> _selezionaArticoloUpdDel() async {
    final i = _impegno!;
    final articoli = _articoliUpdDel;
    final etichette = [
      for (final a in articoli)
        i.isFase006 && _operazione == 'DEL' ? '[ ${a.fase} ] ${a.codice}' : a.codice
    ];
    final s = await invSelect(context, 'Seleziona l\'Articolo', etichette);
    if (s == null || !mounted) return;
    await _caricaArticolo(articoli[etichette.indexOf(s)].codice);
  }

  // ---------------------------------------------------------------------------
  // Quantità
  // ---------------------------------------------------------------------------

  Future<void> _promptQta() async {
    final i = _impegno!;
    final a = _articolo!;
    var msg = 'Digita la quantità da ${_operazione == 'UPD' ? 'modificare' : 'inserire'} '
        'per questo Articolo';
    if (i.isFase006) {
      msg += '\n\nLa q.tà verrà trasformata in Negativa nella Fase ${i.fase}';
    }
    if (!['PZ', 'NR', 'PC'].contains(a.unitaMisura)) {
      msg += '\n\nUsa il . per i decimali (Es: 12.15)';
    }

    final cambia = _qta != 0;
    num predefinita = cambia ? (i.isFase006 ? -_qta : _qta) : 1;
    for (final x in i.listaArticoli) {
      if (x.codice == a.codice && x.fase == i.fase) {
        predefinita = x.qta;
        _qtaDaLista = x.qta;
        msg += '\n\nQ.tà corrente: ${formatQta(x.qta)}';
      }
    }

    final r = await invPrompt(
      context,
      '${cambia ? 'Cambia' : 'Inserisci'} Quantità Articolo',
      msg,
      ['Reimposta', 'Chiudi', cambia ? 'Cambia' : 'Inserisci'],
      initial: formatQta(predefinita),
      numeric: true,
    );
    if (r == null || !mounted) return;
    if (r.button == 0) {
      setState(() => _qta = 0);
      return;
    }
    if (r.button != 2) return;
    final q = double.tryParse(r.text.trim().replaceAll(',', '.'));
    if (q == null) {
      await invAlert(context, 'Errore', 'Quantità non digitata correttamente');
      return;
    }
    await _verificaGiacenza(q);
  }

  /// checkGiacenzaArticolo: in fase 0027/0034 l'impegno deve essere coperto
  /// dalla disponibilità su MGAUT00, MGAUT10 o MISK.
  Future<void> _verificaGiacenza(num qta) async {
    final i = _impegno!;
    if (_operazione == 'UPD') {
      _qtaUpdIncrementata = qta - _qtaDaLista;
      if (_qtaUpdIncrementata <= 0) {
        setState(() => _qta = qta);
        return;
      }
    }
    if (!i.isFase0027o0034) {
      setState(() => _qta = i.isFase006 ? -qta : qta);
      return;
    }
    setState(() => _busy = true);
    bool ok;
    try {
      ok = await _service.giacenzaDisponibile(
          _articolo!.codice, _operazione == 'UPD' ? _qtaUpdIncrementata : qta);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      await invAlert(context, 'Errore di Rete', 'Impossibile contattare il Server');
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      setState(() => _qta = qta);
    } else {
      await invAlert(context, 'Giacenza non disponibile',
          "L' Articolo ${_articolo!.codice} non ha abbastanza giacenza su MGAUT00, "
          "MGAUT10 o MISK\n\nImpegnare in un'altra fase");
    }
  }

  bool get _puoInviare =>
      _articolo != null && (_operazione == 'DEL' || _qta != 0);

  // ---------------------------------------------------------------------------
  // Invio
  // ---------------------------------------------------------------------------

  Future<void> _invia() async {
    final i = _impegno!;

    // Magazzino di destinazione: dal server, altrimenti digitato.
    if (!i.magazzinoValido) {
      setState(() => _busy = true);
      try {
        final mag = await _service.returnMagazzino(i.odl, i.fase);
        if (mag.isNotEmpty) i.magazzinoDestinazione = mag;
      } catch (_) {
        if (mounted) {
          setState(() => _busy = false);
          await invAlert(context, 'Errore', 'Errore: Magazzino di Destinazione non trovato');
        }
        return;
      }
      if (!mounted) return;
      setState(() => _busy = false);
    }
    if (!i.magazzinoValido) {
      final r = await invPrompt(
        context,
        'Magazzino di Destinazione',
        'ATTENZIONE!\n\nNon è stato trovato il Magazzino di Destinazione.\n\n'
            'Per procedere: Digita manualmente il Magazzino di Destinazione:',
        ['Conferma', 'Annulla'],
        uppercase: true,
      );
      if (r == null || r.button != 0 || !mounted) return;
      final mag = r.text.toUpperCase().trim();
      bool esiste;
      try {
        esiste = await _service.checkMagazzinoExists(mag);
      } catch (_) {
        if (mounted) {
          await invAlert(context, 'Errore di Connessione',
              'Errore di Rete: impossibile verificare se il Magazzino $mag esiste');
        }
        return;
      }
      if (!mounted) return;
      if (!esiste) {
        await invAlert(context, 'Magazzino Inesistente', 'Errore: il Magazzino $mag non esiste');
        return;
      }
      setState(() => i.magazzinoDestinazione = mag);
      invToast(context, '$mag impostato');
    }

    await _avviaImpegno();
  }

  Future<void> _avviaImpegno() async {
    final i = _impegno!;
    final articolo = _articolo!.codice;
    final qta = _qta;
    var fase = i.fase;

    // DEL in fase 006x: l'articolo può essere in più fasi.
    if (_operazione == 'DEL' && i.isFase006) {
      final fasi = i.listaArticoli.where((a) => a.codice == articolo).toList();
      if (fasi.isNotEmpty) fase = fasi.last.fase;
      if (fasi.length > 1) {
        final elenco = fasi.map((f) => '${f.fase} ( ${formatQta(f.qta)} )').join('\n');
        final r = await invPrompt(
          context,
          'Fase da eliminare',
          "Attenzione: l'Articolo $articolo è presente in multiple Fasi:\n$elenco\n\n"
              'Digita la Fase dalla quale vuoi eliminarlo:',
          ['Conferma', 'Annulla'],
        );
        if (r == null || r.button != 0 || !mounted) return;
        fase = r.text.trim();
        if (!fasi.any((f) => f.fase == fase)) {
          await invAlert(context, 'Errore Digitazione Fase',
              'La Fase che hai digitato ( $fase ) non esiste. Riprova.');
          return;
        }
      }
    }

    final azione = switch (_operazione) {
      'DEL' => "Vuoi Eliminare l' Articolo $articolo da questi dati?",
      'UPD' => "Vuoi Aggiornare l' Articolo $articolo con la nuova quantità: ${formatQta(qta)}?",
      _ => "Vuoi Aggiungere l' Articolo $articolo con quantità ${formatQta(qta)} a questi dati?",
    };
    final ok = await invChoice(
      context,
      'Riepilogo',
      'ODL: ${i.odl}\nFase: $fase\nMagazzino: ${i.magazzinoDestinazione}\n\n$azione',
      ['Esegui', 'Chiudi'],
    );
    if (ok != 0 || !mounted) return;

    // Parametri Diapason: "P <ADD|REP|DEL> odl articolo fase [qta]".
    final funzione = _operazione == 'UPD' ? 'REP' : _operazione;
    final parametri = _operazione == 'DEL'
        ? 'P $funzione ${i.odl} $articolo $fase'
        : 'P $funzione ${i.odl} $articolo $fase ${formatQta(qta)}';

    setState(() => _busy = true);
    String risposta;
    try {
      risposta = await _service.updateSOSACPN(parametri);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await invAlert(context, 'Impegno Fallito', 'Errore di Rete: $e');
      return;
    }
    if (!mounted) return;
    if (risposta != '0000 OPERAZIONE ESEGUITA') {
      setState(() => _busy = false);
      await invAlert(context, 'Impegno Fallito', risposta);
      return;
    }

    await _dopoImpegno(fase);
  }

  /// Statistiche (fase 0027) → email (fase 0027) → Attività (0027/0034).
  Future<void> _dopoImpegno(String fase) async {
    final i = _impegno!;
    final a = _articolo!;

    if (_operazione != 'UPD' && i.fase == '0027') {
      // Come l'originale ritenta finché riesce (qui al massimo 30 volte).
      for (var t = 0; t < 30; t++) {
        try {
          await _service.aggiornaStatistica0027(
            elimina: _operazione == 'DEL',
            articolo: a.codice,
            odl: i.odl,
            padre: i.padre,
            fase: fase,
            magazzino: i.magazzinoDestinazione,
            responsabile: i.responsabile,
            qta: _qta,
          );
          break;
        } on ApiException catch (e) {
          // 4xx (es. azione assente sul server o parametri rifiutati): ritentare non serve.
          final s = e.statusCode ?? 0;
          if (s >= 400 && s < 500) break;
          await Future.delayed(const Duration(seconds: 1));
        } catch (_) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    var esito = 'Operazione Eseguita con successo';
    esito += await _inviaEmail() ? ' ( E-Mail inviata' : ' ( E-Mail non inviata';
    if (!mounted) return;

    if (!i.isFase0027o0034) {
      setState(() => _busy = false);
      await invAlert(context, 'Operazione Completata', '$esito )');
      await _ricarica();
      return;
    }
    await _gestisciAttivita(esito);
  }

  Future<bool> _inviaEmail() async {
    final i = _impegno!;
    if (i.fase != '0027') return false;
    String? target;
    if (i.responsabile == _me.codiceUtente) {
      // Il responsabile sono io: niente email a me, solo ai CC.
      target = '';
    } else {
      try {
        final u = (await _getUtenti()).where(
            (u) => u.codiceUtente == i.responsabile && u.emailUtente.isNotEmpty);
        if (u.isNotEmpty) target = u.first.emailUtente;
      } catch (_) {}
    }
    if (target == null) return false;

    final funzione = switch (_operazione) {
      'UPD' => 'Aggiornato',
      'DEL' => 'Rimosso',
      _ => 'Aggiunto',
    };
    final qtaText = _operazione == 'DEL' ? '' : 'con q.ta <b>${formatQta(_qta)}</b>';
    final a = _articolo!;
    try {
      await _service.sendEmail(
        emailTarget: target,
        titolo: 'Articolo $funzione | ODL: ${i.odl} - Fase: ${i.fase}',
        messaggio: "$funzione l'Articolo <b>${a.codice}</b> $qtaText ( ODL: ${i.odl} - "
            'Fase: ${i.fase} ) da parte di ${_me.nomeUtente}.'
            '<br><br>Desc Articolo: ${a.descrizione}<br>Padre: ${i.padre}'
            '<br>Desc Padre: ${i.descPadre}',
        nomeUtente: _me.nomeUtente,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// creaAttivita: ADD crea l'Attività di prelievo; UPD/DEL modificano
  /// quella esistente (o, per un aumento di quantità, ne creano una nuova).
  Future<void> _gestisciAttivita(String esito) async {
    final i = _impegno!;
    final a = _articolo!;

    String testoAvviso(num qta) => 'F.${i.fase} || Art: ${a.codice} | Odl: ${i.odl} | '
        'A: ${i.magazzinoDestinazione} | Q.ta: ${formatQta(qta)}';

    if (_operazione == 'ADD') {
      await _creaAttivita(testoAvviso(_qta), esito);
      return;
    }

    final qtaAvviso = _operazione == 'UPD' ? _qtaUpdIncrementata : _qta;
    final avviso = testoAvviso(qtaAvviso);

    Future<void> fine(String titolo, String testo) async {
      if (!mounted) return;
      setState(() => _busy = false);
      await invAlert(context, titolo, testo);
      await _ricarica();
    }

    ChiaviAttivita? chiavi;
    Map<String, dynamic>? attivita;
    try {
      chiavi = await _service.getChiaviAttivita(
        articolo: a.codice,
        odl: i.odl,
        fase: i.fase,
        magazzino: i.magazzinoDestinazione,
        qta: _qta,
        operazione: _operazione,
      );
      if (chiavi != null) attivita = await _service.selectSingoloAvviso(chiavi);
    } catch (_) {
      await fine('Operazione Eseguita',
          "L'impegno è stato aggiornato ma non è stato possibile aggiornare l'Attività");
      return;
    }

    final nonAttiva = attivita == null ||
        (attivita['attivo'] ?? '').toString() != '1' ||
        (attivita['completato'] ?? '').toString() == '1';
    if (chiavi == null || nonAttiva) {
      if (_operazione == 'UPD' && _qtaUpdIncrementata > 0) {
        // Aumento di quantità senza Attività aperta: nuova Attività per la differenza.
        await _creaAttivita(avviso, esito);
      } else {
        await fine('Operazione Eseguita',
            "L'impegno è stato Aggiornato.\n\nNon è stata trovata nessuna Attività associata ad esso");
      }
      return;
    }

    // Modifica dell'Attività esistente (DEL: "Attività cancellata").
    final nuovoTesto = _operazione == 'DEL' ? 'Attività cancellata' : avviso;
    final dest = (attivita['dest'] ?? '').toString();
    try {
      await _service.modificaAvviso(
        timest: chiavi.timest,
        utente: (attivita['utente'] ?? '').toString().toLowerCase(),
        avviso: nuovoTesto,
        dest: dest,
        urgente: (attivita['urgente'] ?? '0').toString(),
        scadenza: (attivita['scadenza'] ?? '').toString(),
      );
    } catch (_) {
      await fine('Operazione Completata', '$esito | Attività NON modificata )');
      return;
    }

    if (dest != _me.codiceUtente && dest.toLowerCase() != 'acema') {
      final data = _formattaTimest(chiavi.timest);
      final prima = (attivita['avviso'] ?? '').toString();
      try {
        await ChatService(_app.api).sendMessaggioAutomatico(
          testo: 'Ho modificato una tua Attività assegnata in data $data. '
              'Attività modificata in:\n\n$nuovoTesto\n\nPrima era: $prima',
          sender: _me.codiceUtente,
          receiver: dest,
          tipoMessaggio: 'avviso_modificato',
        );
      } catch (_) {}
    }
    await fine('Operazione Completata', '$esito | Attività modificata )');
  }

  /// ajaxInviaAvviso(fromFase0027): crea l'Attività per il magazzino, la
  /// collega all'impegno e avvisa il destinatario in chat.
  Future<void> _creaAttivita(String avviso, String esito) async {
    final i = _impegno!;
    var dest = '';
    try {
      final u = (await _getUtenti())
          .where((u) => u.nomePortale.toLowerCase() == _targetAttivita);
      if (u.isNotEmpty) dest = u.first.codiceUtente;
    } catch (_) {}
    if (!mounted) return;
    if (dest.isEmpty) {
      setState(() => _busy = false);
      await invAlert(context, 'Errore', 'Non esiste nessun Destinatario associato a questo nome');
      return;
    }

    final now = DateTime.now();
    final timest = DateFormat('yyyyMMddHHmmss').format(now);
    final owner = _me.nomePortale.toLowerCase();
    try {
      await _service.uploadAvviso(timest: timest, utente: owner, avviso: avviso, dest: dest);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      await invAlert(context, 'Operazione Completata', '$esito | Attività NON creata )');
      await _ricarica();
      return;
    }

    bool tracciata;
    try {
      tracciata = await _service.writeAttivitaSezione(
        timest: timest,
        utente: owner,
        articolo: _articolo!.codice,
        odl: i.odl,
        fase: i.fase,
        qta: _qta,
        magazzino: i.magazzinoDestinazione,
      );
    } catch (_) {
      tracciata = false;
    }

    try {
      await ChatService(_app.api).sendMessaggioAutomatico(
        testo: 'Ho creato per te una nuova Attività:\n\n$avviso.\n\n'
            'In Data: ${DateFormat('dd/MM/yy HH:mm').format(now)}\nScadenza: ',
        sender: _me.codiceUtente,
        receiver: dest,
        tipoMessaggio: 'avviso_creato',
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() => _busy = false);
    await invAlert(
      context,
      'Operazione Completata',
      tracciata
          ? '$esito | Attività creata )'
          : '$esito | Attività creata ma NON tracciata )',
    );
    await _ricarica();
  }

  static String _formattaTimest(String t) {
    try {
      return DateFormat('dd/MM/yy HH:mm').format(DateFormat('yyyyMMddHHmmss').parse(t));
    } catch (_) {
      return t;
    }
  }

  /// Fasi 006x: importa gli articoli dell'impegno in una nuova Lista di
  /// Pre-Carico (quantità rese positive) e la apre.
  Future<void> _apriPrecarico() async {
    final i = _impegno!;
    final l = ListaPrecarico()
      ..odl = i.odl
      ..fase = i.fase
      ..padre = i.padre
      ..padreDescrizione = i.descPadre
      ..magazzino = i.magazzinoDestinazione;

    if (l.magazzino == 'Nessuno') {
      final predefinito = _me.codiceUtente == 'CPR010' ? 'MGPUL01' : 'MG00020';
      final r = await invPrompt(
        context,
        'Magazzino di Riferimento',
        'ATTENZIONE\n\nManca il Magazzino di Riferimento per questa Lista\n\n'
            'Digita manualmente il Magazzino di Riferimento:',
        ['OK', 'Annulla'],
        initial: predefinito,
        uppercase: true,
      );
      if (!mounted) return;
      l.magazzino = r != null && r.button == 0 && r.text.trim().isNotEmpty
          ? r.text.trim().toUpperCase()
          : predefinito;
    }

    for (final a in i.listaArticoli) {
      l.righe.add(RigaPrecarico(
          articolo: a.codice, descrizione: a.descrizione, um: a.um, qta: a.qta * -1));
    }
    PrecaricoStore.corrente = l;
    invToast(context, 'Lista Importata');
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ListaPrecaricoPage()));
  }

  void _infoArticoli() {
    final i = _impegno!;
    final elenco = i.listaArticoli
        .map((a) => '${a.codice} ( ${formatQta(a.qta)} )')
        .join('\n');
    invAlert(context, 'Lista Articoli di ${i.odl}',
        'Questo ODL in fase ${i.fase} contiene questi Articoli:\n\n$elenco');
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impegno ODL')),
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(),
              Expanded(child: _body()),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator(color: AppColors.spinner)),
            ),
        ],
      ),
      bottomNavigationBar: _impegno == null ? null : _bottomBar(),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _cerca(v),
              decoration: InputDecoration(
                hintText: 'ODL / Padre / Magazzino',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra ODL');
                    if (code != null && mounted) _cerca(code);
                  },
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () => _cerca(_controller.text), child: const Text('Cerca')),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (!_cercato) {
      return LastSearchedList(
        items: _recenti,
        onTap: (c) => _cerca(c),
        onClear: _recenti.isEmpty
            ? null
            : () async {
                await LastSearched.clear(_sezione);
                if (!mounted) return;
                setState(() => _recenti = LastSearched.get(_sezione));
              },
      );
    }
    if (_lista.isEmpty) {
      return const Center(
        child: Text('Nessun risultato o nessuna Fase 0027', textAlign: TextAlign.center),
      );
    }
    if (_impegno == null) return _sceltaOdl();
    return _form();
  }

  Widget _sceltaOdl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('ODL ( ${_lista.length} )',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _lista.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, k) {
              final o = _lista[k];
              return ListTile(
                title: Text(o.odl, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Padre ${o.padre}'),
                trailing: Text('Fase ${o.fase}'),
                onTap: () => _cerca(o.odl, fase: o.fase),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _riga(String etichetta, Widget valore, {VoidCallback? onTap, Widget? azione}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(etichetta, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: valore),
            if (azione != null) azione,
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final i = _impegno!;
    const verde = Color(0xFF2E7D32);
    const rosso = Color(0xFF8B0000);
    final a = _articolo;
    final mostraQta = a != null && (_operazione == 'ADD' || _operazione == 'UPD');

    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Padre: ${i.padre}    Mag: ${i.magazzinoDestinazione}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Desc: ${i.descPadre.toLowerCase()}'),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _riga('ODL', Text(i.odl, style: const TextStyle(color: verde))),
              const Divider(height: 1),
              _riga('Fase', Text(i.fase, style: const TextStyle(color: verde))),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 110,
                        child: Text('Operazione', style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ADD', label: Text('ADD')),
                          ButtonSegment(value: 'UPD', label: Text('UPD')),
                          ButtonSegment(value: 'DEL', label: Text('DEL')),
                        ],
                        selected: {_operazione},
                        onSelectionChanged: (s) => setState(() {
                          _operazione = s.first;
                          _articolo = null; // come l'originale: si riparte dall'articolo
                          _qta = 0;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _riga(
                'Articolo',
                Text(a?.codice ?? 'Richiesto',
                    style: TextStyle(color: a == null ? rosso : verde, fontWeight: FontWeight.bold)),
                onTap: _operazione == 'ADD' ? _promptArticolo : _selezionaArticoloUpdDel,
                azione: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_operazione == 'ADD')
                      IconButton(
                        tooltip: 'Scansiona articolo',
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _scansionaArticolo,
                      ),
                    Icon(a == null ? Icons.add_circle_outline : Icons.check_circle,
                        color: a == null ? rosso : verde),
                  ],
                ),
              ),
              if (a != null) ...[
                const Divider(height: 1),
                _riga('Desc', Text(a.descrizione.toLowerCase())),
              ],
              if (mostraQta) ...[
                const Divider(height: 1),
                _riga(
                  'Quantità (${a.unitaMisura})',
                  Text(_qta == 0 ? 'Richiesto' : formatQta(_qta),
                      style: TextStyle(
                          color: _qta == 0 ? rosso : verde, fontWeight: FontWeight.bold)),
                  onTap: _promptQta,
                  azione: Icon(_qta == 0 ? Icons.add_circle_outline : Icons.check_circle,
                      color: _qta == 0 ? rosso : verde),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Articoli dell\'ODL',
              icon: const Icon(Icons.list_alt),
              onPressed: _infoArticoli,
            ),
            if (_impegno!.isFase006)
              IconButton(
                tooltip: 'Apri come Lista di Pre-Carico',
                icon: const Icon(Icons.playlist_add_check),
                onPressed: _busy ? null : _apriPrecarico,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Invia impegno'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.casagrandeDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _puoInviare && !_busy ? _invia : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
