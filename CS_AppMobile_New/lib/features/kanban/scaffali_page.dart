import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/kanban_articolo.dart';
import '../../models/scaffale_kanban.dart';
import '../../state/app_state.dart';
import '../giacenze/inventario_dialogs.dart';
import '../scanner/barcode_scanner_page.dart';
import 'scaffali_service.dart';

/// Pagina Kanban → Scaffali (fase 1, read-only) — porting di
/// www/scripts/Kanban (browser elenco scaffali).
/// Elenca gli scaffali con filtro per magazzino e ricerca testuale;
/// al tap mostra le celle dello scaffale.
class ScaffaliPage extends StatefulWidget {
  const ScaffaliPage({super.key});

  @override
  State<ScaffaliPage> createState() => _ScaffaliPageState();
}

class _ScaffaliPageState extends State<ScaffaliPage> {
  late final ScaffaliService _service;

  final _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<ScaffaleKanban> _tutti = [];
  List<String> _magazzini = [];
  String? _magazzinoFiltro; // null = tutti
  String _ricerca = '';

  @override
  void initState() {
    super.initState();
    _service = ScaffaliService(context.read<AppState>().api);
    _carica();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carica() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await _service.getAllScaffali();
      if (!mounted) return;
      setState(() {
        _tutti = lista;
        _magazzini = _service.magazziniDistinti(lista);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore di Rete o del Server';
        _loading = false;
      });
    }
  }

  List<ScaffaleKanban> get _filtrati {
    final q = _ricerca.trim().toLowerCase();
    return _tutti.where((s) {
      if (_magazzinoFiltro != null && s.magazzino != _magazzinoFiltro) {
        return false;
      }
      if (q.isEmpty) return true;
      return s.codice.toLowerCase().contains(q) ||
          s.descrizione.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra scaffale');
    if (code == null || !mounted) return;
    _searchController.text = code;
    setState(() => _ricerca = code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scaffali Kanban')),
      body: Column(
        children: [
          _filtri(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filtri() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _ricerca = v),
            decoration: InputDecoration(
              hintText: 'Codice o descrizione scaffale',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_ricerca.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _ricerca = '');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Scansiona',
                    onPressed: _scansiona,
                  ),
                ],
              ),
            ),
          ),
          if (_magazzini.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warehouse_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _magazzinoFiltro,
                    hint: const Text('Tutti i magazzini'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tutti i magazzini'),
                      ),
                      ..._magazzini.map(
                        (m) => DropdownMenuItem<String?>(
                          value: m,
                          child: Text(m),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _magazzinoFiltro = v),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_error != null) {
      return _centerMessage(Icons.cloud_off, _error!, retry: _carica);
    }
    final lista = _filtrati;
    if (lista.isEmpty) {
      return _centerMessage(Icons.shelves, 'Nessuno scaffale trovato');
    }
    return RefreshIndicator(
      onRefresh: _carica,
      child: ListView.separated(
        itemCount: lista.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final s = lista[i];
          return ListTile(
            leading: const Icon(Icons.shelves),
            title: Text(s.codice,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text([
              if (s.descrizione.isNotEmpty) s.descrizione,
              if (s.magazzino.isNotEmpty) 'Mag: ${s.magazzino}',
            ].join('   ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _apriScaffale(s),
          );
        },
      ),
    );
  }

  void _apriScaffale(ScaffaleKanban s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScaffaleDettaglioPage(service: _service, scaffale: s),
      ),
    );
  }

  Widget _centerMessage(IconData icon, String text, {VoidCallback? retry}) {
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

/// Dettaglio scaffale: elenco articoli presenti.
class _ScaffaleDettaglioPage extends StatefulWidget {
  const _ScaffaleDettaglioPage({required this.service, required this.scaffale});

  final ScaffaliService service;
  final ScaffaleKanban scaffale;

  @override
  State<_ScaffaleDettaglioPage> createState() => _ScaffaleDettaglioPageState();
}

class _ScaffaleDettaglioPageState extends State<_ScaffaleDettaglioPage> {
  bool _loading = false;
  String? _error;
  List<ArticoloScaffale> _articoli = [];

  /// Codice dell'articolo con un'operazione in corso (mostra ⏳ al posto della X).
  String? _articoloInCorso;

  /// Operazione di aggiunta in corso (disabilita il '+').
  bool _aggiuntaInCorso = false;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  // ---------------------------------------------------------------------------
  // Permessi: come in Cordova solo Utente Magazzino, Utente Avanzato o
  // l'utente CPR013 (unica eccezione) possono aggiungere/eliminare articoli.
  // ---------------------------------------------------------------------------
  bool get _puoModificare {
    final u = context.read<AppState>().utenteLoggato;
    return u.accountType == 'Utente Magazzino' ||
        u.accountType == 'Utente Avanzato' ||
        u.codiceUtente == 'CPR013';
  }

  String get _codiceUtente =>
      context.read<AppState>().utenteLoggato.codiceUtente;

  // ---------------------------------------------------------------------------
  // Tap su una riga: elenco degli scaffali che contengono l'articolo
  // (addElencoScaffaliToArticolo).
  // ---------------------------------------------------------------------------
  Future<void> _mostraScaffaliArticolo(ArticoloScaffale a) async {
    if (_articoloInCorso != null) return;
    setState(() => _articoloInCorso = a.codice);
    try {
      final scaffali = await widget.service.getElencoScaffaliArticolo(a.codice);
      if (!mounted) return;
      setState(() => _articoloInCorso = null);
      final testo =
          scaffali.map((s) => '${s.codice} - ${s.descrizione}').join('\n');
      await invAlert(context, 'Elenco Scaffali per ${a.codice}', testo);
    } catch (e) {
      if (!mounted) return;
      setState(() => _articoloInCorso = null);
      await invAlert(context, 'Errore',
          "Errore di Rete: Impossibile scaricare l'elenco degli Scaffali");
    }
  }

  // ---------------------------------------------------------------------------
  // '+' in basso: aggiunge un articolo allo scaffale (addArticoloToScaffale).
  // ---------------------------------------------------------------------------
  Future<void> _aggiungiArticolo() async {
    final scaffale = widget.scaffale.codice;

    if (!_puoModificare) {
      await invAlert(context, 'Accesso Negato',
          'Non hai i Permessi sufficienti per Aggiungere un Articolo ad uno Scaffale.');
      return;
    }

    final r = await invPrompt(
      context,
      'Aggiungi Articolo',
      "Digita l'Articolo da inserire nello Scaffale $scaffale",
      ['Aggiungi', 'Chiudi'],
      uppercase: true,
    );
    if (r == null || r.button != 0 || !mounted) return;

    final articolo = r.text.trim();
    if (articolo.isEmpty) {
      await invAlert(context, 'Articolo Non trovato',
          "L'articolo con codice $articolo non esiste. Riprova");
      return;
    }

    setState(() => _aggiuntaInCorso = true);
    try {
      // 1) Verifica che l'articolo esista (giacenze/selectSingoloArticolo).
      String? codice;
      try {
        codice = await widget.service.verificaArticolo(articolo);
      } catch (_) {
        codice = null;
      }
      if (!mounted) return;
      if (codice == null) {
        await invAlert(context, 'Articolo Non trovato',
            "L'articolo con codice $articolo non esiste. Riprova");
        return;
      }

      // 2) Inserimento nello scaffale: 'error' = articolo già presente.
      final bool aggiunto;
      try {
        aggiunto = await widget.service.addArticoloScaffale(scaffale, codice);
      } catch (_) {
        if (!mounted) return;
        await invAlert(context, 'Errore',
            "Non è stato possibile aggiungere l'Articolo $articolo. Riprova.");
        return;
      }
      if (!mounted) return;
      if (!aggiunto) {
        await invAlert(context, 'Errore',
            "Non è possibile aggiungere l'Articolo $articolo allo Scaffale $scaffale in quanto già esistente");
        return;
      }

      // Log (in Cordova applicazione.sendLogs).
      debugPrint(
          'Articolo $codice aggiunto allo scaffale $scaffale | Utente: $_codiceUtente');
      await invAlert(context, 'Articolo Aggiunto',
          'Articolo $codice aggiunto allo Scaffale $scaffale');
      if (!mounted) return;
      await _carica(); // ricarica la lista articoli dello scaffale
    } finally {
      if (mounted) setState(() => _aggiuntaInCorso = false);
    }
  }

  // ---------------------------------------------------------------------------
  // X sulla riga: elimina l'articolo dallo scaffale (deleteArticoloToScaffale).
  // ---------------------------------------------------------------------------
  Future<void> _eliminaArticolo(ArticoloScaffale a) async {
    if (_articoloInCorso != null) return;
    final scaffale = widget.scaffale.codice;
    final articolo = a.codice;

    if (!_puoModificare) {
      await invAlert(context, 'Accesso Negato',
          'Non hai i Permessi sufficienti per Eliminare un Articolo da uno Scaffale.');
      return;
    }

    final scelta = await invChoice(
      context,
      'Elimina Articolo',
      "Vuoi eliminare l'Articolo $articolo dallo Scaffale $scaffale?",
      ['Elimina', 'Chiudi'],
    );
    if (scelta != 0 || !mounted) return;

    setState(() => _articoloInCorso = articolo);
    try {
      // 1) Verifica che l'articolo esista (giacenze/selectSingoloArticolo).
      String? codice;
      try {
        codice = await widget.service.verificaArticolo(articolo);
      } catch (_) {
        codice = null;
      }
      if (!mounted) return;
      if (codice == null) {
        await invAlert(context, 'Articolo Non trovato',
            "L'articolo con codice $articolo non esiste. Riprova");
        return;
      }

      // 2) Eliminazione dallo scaffale (con il codice così com'è nello scaffale).
      try {
        await widget.service.deleteArticoloScaffale(scaffale, articolo);
      } catch (_) {
        if (!mounted) return;
        await invAlert(context, 'Errore',
            "Non è stato possibile eliminare l'Articolo $articolo. Riprova.");
        return;
      }
      if (!mounted) return;

      debugPrint(
          'Articolo $articolo eliminato dallo scaffale $scaffale | Utente: $_codiceUtente');
      await invAlert(context, 'Articolo Eliminato',
          'Articolo $articolo eliminato dallo Scaffale $scaffale');
      if (!mounted) return;
      await _carica(); // ricarica la lista articoli dello scaffale
    } finally {
      if (mounted) setState(() => _articoloInCorso = null);
    }
  }

  Future<void> _carica() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final articoli =
          await widget.service.getArticoliScaffale(widget.scaffale.codice);
      if (!mounted) return;
      setState(() {
        _articoli = articoli;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore di Rete o del Server';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scaffale;
    return Scaffold(
      appBar: AppBar(title: Text(s.codice)),
      body: _buildBody(),
      // '+' in basso al centro, come il pulsante addArticoloScaffale di Cordova.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (_loading || _error != null)
          ? null
          : FloatingActionButton(
              tooltip: 'Aggiungi Articolo',
              backgroundColor: AppColors.button,
              foregroundColor: Colors.white,
              onPressed: _aggiuntaInCorso ? null : _aggiungiArticolo,
              child: _aggiuntaInCorso
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.add, size: 32),
            ),
    );
  }

  Widget _buildBody() {
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
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _carica, child: const Text('Riprova')),
          ],
        ),
      );
    }
    final s = widget.scaffale;
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.codice,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                if (s.descrizione.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(s.descrizione,
                        style: const TextStyle(color: Colors.black54)),
                  ),
                if (s.magazzino.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Magazzino: ${s.magazzino}'),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Articoli: ${_articoli.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _articoli.isEmpty
              ? const Center(child: Text('Nessun articolo nello scaffale'))
              : ListView.separated(
                  // Spazio in fondo per non coprire l'ultima riga con il '+'.
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _articoli.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _articoloTile(_articoli[i]),
                ),
        ),
      ],
    );
  }

  Widget _articoloTile(ArticoloScaffale a) {
    return ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(a.codice,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text([
        if (a.descrizione.isNotEmpty) a.descrizione.toLowerCase(),
        [
          if (a.qtaConfezione.isNotEmpty) 'Pz: ${a.qtaConfezione}',
          if (a.tipo.isNotEmpty) a.tipo,
          if (a.fornitore.isNotEmpty) a.fornitore.toLowerCase(),
        ].join('  ·  '),
      ].join('\n')),
      isThreeLine: a.descrizione.isNotEmpty,
      // Tap sulla riga: elenco degli scaffali che contengono l'articolo.
      onTap: () => _mostraScaffaliArticolo(a),
      // X per togliere l'articolo dallo scaffale (⏳ durante l'operazione).
      trailing: _articoloInCorso == a.codice
          ? const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.spinner),
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.close, color: AppColors.buttonRed),
              tooltip: 'Elimina dallo Scaffale',
              onPressed: () => _eliminaArticolo(a),
            ),
    );
  }
}
