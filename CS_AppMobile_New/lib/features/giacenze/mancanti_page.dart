import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/sse_client.dart';
import '../../core/storage/last_searched.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/articolo_mancante.dart';
import '../../models/movimento_giacenza.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'inventario_dialogs.dart';
import 'mancanti_service.dart';

enum _Fase { ricerca, sceltaOdl, risultati }

/// Pagina Giacenze → Prel. Mancanti / Prelievi — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/Mancanti e Pagine/Prelievi.
///
/// - Mancanti: magazzino impegno → elenco mancanti (statoPick 'Y').
/// - Prelievi: magazzino → scelta ODL/ODV → elenco righe raggruppate per fase.
///
/// Le righe già inviate (getStoriaMovimento) sono escluse. L'invio è in
/// blocco (WriteMovimentiMultipliAPI + SSE) dopo il controllo che il DB non
/// sia stato aggiornato e che nessun altro abbia inviato nel frattempo.
/// La tab Inviati mostra lo storico con ri-esecuzione / "segna completato".
class MancantiPage extends StatefulWidget {
  const MancantiPage({super.key, this.isPrelievi = false});

  final bool isPrelievi;

  @override
  State<MancantiPage> createState() => _MancantiPageState();
}

class _MancantiPageState extends State<MancantiPage> {
  /// Visualizzazione dei "non critici": condivisa tra Mancanti e Prelievi
  /// (giacenze.viewMancantiNonCritici), non salvata.
  static bool _viewNonCritici = false;

  late final MancantiService _service;
  late final AppState _app;
  late final String _sezione;

  final _magController = TextEditingController();

  _Fase _fase = _Fase.ricerca;
  bool _loading = false;
  bool _sending = false;
  String? _error;
  List<LastSearchedItem> _recenti = [];

  // Prelievi: ODL/ODV del magazzino.
  List<OdlPrelievo> _odlList = [];

  String _magazzino = '';
  String _odlCercato = '';
  DataLogMancanti _dataLog = DataLogMancanti();

  /// listaArticoliMancanti (senza quelli già inviati).
  List<ArticoloMancante> _lista = [];

  /// listaArticoliMancantiFiltrati (dopo blacklist e filtri).
  List<ArticoloMancante> _filtrati = [];

  /// Numero di movimenti già inviati noti (listaMancantiGiaInviati.length).
  int _giaInviati = 0;

  // Filtri (MancanteCorrente.filtro) + blacklist persistente.
  final Set<String> _filtroMag = {};
  final Set<String> _filtroOdl = {};
  Set<String> _blacklist = {};
  String _testo = '';

  // Tab Inviati.
  int _tab = 0;
  bool _loadingInviati = false;
  List<StoricoMancante> _inviati = [];
  bool _inviatiConErrori = false;
  StoricoMancante? _rieseguendo;

  final List<SseClient> _sse = [];
  final List<StreamSubscription<EsitoMovimento>> _subs = [];

  String get _utente => _app.utenteLoggato.codiceUtente;
  String get _societa => _app.utenteLoggato.societaApi;
  String get _blacklistKey => widget.isPrelievi
      ? 'blacklistPrelieviMagazzini'
      : 'blacklistMancantiMagazzini';
  String get _titolo => widget.isPrelievi ? 'Prelievi' : 'Prel. Mancanti';

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _service = MancantiService(_app.api);
    _sezione = widget.isPrelievi ? 'prelievi' : 'mancanti';
    _recenti = LastSearched.get(_sezione);
    final saved = LocalStorage.instance.getJson(_blacklistKey);
    if (saved is List) _blacklist = saved.map((e) => e.toString()).toSet();
  }

  @override
  void dispose() {
    _magController.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    for (final c in _sse) {
      c.close();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Ricerca
  // -------------------------------------------------------------------------

  Future<void> _cerca() async {
    final mag = _magController.text.trim().toUpperCase();
    if (mag.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (widget.isPrelievi) {
      await _cercaOdlPrelievi(mag);
    } else {
      await _caricaMancanti(mag);
    }
  }

  /// Prelievi: elenco ODL/ODV del magazzino (queryGetOdlList).
  Future<void> _cercaOdlPrelievi(String mag) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    List<OdlPrelievo> lista;
    try {
      lista = await _service.getOdlPrelievi(mag);
    } catch (_) {
      lista = [];
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _magazzino = mag;
      _odlList = lista;
    });
    if (lista.isEmpty) {
      // Come l'originale: pagina risultati vuota (gli Inviati restano accessibili).
      _impostaRisultatiVuoti(mag);
    } else {
      setState(() => _fase = _Fase.sceltaOdl);
    }
  }

  void _impostaRisultatiVuoti(String mag) {
    setState(() {
      _magazzino = mag;
      _odlCercato = '';
      _lista = [];
      _filtrati = [];
      _giaInviati = 0;
      _tab = 0;
      _fase = _Fase.risultati;
    });
    _checkInviati();
  }

  /// querySelectMancantiDaMag + incrocio con i movimenti già inviati.
  Future<void> _caricaMancanti(String mag, {String odl = ''}) async {
    final stessoMagazzino = mag == _magazzino;
    setState(() {
      _loading = true;
      _error = null;
    });
    await LastSearched.add(_sezione, mag);
    try {
      final res = await _service.getMancanti(
        magazzinoImpegno: mag,
        codiceOdl: odl,
        statoPickYSelected: !widget.isPrelievi,
      );
      final gia = await _service.getStoriaMovimento(
        utente: '',
        dtrun: res.dataLog.dtrun,
        hrrun: res.dataLog.hrrun,
        magazzinoImpegno: mag,
        sezione: _sezione,
      );
      if (!mounted) return;
      setState(() {
        _magazzino = mag;
        _odlCercato = odl;
        _dataLog = res.dataLog;
        _giaInviati = gia.length;
        _lista = res.lista
            .where((m) => !gia.any(m.corrispondeA))
            .toList();
        // Il filtro dei Mancanti resta se si ricerca lo stesso magazzino.
        if (widget.isPrelievi || !stessoMagazzino) {
          _filtroMag.clear();
          _filtroOdl.clear();
        }
        _applicaFiltri();
        _tab = 0;
        _fase = _Fase.risultati;
        _loading = false;
        _recenti = LastSearched.get(_sezione);
      });
      _checkInviati();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _recenti = LastSearched.get(_sezione);
      });
      await invAlert(context, 'Errore di Rete',
          'Errore di Rete: Impossibile scaricare la Lista');
    }
  }

  Future<void> _ricarica() async {
    if (_magazzino.isEmpty) return;
    await _caricaMancanti(_magazzino, odl: _odlCercato);
  }

  Future<void> _checkInviati() async {
    try {
      final errori = await _service.haInviatiConErrori(
        utente: _utente,
        magazzinoImpegno: _magazzino,
        sezione: _sezione,
      );
      if (mounted) setState(() => _inviatiConErrori = errori);
    } catch (_) {
      if (mounted) setState(() => _inviatiConErrori = false);
    }
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra magazzino');
    if (code == null || !mounted) return;
    _magController.text = code;
    _cerca();
  }

  void _tornaAllaRicerca() {
    setState(() {
      _fase = _Fase.ricerca;
      _recenti = LastSearched.get(_sezione);
    });
  }

  // -------------------------------------------------------------------------
  // Filtri / blacklist (filterArticoliMancanti)
  // -------------------------------------------------------------------------

  void _applicaFiltri() {
    _filtrati = _lista.where((m) {
      if (_blacklist.contains(m.magdispo)) return false;
      if (_filtroMag.isNotEmpty && !_filtroMag.contains(m.magdispo)) return false;
      if (_filtroOdl.isNotEmpty && !_filtroOdl.contains(m.odl)) return false;
      return true;
    }).toList();
    for (final m in _lista) {
      m.selezionato = false;
    }
  }

  List<String> _unici(Iterable<String> v) {
    final out = <String>[];
    for (final s in v) {
      if (!out.contains(s)) out.add(s);
    }
    return out;
  }

  bool get _filtriAttivi =>
      _filtroMag.isNotEmpty || _filtroOdl.isNotEmpty || _blacklist.isNotEmpty;

  Future<void> _apriFiltri() async {
    final magTotali = _unici(_lista.map((m) => m.magdispo));
    final odlTotali = _unici(_lista.map((m) => m.odl));
    final fMag = Set<String>.of(_filtroMag);
    final fOdl = Set<String>.of(_filtroOdl);
    final black = Set<String>.of(_blacklist);

    final applica = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget sezione(String titolo, List<String> valori, Set<String> sel) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                    child: Text(titolo,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (valori.isEmpty)
                    const Text('—', style: TextStyle(color: Colors.black45)),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final v in valori)
                        FilterChip(
                          label: Text(v.isEmpty ? '(vuoto)' : v),
                          selected: sel.contains(v),
                          onSelected: (on) =>
                              setSheet(() => on ? sel.add(v) : sel.remove(v)),
                        ),
                    ],
                  ),
                ],
              );
          return SafeArea(
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.95,
              builder: (_, scroll) => ListView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Filtri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  sezione('Filtra per Mag Disp', magTotali, fMag),
                  sezione('Blacklist magazzini (salvata)', magTotali, black),
                  sezione(widget.isPrelievi ? 'Filtra per ODL / ODV' : 'Filtra per ODL',
                      odlTotali, fOdl),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setSheet(() {
                          fMag.clear();
                          fOdl.clear();
                          black.clear();
                        }),
                        child: const Text('Azzera filtri'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Applica'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (applica != true || !mounted) return;
    setState(() {
      _filtroMag
        ..clear()
        ..addAll(fMag);
      _filtroOdl
        ..clear()
        ..addAll(fOdl);
      _blacklist = black;
      _applicaFiltri();
    });
    await LocalStorage.instance.setJson(_blacklistKey, _blacklist.toList());
  }

  void _toggleNonCritici() {
    setState(() {
      _viewNonCritici = !_viewNonCritici;
      if (!_viewNonCritici) {
        // Le righe nascoste non restano selezionate.
        for (final m in _filtrati.where((m) => m.isNonCritico)) {
          m.selezionato = false;
        }
      }
    });
    invToast(context, _viewNonCritici
        ? 'Visualizzati i Mancanti Non Critici'
        : 'Nascosti i Mancanti Non Critici');
  }

  /// Righe mostrate: filtrate, senza i non critici (se nascosti) e col
  /// filtro testuale.
  List<ArticoloMancante> get _visibili {
    final q = _testo.trim().toLowerCase();
    return _filtrati.where((m) {
      if (m.isNonCritico && !_viewNonCritici) return false;
      if (q.isEmpty) return true;
      return m.articolo.toLowerCase().contains(q) ||
          m.descArticolo.toLowerCase().contains(q) ||
          m.odl.toLowerCase().contains(q) ||
          m.magdispo.toLowerCase().contains(q);
    }).toList();
  }

  List<ArticoloMancante> get _selezionati =>
      _filtrati.where((m) => m.selezionato).toList();

  // -------------------------------------------------------------------------
  // Selezione (regole MGAUT01 / MISP001 / MISP002)
  // -------------------------------------------------------------------------

  void _toggle(ArticoloMancante m) {
    if (!m.selezionabile) {
      invAlert(context, 'Impossibile Selezionare',
          'I Mancanti con magazzino ${m.magdispo} non possono essere Selezionati');
      return;
    }
    setState(() => m.selezionato = !m.selezionato);
  }

  void _toggleTutti() {
    final candidati = _visibili.where((m) => m.selezionabile).toList();
    final tutti = candidati.isNotEmpty && candidati.every((m) => m.selezionato);
    setState(() {
      for (final m in candidati) {
        m.selezionato = !tutti;
      }
    });
  }

  /// Prelievi: tocco sull'intestazione di fase (faseCheck). Seleziona solo
  /// le righe di quella fase; se erano già tutte selezionate, deseleziona.
  void _toggleFase(String fase) {
    bool eleggibile(ArticoloMancante m) =>
        m.fase == fase &&
        m.selezionabile &&
        (!m.isNonCritico || _viewNonCritici);
    final giaTutte = _filtrati.where(eleggibile).every((m) => m.selezionato);
    setState(() {
      for (final m in _filtrati) {
        m.selezionato = false;
      }
      if (!giaTutte) {
        for (final m in _filtrati.where(eleggibile)) {
          m.selezionato = true;
        }
      }
    });
  }

  // -------------------------------------------------------------------------
  // Invio in blocco (queryPreparaMovimentoMancanti)
  // -------------------------------------------------------------------------

  Future<void> _invia() async {
    if (_app.utenteLoggato.accountType == 'Utente Standard') {
      await invAlert(context, 'OPERAZIONE NEGATA',
          "Un Utente 'Standard' può solo visualizzare la Sezione 'Mancanti' ma non può effettuare Operazioni");
      return;
    }
    final sel = _selezionati;
    if (sel.isEmpty) return;

    final parola = widget.isPrelievi
        ? (sel.length > 1 ? 'Prelievi' : 'Prelievo')
        : (sel.length > 1 ? 'Mancanti' : 'Mancante');
    final ok = await invChoice(
      context,
      widget.isPrelievi ? 'Movimento Prelievi' : 'MOVIMENTO MANCANTI',
      'Vuoi Effettuare il Movimento di ${sel.length} $parola ?',
      ['Esegui', 'Chiudi'],
    );
    if (ok != 0 || !mounted) return;

    setState(() => _sending = true);
    try {
      // 1. Il DB dei mancanti non deve essere stato aggiornato nel frattempo.
      DataLogMancanti latest;
      try {
        latest = await _service.getLatestDataLog();
      } catch (_) {
        if (mounted) {
          await invAlert(context, 'Errore',
              "Errore di Rete: Impossibile scaricare l'ultimo Data Log");
        }
        return;
      }
      if (!mounted) return;
      if (!latest.sameAs(_dataLog)) {
        final s = await invChoice(
          context,
          'Attenzione',
          'Impossibile effettuare il Movimento\n\nIl Database è stato Aggiornato '
              'alle ore ${latest.oraFormattata}.\n\nVuoi Eseguire comunque il '
              'Movimento o Aggiornare?',
          ['Aggiorna DB', 'Esegui Comunque'],
        );
        if (s == 0) {
          setState(() => _sending = false);
          await _ricarica();
          return;
        }
        if (s != 1) return;
      }

      // 2. Nessun altro deve aver inviato movimenti per questo magazzino.
      List<Map<String, dynamic>> storia;
      try {
        storia = await _service.getStoriaMovimento(
          utente: '',
          dtrun: _dataLog.dtrun,
          hrrun: _dataLog.hrrun,
          magazzinoImpegno: _magazzino,
          sezione: _sezione,
        );
      } catch (_) {
        if (mounted) {
          await invAlert(context, 'Errore',
              "Errore di Rete: Impossibile fare la scansione degli ultimi movimenti prima dell'invio");
        }
        return;
      }
      if (!mounted) return;
      if (storia.length != _giaInviati) {
        final n = storia.length - _giaInviati;
        final t1 = n > 1 ? 'sono stati eseguiti' : 'è stato eseguito';
        final t2 = n > 1 ? 'nuovi Movimenti' : 'nuovo Movimento';
        final s = await invChoice(
          context,
          'Attenzione',
          'Impossibile effettuare il Movimento: $t1 $n $t2 per questo Magazzino.'
              '\n\nVuoi Eseguire comunque il Movimento o Aggiornare?',
          ['Aggiorna', 'Esegui Comunque'],
        );
        if (s == 0) {
          setState(() => _sending = false);
          await _ricarica();
          return;
        }
        if (s != 1) return;
      }

      // 3. Invio in blocco.
      await _scriviMovimenti(sel);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _scriviMovimenti(List<ArticoloMancante> sel) async {
    final now = DateTime.now();
    final nomeLista = '${_sezione}_${DateFormat('HH_mm_ss').format(now)}';
    final idApi = '${DateFormat('yyyy_MM_dd_HH_mm_ss_SSS').format(now)}_$_utente';
    final movimenti = MancantiService.preparaMovimenti(
      sel,
      idApi: idApi,
      sezione: _sezione,
      utente: _utente,
      societa: _societa,
      dataLog: _dataLog,
    );

    try {
      await _service.writeMovimentiMultipli(
        movimenti,
        idApi: idApi,
        nomeLista: nomeLista,
        utente: _utente,
        sezione: _sezione,
      );
    } catch (_) {
      if (mounted) {
        await invAlert(
            context, 'Errore di Rete', 'Impossibile inviare la Lista $nomeLista');
      }
      return;
    }
    if (!mounted) return;

    // Ciò che è stato inviato sparisce subito dalla lista.
    setState(() {
      _giaInviati += movimenti.length;
      _lista.removeWhere((m) => m.selezionato);
      _filtrati.removeWhere((m) => m.selezionato);
    });
    invToast(context, 'Lista $nomeLista inviata in background!');
    _ascoltaEsito(idApi);
  }

  void _ascoltaEsito(String idApi) {
    final sse = SseClient();
    _sse.add(sse);
    late final StreamSubscription<EsitoMovimento> sub;
    sub = _service.streamEsito(idApi, sse).listen(
      (esito) async {
        if (esito.id != idApi || !esito.completato) return;
        sub.cancel();
        sse.close();
        if (!mounted) return;
        _checkInviati();
        if (_tab == 1) _caricaInviati();
        await invAlert(context, 'Movimenti Completati',
            '${esito.nomeLista}\n\n${esito.response}');
      },
      onError: (_) {},
      cancelOnError: true,
    );
    _subs.add(sub);
  }

  // -------------------------------------------------------------------------
  // Tab Inviati
  // -------------------------------------------------------------------------

  Future<void> _caricaInviati() async {
    setState(() => _loadingInviati = true);
    try {
      final lista = await _service.getInviati(
        utente: _utente,
        magazzinoImpegno: _magazzino,
        sezione: _sezione,
      );
      if (!mounted) return;
      setState(() {
        _inviati = lista;
        _loadingInviati = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInviati = false);
      await invAlert(context, 'Errore',
          "Non puoi accedere all'elenco dei Mancanti Inviati mentre sei Offline. Riprova.");
    }
  }

  void _selezionaTab(int tab) {
    setState(() => _tab = tab);
    if (tab == 1) _caricaInviati();
  }

  Future<void> _azioneStorico(StoricoMancante m) async {
    if (m.statoMov == 0) {
      await invAlert(context, 'Attenzione',
          'Non puoi rieseguire un Movimento mentre è ancora in corso..');
      return;
    }
    if (m.statoMov == 2) {
      await invAlert(context, 'Attenzione',
          'Non puoi rieseguire il Movimento, se è già stato concluso con successo');
      return;
    }
    final s = await invChoice(
      context,
      'Ri-esegui Movimento',
      'Vuoi ri-eseguire questo Movimento, o segnarlo come Completato?',
      ['Ri-Esegui', 'Segna Completato', 'Chiudi'],
    );
    if (!mounted) return;
    if (s == 0) await _riesegui(m);
    if (s == 1) await _segnaCompletato(m);
  }

  Future<void> _riesegui(StoricoMancante m) async {
    setState(() => _rieseguendo = m);
    String? errore;
    try {
      final esito =
          await _service.rieseguiMovimento(m, utente: _utente, societa: _societa);
      if (!esito.isSuccess) errore = esito.response.trim();
    } catch (_) {
      errore = 'error';
      try {
        await _service.updateStatoStoria(
          articolo: m.articolo,
          odl: m.odl,
          fase: m.fase,
          dtrun: m.dtrun,
          hrrun: m.hrrun,
          statoMov: 1,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _rieseguendo = null);
    if (errore == null) {
      await invAlert(context, 'MOVIMENTI COMPLETATI',
          'Tutti e 1 i Movimenti sono stati Eseguiti con SUCCESSO');
    } else {
      await invAlert(context, 'ERRORE MOV ARTICOLO ${m.articolo}',
          'ARTICOLO ${m.articolo}: $errore');
    }
    if (!mounted) return;
    _checkInviati();
    _caricaInviati();
  }

  Future<void> _segnaCompletato(StoricoMancante m) async {
    try {
      await _service.updateStatoStoria(
        articolo: m.articolo,
        odl: m.odl,
        fase: m.fase,
        dtrun: m.dtrun,
        hrrun: m.hrrun,
        statoMov: 2,
      );
      if (!mounted) return;
      setState(() => m.statoMov = 2);
      _checkInviati();
    } catch (_) {
      if (mounted) {
        await invAlert(context, 'Errore',
            'Errore di Rete: Impossibile aggiornare questo Mancante Storico');
      }
    }
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final inRisultati = _fase == _Fase.risultati;
    final sel = inRisultati ? _selezionati.length : 0;

    return PopScope(
      canPop: _fase == _Fase.ricerca,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _tornaAllaRicerca();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_magazzino.isNotEmpty && _fase != _Fase.ricerca
              ? '$_titolo · $_magazzino'
              : _titolo),
          actions: [
            if (inRisultati && _tab == 0) ...[
              IconButton(
                tooltip: _viewNonCritici ? 'Nascondi non critici' : 'Mostra non critici',
                icon: Icon(_viewNonCritici ? Icons.visibility : Icons.visibility_off),
                onPressed: _toggleNonCritici,
              ),
              IconButton(
                tooltip: 'Filtri',
                icon: Icon(Icons.filter_alt,
                    color: _filtriAttivi ? Colors.amberAccent : null),
                onPressed: _apriFiltri,
              ),
            ],
            if (inRisultati)
              IconButton(
                tooltip: 'Aggiorna',
                icon: const Icon(Icons.refresh),
                onPressed: _sending
                    ? null
                    : () => _tab == 1 ? _caricaInviati() : _ricarica(),
              ),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(),
            if (_sending)
              Container(
                color: Colors.black38,
                child: const Center(
                    child: CircularProgressIndicator(color: AppColors.spinner)),
              ),
          ],
        ),
        bottomNavigationBar: (inRisultati && _tab == 0 && sel > 0)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: Text('Invia $sel selezionati'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.casagrandeDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _sending ? null : _invia,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    switch (_fase) {
      case _Fase.ricerca:
        return Column(
          children: [
            _searchBar(),
            Expanded(
              child: _error != null
                  ? _centerMsg(Icons.cloud_off, _error!)
                  : LastSearchedList(
                      items: _recenti,
                      onTap: (codice) {
                        _magController.text = codice;
                        _cerca();
                      },
                      onClear: _recenti.isEmpty
                          ? null
                          : () async {
                              await LastSearched.clear(_sezione);
                              if (!mounted) return;
                              setState(() => _recenti = LastSearched.get(_sezione));
                            },
                    ),
            ),
          ],
        );
      case _Fase.sceltaOdl:
        return _sceltaOdl();
      case _Fase.risultati:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                      value: 0,
                      label: Text(widget.isPrelievi ? 'PRELIEVI' : 'MANCANTI')),
                  ButtonSegment(
                      value: 1,
                      label: Text(_inviatiConErrori ? 'INVIATI ⚠️' : 'INVIATI')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => _selezionaTab(s.first),
              ),
            ),
            Expanded(child: _tab == 0 ? _listaMancanti() : _listaInviati()),
          ],
        );
    }
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _magController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _cerca(),
              decoration: InputDecoration(
                hintText: 'Magazzino impegno',
                prefixIcon: const Icon(Icons.warehouse_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scansiona,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _cerca, child: const Text('Cerca')),
        ],
      ),
    );
  }

  Widget _sceltaOdl() {
    final odv = _odlList.any((o) => o.isOdv);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${odv ? 'ODV' : 'ODL'} ( ${_odlList.length} ) — scegli quello da prelevare',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _odlList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final o = _odlList[i];
              return ListTile(
                title: Text(o.odl,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${o.isOdv ? 'Cliente' : 'Padre'} ${o.padre}\n'
                    '${o.desPadre.toLowerCase()}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _caricaMancanti(_magazzino, odl: o.odl),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _listaMancanti() {
    final visibili = _visibili;
    final candidati = visibili.where((m) => m.selezionabile);
    final tutti = candidati.isNotEmpty && candidati.every((m) => m.selezionato);

    final children = <Widget>[];
    String? faseCorrente;
    for (final m in visibili) {
      if (widget.isPrelievi && m.fase != faseCorrente) {
        faseCorrente = m.fase;
        children.add(_headerFase(m));
      }
      children.add(_tile(m));
      children.add(const Divider(height: 1));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _testo = v),
                  decoration: InputDecoration(
                    hintText: 'Cerca nella lista (${visibili.length})',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              TextButton(
                onPressed: candidati.isEmpty ? null : _toggleTutti,
                child: Text(tutti ? 'Deselez.' : 'Selez. tutti'),
              ),
            ],
          ),
        ),
        Expanded(
          child: visibili.isEmpty
              ? _centerMsg(Icons.inventory_2_outlined,
                  _lista.isEmpty ? 'Nessun articolo da prelevare' : 'Nessun risultato con i filtri attivi')
              : RefreshIndicator(
                  onRefresh: _ricarica,
                  child: ListView(children: children),
                ),
        ),
      ],
    );
  }

  Widget _headerFase(ArticoloMancante m) {
    final odv = m.odl.startsWith('OM') || m.odl.startsWith('OR');
    return Material(
      color: const Color(0xFFDFF5D8),
      child: InkWell(
        onTap: () => _toggleFase(m.fase),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(odv ? m.padre : 'FASE ${m.fase}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(_odlCercato),
              const SizedBox(width: 8),
              const Icon(Icons.done_all, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(ArticoloMancante m) {
    final colore = m.selezionato ? const Color(0xFF8B0000) : Colors.black87;
    final stile = TextStyle(
      color: m.isNonCritico ? const Color(0xFF444444) : colore,
      fontStyle: m.isNonCritico ? FontStyle.italic : FontStyle.normal,
    );
    return InkWell(
      onTap: () => _toggle(m),
      child: Opacity(
        opacity: m.selezionabile ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 86,
                child: Column(
                  children: [
                    Text(m.magdispo, style: stile.copyWith(fontSize: 13)),
                    if (m.vanodispo.isNotEmpty)
                      Text(m.vanodispo, style: stile.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.articolo,
                        style: stile.copyWith(
                            fontWeight:
                                m.isCritico ? FontWeight.bold : FontWeight.w500)),
                    Text('Q.tà: ${formatQta(m.giacdispo)} (${m.umis})',
                        style: stile.copyWith(fontSize: 13)),
                    Text('ODL ${m.odl}  ·  ${m.padre}',
                        style: stile.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                m.selezionato ? Icons.check_box : Icons.check_box_outline_blank,
                color: m.selezionabile ? colore : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaInviati() {
    if (_loadingInviati) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_inviati.isEmpty) {
      return _centerMsg(Icons.history, 'Nessun movimento inviato');
    }
    final children = <Widget>[_headerStorico('OGGI')];
    var storicoMostrato = false;
    for (final m in _inviati) {
      if (!m.isOggi && !storicoMostrato) {
        children.add(_headerStorico('STORICO'));
        storicoMostrato = true;
      }
      children.add(_tileStorico(m));
      children.add(const Divider(height: 1));
    }
    return RefreshIndicator(
      onRefresh: _caricaInviati,
      child: ListView(children: children),
    );
  }

  Widget _headerStorico(String text) => Container(
        width: double.infinity,
        color: const Color(0xFFEDEDED),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _tileStorico(StoricoMancante m) {
    final busy = identical(_rieseguendo, m);
    return ListTile(
      title: Text('${m.articolo}   Q.tà: ${formatQta(m.qta)} (${m.umis})',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
          '${m.vanodispo.isNotEmpty ? '( ${m.vanodispo} ) ' : ''}${m.magdispo} ➔ ${m.magazzinoImpegno}'
          '\nODL ${m.odl}'),
      isThreeLine: true,
      trailing: busy
          ? const SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : InkWell(
              onTap: () => _azioneStorico(m),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(m.iconaStato, style: const TextStyle(fontSize: 18)),
                  Text(m.dataDisplay, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
      onTap: busy ? null : () => _azioneStorico(m),
    );
  }

  Widget _centerMsg(IconData icon, String text) {
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
        ],
      ),
    );
  }
}
