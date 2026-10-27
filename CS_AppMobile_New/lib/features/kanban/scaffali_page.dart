import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/kanban_articolo.dart';
import '../../models/scaffale_kanban.dart';
import '../../state/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    _carica();
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
    );
  }
}
