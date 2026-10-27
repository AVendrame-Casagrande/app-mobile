import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart' show ApiException;
import '../../core/theme/app_theme.dart';
import '../../models/automha_ordine.dart';
import '../../models/avviso.dart';
import '../../models/movimento_giacenza.dart';
import '../../models/riga_lista_aut.dart';
import '../../state/app_state.dart';
import '../avvisi/avvisi_service.dart';
import '../chat/chat_service.dart';
import 'inventario_dialogs.dart';
import 'mgaut_aggiunta.dart';
import 'movimento_service.dart';
import 'mgaut_service.dart';

// Indici delle tab, nell'ordine dell'originale: AUT00, AUT10, 27/34, 02/03, AUT01.
const _tabAut00 = 0;
const _tabAut10 = 1;
const _tab0027 = 2;
const _tabAut02 = 3;
const _tabAut01 = 4;

/// Pagina Giacenze → Liste AUT — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/Mgaut.
///
/// - AUT00 / AUT10: liste di prelievo compilate sul dispositivo (Manuale, ODL,
///   ODV, ODV immediato da pre bolla) e inviate con WriteListaMagazzinoAutomatico.
/// - 27/34: liste di prelievo ricavate dalle Attività di fase 0027/0034.
/// - 02/03: consultazione MGAUT02.
/// - AUT01: trasferimenti da MGAUT01 (invio WriteMovimentiMultipliAPI + SSE).
class MgautPage extends StatefulWidget {
  const MgautPage({super.key});

  @override
  State<MgautPage> createState() => _MgautPageState();
}

class _MgautPageState extends State<MgautPage> with SingleTickerProviderStateMixin {
  /// Filtro magazzino impegno della 27/34 (filterMagazzino0027Page).
  static String _filtro0027 = 'TUTTI';

  late final MgautService _service;
  late final MovimentoService _movService;
  late final AppState _app;
  late final TabController _tabs;
  int _tabPrecedente = 0;
  bool _accesso0027 = false;

  bool _loading01 = false;
  bool _loading02 = false;
  bool _loading0027 = false;
  bool _busy = false;
  String? _error01;
  String? _error02;

  List<AutomhaOrdine> _mgis001 = [];
  List<AutomhaOrdine> _mgaut02 = [];
  List<RigaPrelievo0027> _lista0027 = [];
  bool _caricato0027 = false;

  StreamSubscription<EsitoMovimento>? _esitoSub;

  String get _utente => _app.utenteLoggato.codiceUtente;
  String get _nomePortale => _app.utenteLoggato.nomePortale;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _service = MgautService(_app.api);
    _movService = MovimentoService(_app.api);
    _accesso0027 = _utente == 'CMA006';

    // setMgautPageMagazzinoCorrente(): CMA006 e CTM* partono da AUT01.
    final iniziale =
        _utente == 'CMA006' || _utente.startsWith('CTM') ? _tabAut01 : _tabAut00;
    _tabs = TabController(length: 5, vsync: this, initialIndex: iniziale);
    _tabPrecedente = iniziale;
    _tabs.addListener(_onTab);

    _caricaMgis001();
    _caricaMgaut02();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _esitoSub?.cancel();
    _movService.closeStream();
    super.dispose();
  }

  Future<void> _onTab() async {
    if (_tabs.indexIsChanging) return;
    final idx = _tabs.index;
    if (idx == _tab0027 && !_accesso0027) {
      final s = await invChoice(
        context,
        'Accesso Liste di Prelievo F.0027',
        'Solamente il CMA006 può accedere a questa Sezione. Vuoi accedere lo stesso?',
        ['Accedi', 'Chiudi'],
      );
      if (!mounted) return;
      if (s != 0) {
        _tabs.animateTo(_tabPrecedente);
        return;
      }
      _accesso0027 = true;
    }
    if (idx == _tab0027 && !_caricato0027) _carica0027();
    setState(() => _tabPrecedente = idx);
  }

  // ===========================================================================
  // AUT01 / MGAUT02 (server)
  // ===========================================================================

  Future<void> _caricaMgis001() async {
    setState(() {
      _loading01 = true;
      _error01 = null;
    });
    try {
      final lista = await _service.getMgis001();
      if (!mounted) return;
      setState(() {
        _mgis001 = lista;
        _loading01 = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error01 = 'Errore di Rete o del Server';
        _loading01 = false;
      });
    }
  }

  Future<void> _caricaMgaut02() async {
    setState(() {
      _loading02 = true;
      _error02 = null;
    });
    try {
      final lista = await _service.getMgaut02();
      if (!mounted) return;
      setState(() {
        _mgaut02 = lista;
        _loading02 = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error02 = 'Errore di Rete o del Server';
        _loading02 = false;
      });
    }
  }

  /// Raggruppa una lista per nomeLista mantenendo l'ordine.
  Map<String, List<AutomhaOrdine>> _raggruppa(List<AutomhaOrdine> lista) {
    final map = <String, List<AutomhaOrdine>>{};
    for (final r in lista) {
      map.putIfAbsent(r.nomeLista, () => []).add(r);
    }
    return map;
  }

  List<AutomhaOrdine> get _selezionati01 =>
      _mgis001.where((r) => r.selezionato).toList();

  Future<void> _inviaAut01() async {
    final sel = _selezionati01;
    if (sel.isEmpty) return;

    final conferma = await invChoice(context, 'Invia liste AUT01',
        'Inviare ${sel.length} righe selezionate al magazzino automatico?',
        ['Invia', 'Annulla']);
    if (conferma != 0 || !mounted) return;

    final now = DateTime.now();
    final idApi = '${DateFormat('yyyy_MM_dd_HH_mm_ss_SSS').format(now)}_$_utente';
    final nomeLista = 'mgaut01_${DateFormat('HH_mm_ss').format(now)}';
    final movimenti = sel
        .map((r) => MgautService.movimentoDaRiga(r, idApi: idApi, utente: _utente))
        .toList();

    setState(() => _busy = true);
    try {
      _esitoSub?.cancel();
      _esitoSub = _movService.streamEsito(idApi).listen((esito) {
        if (esito.id != idApi) return;
        if (esito.completato) {
          _esitoSub?.cancel();
          _movService.closeStream();
          if (!mounted) return;
          setState(() => _busy = false);
          invAlert(context, 'Invio completato',
              esito.response.isEmpty ? 'Liste inviate.' : esito.response);
          _caricaMgis001();
        }
      }, onError: (_) {});

      await _movService.writeMovimentiMultipli(
        movimenti,
        idApi: idApi,
        nomeLista: nomeLista,
        utente: _utente,
        sezione: 'mgaut01',
      );

      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _busy) {
          _esitoSub?.cancel();
          _movService.closeStream();
          setState(() => _busy = false);
          invAlert(context, 'Invio inviato',
              'Liste inviate. Conferma non ricevuta in tempo: aggiorna la lista.');
          _caricaMgis001();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      invAlert(context, 'Errore', 'Invio non riuscito: errore di rete.');
    }
  }

  Future<void> _eliminaLista(AutomhaOrdine r) async {
    final conferma = await invChoice(
        context, 'Elimina lista', 'Eliminare la lista ${r.nomeLista}?', ['Elimina', 'Annulla']);
    if (conferma != 0 || !mounted) return;
    setState(() => _busy = true);
    try {
      final ok = await _service.deleteLista(r);
      if (!mounted) return;
      setState(() => _busy = false);
      if (ok) {
        _caricaMgis001();
      } else {
        invAlert(context, 'Errore', 'Lista non eliminata.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      invAlert(context, 'Errore', "Errore di rete durante l'eliminazione.");
    }
  }

  // ===========================================================================
  // AUT00 / AUT10 (liste locali)
  // ===========================================================================

  String _magazzinoTab(int tab) => tab == _tabAut10 ? 'MGAUT10' : 'MGAUT00';

  Future<void> _aggiungi(String magazzino) async {
    final cambiate = await MgautAggiunta(
      context: context,
      service: _service,
      magazzinoOrigine: magazzino,
      nomePortale: _nomePortale,
    ).avvia();
    if (cambiate && mounted) setState(() {});
  }

  Future<void> _svuota(String magazzino) async {
    final s = await invChoice(
      context,
      'Svuota Lista $magazzino',
      'Vuoi svuotare tutta la Lista $magazzino e rimuovere tutti gli Articoli?',
      ['Svuota', 'Chiudi'],
    );
    if (s != 0 || !mounted) return;
    setState(() => MgautStore.lista(magazzino).clear());
    invToast(context, 'Lista $magazzino svuotata');
  }

  Future<void> _rimuovi(String magazzino, RigaListaAut r) async {
    final s = await invChoice(
      context,
      'Rimuovi Articolo',
      "Vuoi rimuovere l'Articolo ${r.articolo} dalla Lista $magazzino?",
      ['Rimuovi', 'Chiudi'],
    );
    if (s != 0 || !mounted) return;
    setState(() => MgautStore.lista(magazzino).remove(r));
    invToast(context, 'Articolo ${r.articolo} rimosso');
  }

  String _infoTipo(RigaListaAut r) {
    switch (r.tipoprel) {
      case 'MAN':
        return 'Tipo lista: Manuale';
      case 'ODL':
        return 'ODL: ${r.rifprel}\nPadre: ${r.artpadre} ( ${r.descartpadre.toLowerCase()} )'
            '\n\nFase: ${r.fase} ( ${r.descfase.toLowerCase()} )';
      case 'ODV':
        return 'ODV: ${r.rifprel}\nPOS: ${r.pos}\n\nCliente: ${r.cliente} ( ${r.nomecliente.toLowerCase()} )';
    }
    return '';
  }

  Future<void> _infoRiga(String magazzino, RigaListaAut r) async {
    final msg = 'Articolo:  ${r.articolo} ( ${r.descarticolo.toLowerCase()} )\n\n${_infoTipo(r)}';
    if (r.tipoprel == 'ODV' && magazzino == 'MGAUT10') {
      final s = await invChoice(
          context, 'Info ${r.articolo}', msg, ['Sposta su MGAUT00', 'Chiudi']);
      if (s == 0 && mounted) await _spostaSuMgaut00(r);
      return;
    }
    await invAlert(context, 'Info ${r.articolo}', msg);
  }

  /// Sposta una riga ODV da MGAUT10 a MGAUT00 se c'è giacenza.
  Future<void> _spostaSuMgaut00(RigaListaAut r) async {
    ArticoloAut? a;
    try {
      a = await _service.getArticolo(r.articolo);
    } catch (_) {
      a = null;
    }
    if (!mounted) return;
    if (a == null) {
      await invAlert(context, 'Articolo Non trovato',
          "L'articolo con codice ${r.articolo} non esiste. Riprova");
      return;
    }
    if (a.giacenteSu('MGAUT00') < r.qta) {
      await invAlert(context, 'Errore Giacenza MGAUT00',
          "L'articolo ${r.articolo} non ha abbastanza Giacenza per essere spostato nella Lista MGAUT00");
      return;
    }
    final l00 = MgautStore.mgaut00;
    if (l00.isNotEmpty) {
      String? errore;
      if (l00.first.tipoprel != r.tipoprel) {
        errore = 'La Lista MGAUT00 contiene delle Righe per un prelievo diverso da quello ODV';
      } else if (l00.first.magto != r.magto) {
        errore = 'La Lista MGAUT00 contiene delle Righe con Magazzino di Destinazione '
            'diverso da quello di questa Riga';
      } else if (l00.first.rifprel != r.rifprel) {
        errore = 'La Lista MGAUT00 contiene delle Righe che fanno riferimento ad un ODV '
            'diverso da quello di questa Riga';
      }
      if (errore != null) {
        await invAlert(context, 'Impossibile Aggiungere', errore);
        return;
      }
    }
    setState(() {
      MgautStore.mgaut10.remove(r);
      l00.insert(0, r.copyWith(magfrom: 'MGAUT00'));
    });
    invToast(context, 'Articolo ${r.articolo} spostato su MGAUT00');
  }

  Future<void> _inviaListaLocale(String magazzino) async {
    final lista = MgautStore.lista(magazzino);
    if (lista.isEmpty) return;
    final p = lista.first;
    final testo = 'Vuoi inviare la Lista di Prelievo $magazzino contenente '
        '${lista.length} Articoli?\n\nMag. Dest: ${p.magto}'
        '${p.vanoto.isNotEmpty ? '\nVano Dest: ${p.vanoto}' : ''}\n'
        '${_infoTipo(p).replaceAll('\n\n', '\n')}\n\n'
        'Puoi aggiungere una Nota ( Opzionale ) per questa Lista, che verrà '
        'applicata a tutti i suoi Movimenti ( max. 19 caratteri )';
    final r = await invPrompt(context, 'Invia Lista $magazzino', testo, ['Invia', 'Chiudi']);
    if (r == null || r.button != 0 || !mounted) return;

    setState(() => _busy = true);
    String esito;
    try {
      esito = await _service.writeListaMagazzinoAutomatico(
        utente: _utente,
        magazzinoOrigine: p.magfrom,
        magazzinoDestinazione: p.magto,
        odl: p.rifprel,
        fase: p.subrifprel,
        tipoInterfaccia: 'PREL${p.tipoprel}',
        righe: lista.map((x) => x.toJson()).toList(),
        nota: _nota(r.text),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await invAlert(context, 'Errore di Rete',
          "Errore Durante l'invio della Lista di Prelievo:\n\n$e");
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (esito.startsWith('200')) {
      final n = lista.length;
      setState(lista.clear);
      await invAlert(context, '200', 'La Lista contenente $n Righe è stata inviata con Successo!');
    } else {
      await invAlert(
          context, 'Errore', "Errore Durante l'invio della Lista di Prelievo:\n\n$esito");
    }
  }

  /// Nota: max 19 caratteri, a capo sostituiti da spazi.
  static String _nota(String s) {
    final t = s.length > 19 ? s.substring(0, 19) : s;
    return t.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  }

  // ===========================================================================
  // 27/34 (dalle Attività)
  // ===========================================================================

  Future<void> _carica0027() async {
    setState(() {
      _loading0027 = true;
      _caricato0027 = true;
    });
    try {
      final avvisi = await AvvisiService(_app.api).getAllAvvisi(_nomePortale);
      final righe = <RigaPrelievo0027>[];
      for (final a in avvisi) {
        if (!AvvisoPrelievo.isPrelievo(a.avviso)) continue;
        final p = AvvisoPrelievo.parse(a.avviso);
        righe.add(RigaPrelievo0027(
          odl: p.odl,
          magazzinoimpegno: p.magDest,
          articolo: p.articolo,
          fase: p.fase,
          qta: num.tryParse(p.qta.replaceAll(',', '.')) ?? 0,
          dataCreazioneAttivita: a.timestInteger,
        ));
      }
      await Future.wait(righe.map(_completaRiga0027));
      if (!mounted) return;
      setState(() {
        _lista0027 = righe.where((r) => r.articoloDaVisualizzare).toList();
        _loading0027 = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading0027 = false);
      await invAlert(context, 'Errore di Rete',
          'Errore di Rete o del Server durante il caricamento delle Liste dalle Attività');
    }
  }

  /// Completa i dati mancanti della riga (updateRigaPrelievo24_34).
  Future<void> _completaRiga0027(RigaPrelievo0027 r) async {
    final a = await _service.getArticolo(r.articolo);
    if (a != null) {
      r.umis = a.unitaMisura;
      r.descarticolo = a.descrizione;
      final rep = a.magazzini[r.magazzinoimpegno];
      r.giacenteReparto = rep?.giacente;
      r.impegnatoReparto = rep?.impegnato;
      // Priorità a MGAUT00, poi MGAUT10; altrimenti MISK (non automatica).
      if (a.giacenteSu('MGAUT00') >= r.qta && a.magazzini.containsKey('MGAUT00')) {
        r.magdispo = 'MGAUT00';
      } else if (a.giacenteSu('MGAUT10') >= r.qta && a.magazzini.containsKey('MGAUT10')) {
        r.magdispo = 'MGAUT10';
      }
    }
    r.articoloDaVisualizzare =
        await _service.daVisualizzare0027(r.articolo, r.odl, r.dataCreazioneAttivita);
  }

  List<RigaPrelievo0027> get _visibili0027 => _filtro0027 == 'TUTTI'
      ? _lista0027
      : _lista0027.where((r) => r.magazzinoimpegno.contains(_filtro0027)).toList();

  Future<void> _filtra0027() async {
    final mags = <String>{for (final r in _lista0027) r.magazzinoimpegno}.toList()..sort();
    final s = await invSelect(context, 'Filtra per Magazzino di Impegno', ['TUTTI', ...mags]);
    if (s == null || !mounted) return;
    setState(() => _filtro0027 = s);
  }

  void _toggleGruppo0027(RigaPrelievo0027 r) {
    if (r.isMisk) {
      invAlert(
        context,
        'Lista NON Automatica',
        'Impossibile creare una Lista di Prelievo: questo Impegno ha come Magazzino '
            'di Origine il MISK.\n\nAvvisare un Magazziniere che effettui il Movimento.'
            "\n\nPer Eliminare questa Lista: Elimina l'Attività associata nella sezione [Attività]",
      );
      return;
    }
    final eraSelezionato = r.selezionato;
    setState(() {
      for (final x in _lista0027) {
        x.selezionato = false;
      }
      if (!eraSelezionato) {
        for (final x in _lista0027) {
          if (x.odl == r.odl &&
              x.fase == r.fase &&
              x.magdispo == r.magdispo &&
              x.magazzinoimpegno == r.magazzinoimpegno) {
            x.selezionato = true;
          }
        }
      }
    });
  }

  void _info0027(RigaPrelievo0027 r) {
    invAlert(
      context,
      'Info ${r.articolo}',
      'Articolo: ${r.articolo} ( ${r.descarticolo.toLowerCase()} )\n\n'
          'Q.tà F.${r.fase}: ${formatQta(r.qta)}\n\n'
          'Giacente in Reparto: ${r.giacenteReparto ?? '-'}\n'
          'Impegnato in Reparto: ${r.impegnatoReparto ?? '-'}',
    );
  }

  Future<void> _invia0027() async {
    final sel = _lista0027.where((r) => r.selezionato).toList();
    if (sel.isEmpty) return;
    final p = sel.last;
    final articoli = sel.map((r) => '${r.articolo} ➔ ${formatQta(r.qta)}').join('\n');
    final r = await invPrompt(
      context,
      'Lista di Prelievo Fase 27/34',
      'Vuoi inviare la Lista di Prelievo ( da ${p.magdispo} a ${p.magazzinoimpegno} '
          'con ODL ${p.odl} e Fase ${p.fase} ) dei seguenti Articoli?\n\n$articoli\n\n'
          'Puoi aggiungere una Nota ( Opzionale ) per questa Lista, che verrà '
          'applicata a tutti i suoi Movimenti ( max. 19 caratteri )',
      ['Invia', 'Chiudi'],
    );
    if (r == null || r.button != 0 || !mounted) return;

    setState(() => _busy = true);
    String esito;
    try {
      esito = await _service.writeListaMagazzinoAutomatico(
        utente: _utente,
        magazzinoOrigine: p.magdispo ?? '',
        magazzinoDestinazione: p.magazzinoimpegno,
        odl: p.odl,
        fase: p.fase,
        tipoInterfaccia: 'PRELODL',
        righe: sel.map((x) => x.toJson()).toList(),
        nota: _nota(r.text),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await invAlert(context, 'Errore di Rete',
          "Errore Durante l'invio della Lista di Prelievo 0027/34:\n\n$e");
      _carica0027();
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (esito.startsWith('200')) {
      await invAlert(
          context, '200', 'La Lista contenente ${sel.length} Righe è stata inviata con Successo!');
      _completaAttivita0027(sel);
    } else {
      await invAlert(context, 'Errore',
          "Errore durante l'invio della Lista di Prelievo 0027/34:\n\n$esito");
    }
    if (mounted) _carica0027();
  }

  /// Porting di completaAttivita0027(): per ogni riga inviata, avvia lo script
  /// che completerà l'Attività corrispondente e avvisa il suo creatore in chat.
  Future<void> _completaAttivita0027(List<RigaPrelievo0027> inviate) async {
    final api = _app.api;
    final me = _app.utenteLoggato;
    List<Avviso> avvisi;
    Map<String, String> codici = {};
    try {
      final avvisiService = AvvisiService(api);
      avvisi = avvisiService.filtraValidiOggi(await avvisiService.getAllAvvisi(me.nomePortale));
    } catch (_) {
      return;
    }
    try {
      final utenti = await ChatService(api).getUsersList();
      codici = {for (final u in utenti) u.nomePortale.toLowerCase(): u.codiceUtente};
    } catch (_) {}

    String codiceDi(String nomePortale) {
      var c = nomePortale == me.nomePortale.toLowerCase()
          ? me.codiceUtente
          : (codici[nomePortale] ?? '');
      if (c == 'CAP') c = 'CAP001';
      if (c == 'CMA') c = 'CMA001';
      return c;
    }

    for (final riga in inviate) {
      for (final a in avvisi) {
        final p = AvvisoPrelievo.parse(a.avviso);
        if (p.articolo != riga.articolo ||
            p.odl != riga.odl ||
            p.magDest != riga.magazzinoimpegno) {
          continue;
        }
        final destinatario = codiceDi(a.utente);
        final testo = 'Ho completato la Attività che mi era stata assegnata da te il '
            '${a.timest}.\n\nAttività:\n\n${a.avviso}';
        _avviaScriptCompletamento(p, a, destinatario, testo);
      }
    }
  }

  Future<void> _avviaScriptCompletamento(
      AvvisoPrelievo p, Avviso a, String destinatario, String testo,
      [int tentativo = 0]) async {
    try {
      final id = await _service.startScriptCompletaAvviso(
        articolo: p.articolo,
        odl: p.odl,
        timestAvviso: a.timestInteger,
        utenteCompletante: _utente,
        utenteAvviso: a.utente.toLowerCase(),
        utenteAvvisoDiapason: destinatario,
        destAvviso: a.dest,
        chatText: testo,
      );
      // "in_attesa": l'articolo non è ancora su MGAUT01, l'API completerà
      // l'Attività (e manderà il messaggio chat) in background.
      if (int.tryParse(id) == null) return;
      try {
        await _service.setEmailChatReminder(id,
            messaggio: testo, sender: _utente, receiver: destinatario);
      } catch (_) {}
    } catch (e) {
      // HTTP 400 = parametri mancanti (es. codice Diapason del creatore vuoto):
      // ritentare non serve.
      if (e is ApiException && e.statusCode == 400) return;
      // Come l'originale: si ritenta ogni 5 secondi (qui al massimo 12 volte).
      if (tentativo >= 12) return;
      await Future.delayed(const Duration(seconds: 5));
      await _avviaScriptCompletamento(p, a, destinatario, testo, tentativo + 1);
    }
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste AUT'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: 'AUT00 (${MgautStore.mgaut00.length})'),
            Tab(text: 'AUT10 (${MgautStore.mgaut10.length})'),
            Tab(text: _loading0027 ? '27/34 ⏳' : '27/34'),
            const Tab(text: '02/03'),
            const Tab(text: 'AUT01'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna',
            onPressed: () {
              switch (_tabs.index) {
                case _tab0027:
                  _carica0027();
                case _tabAut02:
                  _caricaMgaut02();
                case _tabAut01:
                  _caricaMgis001();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabs,
            children: [
              _tabListaLocale('MGAUT00'),
              _tabListaLocale('MGAUT10'),
              _tabLista0027(),
              _tabMgaut02(),
              _tabMgis001(),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.spinner),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget? _bottomBar() {
    final tab = _tabs.index;
    Widget bar(List<Widget> children) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: children),
          ),
        );
    final stile = ElevatedButton.styleFrom(
      backgroundColor: AppColors.casagrandeDark,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

    if (tab == _tabAut00 || tab == _tabAut10) {
      final mag = _magazzinoTab(tab);
      final vuota = MgautStore.lista(mag).isEmpty;
      return bar([
        IconButton(
          tooltip: 'Svuota lista',
          icon: const Icon(Icons.delete_sweep),
          onPressed: vuota || _busy ? null : () => _svuota(mag),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Invia'),
            style: stile,
            onPressed: vuota || _busy ? null : () => _inviaListaLocale(mag),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi'),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _busy ? null : () => _aggiungi(mag),
          ),
        ),
      ]);
    }
    if (tab == _tab0027) {
      final sel = _lista0027.where((r) => r.selezionato).length;
      return bar([
        IconButton(
          tooltip: 'Filtra per magazzino',
          icon: Icon(Icons.filter_alt,
              color: _filtro0027 != 'TUTTI' ? Colors.amber.shade800 : null),
          onPressed: _lista0027.isEmpty ? null : _filtra0027,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: Text(sel > 0 ? 'Invia ($sel)' : 'Invia'),
            style: stile,
            onPressed: sel == 0 || _busy ? null : _invia0027,
          ),
        ),
      ]);
    }
    if (tab == _tabAut01 && _selezionati01.isNotEmpty) {
      return bar([
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: Text('Invia AUT01 (${_selezionati01.length})'),
            style: stile,
            onPressed: _inviaAut01,
          ),
        ),
      ]);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  Widget _tabListaLocale(String magazzino) {
    final lista = MgautStore.lista(magazzino);
    if (lista.isEmpty) {
      return _centerMsg(Icons.playlist_add,
          'Lista $magazzino vuota.\nUsa "Aggiungi" per creare un prelievo.');
    }
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = lista[i];
        final descr = r.descarticolo.toLowerCase();
        final dest = <String>[
          if (r.rifprel.isNotEmpty) r.rifprel,
          r.magto,
          if (r.rifprel.isNotEmpty && r.subrifprel.isNotEmpty) 'Fase ${r.subrifprel}',
          if (r.rifprel.isNotEmpty && r.subrifprel.isEmpty && r.cliente.isNotEmpty)
            r.cliente,
          if (r.vanoRequired) 'Vano ${r.vanoto}',
        ];
        return ListTile(
          onTap: () => _infoRiga(magazzino, r),
          title: Text(r.articolo, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              '${descr.length > 35 ? descr.substring(0, 35) : descr}\n${dest.join(' · ')}'),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${formatQta(r.qta)} ${r.umis}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                tooltip: 'Rimuovi',
                icon: const Icon(Icons.close, color: Color(0xFFC62828)),
                onPressed: () => _rimuovi(magazzino, r),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  Widget _tabLista0027() {
    if (_loading0027) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spinner));
    }
    final lista = _visibili0027;
    if (lista.isEmpty) return _centerMsg(Icons.inbox, 'Non ci sono Liste');

    final children = <Widget>[];
    String? odl, magOri, magDest;
    var primo = true;
    for (final r in lista) {
      if (primo || r.odl != odl || r.magdispo != magOri || r.magazzinoimpegno != magDest) {
        primo = false;
        odl = r.odl;
        magOri = r.magdispo;
        magDest = r.magazzinoimpegno;
        children.add(Material(
          color: r.isMisk ? const Color(0xFFFFE0B2) : const Color(0xFFDFF5D8),
          child: ListTile(
            dense: true,
            onTap: () => _toggleGruppo0027(r),
            title: Text('${r.odl} | ${r.magdispo ?? 'MISK'} ➔ ${r.magazzinoimpegno}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: r.selezionato ? const Text('🎯') : null,
          ),
        ));
      }
      final descr = r.descarticolo.toLowerCase();
      children.add(Opacity(
        opacity: r.isMisk ? 0.5 : 1,
        child: Container(
          color: r.impegnoCoperto ? const Color(0xFFFFF9C4) : null,
          child: ListTile(
            dense: true,
            onTap: () => _info0027(r),
            title: Text(r.articolo),
            subtitle: Text(descr.length > 30 ? descr.substring(0, 30) : descr),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${formatQta(r.qta)} ${r.umis}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SizedBox(width: 20, child: Text(r.selezionato ? '✔️' : '')),
              ],
            ),
          ),
        ),
      ));
      children.add(const Divider(height: 1));
    }
    return RefreshIndicator(onRefresh: _carica0027, child: ListView(children: children));
  }

  // ---------------------------------------------------------------------------
  Widget _tabMgis001() {
    if (_loading01) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_error01 != null) {
      return _centerMsg(Icons.cloud_off, _error01!, retry: _caricaMgis001);
    }
    if (_mgis001.isEmpty) {
      return _centerMsg(Icons.inbox, 'Nessuna lista di trasferimento');
    }
    final gruppi = _raggruppa(_mgis001);
    return ListView(
      children: [
        for (final entry in gruppi.entries) _gruppoMgis(entry.key, entry.value),
      ],
    );
  }

  Widget _gruppoMgis(String nomeLista, List<AutomhaOrdine> righe) {
    final tuttiSel = righe.every((r) => r.selezionato);
    final primo = righe.first;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            child: ListTile(
              dense: true,
              leading: Checkbox(
                value: tuttiSel,
                onChanged: (v) => setState(() {
                  for (final r in righe) {
                    r.selezionato = v ?? false;
                  }
                }),
              ),
              title: Text(nomeLista, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${primo.magfrom} → ${primo.destinazione}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                tooltip: 'Elimina lista',
                onPressed: () => _eliminaLista(primo),
              ),
            ),
          ),
          ...righe.map((r) => ListTile(
                dense: true,
                title: Text(r.articolo),
                subtitle:
                    r.descArticolo.isEmpty ? null : Text(r.descArticolo.toLowerCase()),
                trailing: Text('${formatQta(r.qta)} ${r.umis}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Widget _tabMgaut02() {
    if (_loading02) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_error02 != null) {
      return _centerMsg(Icons.cloud_off, _error02!, retry: _caricaMgaut02);
    }
    if (_mgaut02.isEmpty) {
      return _centerMsg(Icons.inbox, 'Nessuna lista MGAUT02');
    }
    final gruppi = _raggruppa(_mgaut02);
    return ListView(
      children: [
        for (final entry in gruppi.entries)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                Container(
                  color: entry.value.first.inviatoOk
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      entry.value.first.inviatoOk
                          ? Icons.check_circle
                          : Icons.hourglass_bottom,
                      color: entry.value.first.inviatoOk
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFEF6C00),
                    ),
                    title: Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${entry.value.first.magfrom} → ${entry.value.first.destinazione}'),
                  ),
                ),
                ...entry.value.map((r) => ListTile(
                      dense: true,
                      title: Text(r.articolo),
                      subtitle: r.descArticolo.isEmpty
                          ? null
                          : Text(r.descArticolo.toLowerCase()),
                      trailing: Text('${formatQta(r.qta)} ${r.umis}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _centerMsg(IconData icon, String text, {VoidCallback? retry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.black38),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(text, textAlign: TextAlign.center),
          ),
          if (retry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: retry, child: const Text('Riprova')),
          ],
        ],
      ),
    );
  }
}
