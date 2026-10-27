import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/giacenza_inventario.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'giacenza_inventario_service.dart';

/// Pagina Giacenze → Giacenza Inventario (read-only) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/GiacenzaInventario.
/// Mostra le giacenze di un magazzino, con filtro per vano e ricerca articolo.
class GiacenzaInventarioPage extends StatefulWidget {
  const GiacenzaInventarioPage({super.key});

  @override
  State<GiacenzaInventarioPage> createState() => _GiacenzaInventarioPageState();
}

class _GiacenzaInventarioPageState extends State<GiacenzaInventarioPage> {
  late final GiacenzaInventarioService _service;
  final _magController = TextEditingController();
  final _vanoController = TextEditingController();

  static const String _sezione = 'giacenze_inventario';

  bool _loading = false;
  String? _error;
  String? _info;
  List<GiacenzaInventario> _tutte = [];
  bool _hasVani = false;
  String _vanoFiltro = '';
  String _ricercaArticolo = '';
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    _service = GiacenzaInventarioService(context.read<AppState>().api);
    _recenti = LastSearched.get(_sezione);
  }

  @override
  void dispose() {
    _magController.dispose();
    _vanoController.dispose();
    super.dispose();
  }

  Future<void> _cerca() async {
    final mag = _magController.text.trim();
    if (mag.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _tutte = [];
      _hasVani = false;
    });
    try {
      final lista = await _service.getGiacenze(mag);
      if (!mounted) return;
      if (lista.isNotEmpty) {
        await LastSearched.add(_sezione, mag);
      }
      if (!mounted) return;
      setState(() {
        _tutte = lista;
        _hasVani = lista.any((g) => g.vano.isNotEmpty);
        _info = lista.isEmpty ? 'Nessuna giacenza per il magazzino $mag' : null;
        _loading = false;
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

  List<GiacenzaInventario> get _filtrate {
    final vano = _vanoFiltro.trim().toLowerCase();
    final art = _ricercaArticolo.trim().toLowerCase();
    return _tutte.where((g) {
      if (vano.isNotEmpty && !g.vano.toLowerCase().contains(vano)) return false;
      if (art.isNotEmpty &&
          !g.articolo.toLowerCase().contains(art) &&
          !g.descrizione.contains(art)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giacenze Inventario')),
      body: Column(
        children: [
          _searchBar(),
          if (_tutte.isNotEmpty) _filtriRiga(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra magazzino');
    if (code == null || !mounted) return;
    _magController.text = code;
    _cerca();
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _magController,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _cerca(),
              decoration: InputDecoration(
                hintText: 'Codice magazzino',
                prefixIcon: const Icon(Icons.warehouse_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scansiona',
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

  Widget _filtriRiga() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _ricercaArticolo = v),
              decoration: const InputDecoration(
                hintText: 'Filtra articolo',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          if (_hasVani) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _vanoController,
                onChanged: (v) => setState(() => _vanoFiltro = v),
                decoration: const InputDecoration(
                  hintText: 'Vano',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
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
      return _centerMessage(Icons.cloud_off, _error!, retry: _cerca);
    }
    if (_tutte.isNotEmpty) {
      final lista = _filtrate;
      if (lista.isEmpty) {
        return _centerMessage(Icons.filter_alt_off, 'Nessun articolo per il filtro');
      }
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${lista.length} articoli',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (_, i) => _giacenzaTile(lista[i]),
            ),
          ),
        ],
      );
    }
    if (_info != null) {
      return _centerMessage(Icons.search_off, _info!);
    }
    return LastSearchedList(
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
    );
  }

  Widget _giacenzaTile(GiacenzaInventario g) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(g.articolo,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (g.vano.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5966A8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Vano ${g.vano}',
                        style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            if (g.descrizione.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(g.descrizione,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                _qta('Giac', g.qtaGiacente, Colors.black87),
                _qta('Imp', g.impegnato, const Color(0xFFC62828)),
                _qta('Disp', g.disponibile, const Color(0xFF2E7D32)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qta(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value.isEmpty ? '-' : value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
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
