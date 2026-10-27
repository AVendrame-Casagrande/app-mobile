import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/kanban_articolo.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'scaffali_service.dart';

/// Pagina Kanban → Articoli — porting di
/// www/scripts/Kanban/Pagine/Articoli.
/// Cerca un articolo Kanban e ne mostra info + scaffali in cui è presente.
class KanbanArticoliPage extends StatefulWidget {
  const KanbanArticoliPage({super.key});

  @override
  State<KanbanArticoliPage> createState() => _KanbanArticoliPageState();
}

class _KanbanArticoliPageState extends State<KanbanArticoliPage> {
  late final ScaffaliService _service;
  final _controller = TextEditingController();

  static const String _sezione = 'cerca_kanban';

  bool _loading = false;
  String? _error;
  String? _info;
  ArticoloKanban? _articolo;
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    _service = ScaffaliService(context.read<AppState>().api);
    _recenti = LastSearched.get(_sezione);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cerca() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _articolo = null;
    });
    try {
      final art = await _service.getArticoloKanban(code);
      if (!mounted) return;
      if (art != null && art.trovato) {
        await LastSearched.add(_sezione, art.codice);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (art == null || !art.trovato) {
          _info = 'Articolo $code non trovato';
        } else {
          _articolo = art;
        }
        _recenti = LastSearched.get(_sezione);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore di Rete o del Server';
        _loading = false;
      });
    }
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra articolo');
    if (code == null || !mounted) return;
    _controller.text = code;
    _cerca();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Articoli Kanban')),
      body: Column(
        children: [
          _searchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
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
              onSubmitted: (_) => _cerca(),
              decoration: InputDecoration(
                hintText: 'Codice articolo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _loading ? null : _scansiona,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _loading ? null : _cerca,
            child: const Text('Cerca'),
          ),
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
      return _centerMsg(Icons.cloud_off, _error!, retry: _cerca);
    }
    final a = _articolo;
    if (a == null) {
      if (_info != null) {
        return _centerMsg(Icons.inventory_2_outlined, _info!);
      }
      return LastSearchedList(
        items: _recenti,
        onTap: (codice) {
          _controller.text = codice;
          _cerca();
        },
        onClear: _recenti.isEmpty
            ? null
            : () async {
                await LastSearched.clear(_sezione);
                if (!mounted) return;
                setState(() => _recenti = LastSearched.get(_sezione));
              },
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(a.codice,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (a.descrizione.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(a.descrizione.toLowerCase(),
                style: const TextStyle(color: Colors.black54)),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (a.tipo.isNotEmpty) _kv('Tipo', a.isKanban ? 'N (Kanban)' : a.tipo),
                if (a.qtaConfezione.isNotEmpty) _kv('Q.tà confezione', a.qtaConfezione),
                if (a.unitaMisura.isNotEmpty) _kv('Unità di misura', a.unitaMisura),
                if (a.fornitore.isNotEmpty)
                  _kv('Fornitore',
                      '${a.fornitore}${a.fornitoreDescrizione.isNotEmpty ? ' - ${a.fornitoreDescrizione.toLowerCase()}' : ''}'),
                if (a.trattamento.isNotEmpty) _kv('Trattamento', a.trattamento),
                if (a.colore.isNotEmpty) _kv('Colore', a.colore),
                if (a.scortaMinima.isNotEmpty) _kv('Scorta minima', a.scortaMinima),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text('Scaffali (${a.listaScaffali.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        if (a.listaScaffali.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('Articolo non presente in scaffali')),
          )
        else
          ...a.listaScaffali.map((s) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.shelves),
                  title: Text(s.codice,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([
                    if (s.descrizione.isNotEmpty) s.descrizione,
                    if (s.magazzino.isNotEmpty) 'Mag: ${s.magazzino}',
                  ].join('   ')),
                ),
              )),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(k, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 3,
            child: Text(v,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
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
