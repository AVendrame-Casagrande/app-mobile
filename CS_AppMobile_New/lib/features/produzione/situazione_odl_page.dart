import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/situazione_odl.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'situazione_odl_service.dart';

/// Pagina Produzione → Situazione ODL (read-only) — porting di
/// www/scripts/Produzione-Odl/Pagine/SituazioneOdl.
/// Cerca un ODL/padre e ne mostra la situazione divisa per sezioni
/// (REP / PREL / ODA / ODL / MANCANTI) con filtro.
class SituazioneOdlPage extends StatefulWidget {
  const SituazioneOdlPage({super.key});

  @override
  State<SituazioneOdlPage> createState() => _SituazioneOdlPageState();
}

class _SituazioneOdlPageState extends State<SituazioneOdlPage> {
  late final SituazioneOdlService _service;
  final _controller = TextEditingController();

  static const String _sezione = 'situazione_odl';

  bool _loading = false;
  String? _error;
  String? _info;
  SituazioneOdlResult? _result;
  SezioneOdl? _filtro; // null = TUTTI
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    _service = SituazioneOdlService(context.read<AppState>().api);
    _recenti = LastSearched.get(_sezione);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cerca() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    if (input.length < 4) {
      _showAlert('Inserimento errato',
          'Attenzione: devi digitare almeno 4 caratteri');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _result = null;
      _filtro = null;
    });
    try {
      final lista = await _service.checkOdl(input);
      if (!mounted) return;
      if (lista.isEmpty) {
        setState(() {
          _info = 'Nessun risultato per la ricerca "$input"';
          _loading = false;
        });
      } else if (lista.length == 1) {
        await _caricaSituazione(lista.first.odl);
      } else {
        setState(() => _loading = false);
        _scegliOdl(lista);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore di Rete o del Server';
        _loading = false;
      });
    }
  }

  Future<void> _caricaSituazione(String odl) async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _result = null;
      _filtro = null;
    });
    try {
      final res = await _service.getSituazioneOdl(odl);
      if (!mounted) return;
      if (!res.isEmpty) {
        await LastSearched.add(_sezione, odl);
      }
      if (!mounted) return;
      setState(() {
        _result = res;
        _info = res.isEmpty ? 'Nessun risultato per l\'ODL $odl' : null;
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

  Future<void> _scegliOdl(List<CheckOdl> lista) async {
    final scelto = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('ODL multipli (${lista.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final o = lista[i];
                    return ListTile(
                      title: Text(o.odl,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(o.scadenzaFmt),
                      onTap: () => Navigator.of(ctx).pop(o.odl),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (scelto != null) {
      await _caricaSituazione(scelto);
    }
  }

  void _showAlert(String title, String msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Situazione ODL')),
      body: Column(
        children: [
          _searchBar(),
          if (_result != null && !_result!.isEmpty) _header(_result!),
          if (_result != null && !_result!.isEmpty) _filtri(_result!),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra ODL / Padre');
    if (code == null || !mounted) return;
    _controller.text = code;
    _cerca();
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _cerca(),
              decoration: InputDecoration(
                hintText: 'ODL / Padre (min 4 caratteri)',
                prefixIcon: const Icon(Icons.search),
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

  Widget _header(SituazioneOdlResult r) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Padre: ${r.padre}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text('Stato: ${r.statoPadre}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: Text('Q.tà: ${_n(r.qtaResPadre)}')),
                Text('Fabb: ${r.dataPadre}'),
              ],
            ),
            if (r.descPadre.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(r.descPadre.toLowerCase(),
                    style: const TextStyle(color: Colors.black54)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filtri(SituazioneOdlResult r) {
    final sezioni = r.sezioniPresenti;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip('TUTTI (${r.conteggio(null)})', _filtro == null,
              () => setState(() => _filtro = null), Colors.blueGrey),
          for (final s in sezioni)
            _chip('${s.label} (${r.conteggio(s)})', _filtro == s,
                () => setState(() => _filtro = s), _coloreSezione(s)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: color.withValues(alpha: 0.25),
        onSelected: (_) => onTap(),
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
    if (_result != null && !_result!.isEmpty) {
      final righe = _filtro == null
          ? _result!.righe
          : _result!.righe.where((r) => r.sezione == _filtro).toList();
      if (righe.isEmpty) {
        return _centerMessage(Icons.filter_alt_off, 'Nessuna riga per il filtro');
      }
      return ListView.separated(
        itemCount: righe.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (_, i) => _rigaTile(righe[i]),
      );
    }
    if (_info != null) {
      return _centerMessage(Icons.search_off, _info!);
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

  Widget _rigaTile(SituazioneOdlRiga r) {
    final colore = _coloreSezione(r.sezione);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 4, height: 44, color: colore),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(r.articolo,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (r.haNota)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.sticky_note_2_outlined, size: 14),
                        ),
                    ],
                  ),
                  Text(r.descArticolo.toLowerCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.fase.isNotEmpty ? '${r.fase} · ' : ''}'
                    '${r.sezione.label.toLowerCase()}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: colore),
                  ),
                  if (r.ordine.isNotEmpty)
                    Text(r.ordine, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                r.dettaglioQuantita,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _coloreSezione(SezioneOdl s) {
    switch (s) {
      case SezioneOdl.rep:
        return const Color(0xFF2E7D32); // verde
      case SezioneOdl.prel:
        return const Color(0xFFF9A825); // giallo
      case SezioneOdl.oda:
        return const Color(0xFFEF6C00); // arancio
      case SezioneOdl.odl:
        return const Color(0xFF3949AB); // blu
      case SezioneOdl.mancanti:
        return const Color(0xFFC62828); // rosso
    }
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

  static String _n(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }
}
