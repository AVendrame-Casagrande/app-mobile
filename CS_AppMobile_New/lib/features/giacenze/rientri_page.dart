import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rientro.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'rientri_service.dart';

/// Pagina Giacenze → Rientri (scrittura) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/Rientri.
/// Elenca i rientri di un magazzino e invia il movimento di rientro
/// verso uno dei magazzini di destinazione.
class RientriPage extends StatefulWidget {
  const RientriPage({super.key});

  @override
  State<RientriPage> createState() => _RientriPageState();
}

class _RientriPageState extends State<RientriPage> {
  late final RientriService _service;
  late final String _societa;

  final _magController = TextEditingController();

  static const String _sezione = 'rientri';

  bool _loading = false;
  bool _busy = false;
  String? _error;
  String? _info;
  String _magazzino = '';
  List<Rientro> _rientri = [];
  String _filtro = '';
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _service = RientriService(app.api);
    _societa = app.utenteLoggato.isEnglish ? 'CSUSA' : 'CSPRO';
    _recenti = LastSearched.get(_sezione);
  }

  @override
  void dispose() {
    _magController.dispose();
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
      _rientri = [];
      _magazzino = mag;
    });
    try {
      final lista = await _service.getRientri(mag);
      if (!mounted) return;
      if (lista.isNotEmpty) {
        await LastSearched.add(_sezione, mag);
      }
      if (!mounted) return;
      setState(() {
        _rientri = lista;
        _loading = false;
        if (lista.isEmpty) _info = 'Nessun rientro per il magazzino $mag';
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
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra magazzino');
    if (code == null || !mounted) return;
    _magController.text = code;
    _cerca();
  }

  List<Rientro> get _filtrati {
    final q = _filtro.trim().toLowerCase();
    if (q.isEmpty) return _rientri;
    return _rientri
        .where((r) =>
            r.articolo.toLowerCase().contains(q) ||
            r.vano.toLowerCase().contains(q) ||
            r.descrizione.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _apriRientro(Rientro r) async {
    final result = await showDialog<_RientroRichiesta>(
      context: context,
      builder: (_) => _RientroDialog(rientro: r),
    );
    if (result == null || !mounted) return;
    await _invia(r, result.magazzino, result.qta);
  }

  Future<void> _invia(Rientro r, String amag, num qta) async {
    final utente = context.read<AppState>().utenteLoggato.codiceUtente;
    setState(() => _busy = true);
    try {
      final esito = await _service.inviaMovimento(
        articolo: r.articolo,
        damag: _magazzino,
        davano: r.vano,
        amag: amag,
        qta: qta,
        utente: utente,
        societa: _societa,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (esito.isSuccess) {
          _rientri.remove(r);
        }
      });
      _alert('Stato Movimento', esito.response.trim().isEmpty
          ? (esito.isSuccess ? 'Rientro eseguito' : 'Esito sconosciuto')
          : esito.response.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore', 'Errore di rete durante il movimento');
    }
  }

  void _alert(String title, String msg) {
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
      appBar: AppBar(title: const Text('Rientri')),
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(),
              if (_rientri.isNotEmpty) _filtroBar(),
              Expanded(child: _buildBody()),
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
    );
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
                hintText: 'Magazzino',
                prefixIcon: const Icon(Icons.warehouse_outlined),
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

  Widget _filtroBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        onChanged: (v) => setState(() => _filtro = v),
        decoration: const InputDecoration(
          hintText: 'Filtra articolo, vano o descrizione',
          prefixIcon: Icon(Icons.search, size: 20),
          border: OutlineInputBorder(),
          isDense: true,
        ),
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
    if (_rientri.isEmpty) {
      if (_info != null) {
        return _centerMsg(Icons.assignment_return_outlined, _info!);
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
    final lista = _filtrati;
    if (lista.isEmpty) {
      return _centerMsg(Icons.filter_alt_off, 'Nessun rientro per il filtro');
    }
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = lista[i];
        return ListTile(
          title: Text(r.articolo,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.descrizione.isNotEmpty) Text(r.descrizione.toLowerCase()),
              Text('Libera: ${_n(r.qtaLibera)}'
                  '${r.vano.isNotEmpty ? '  ·  Vano ${r.vano}' : ''}'
                  '   (Tot ${_n(r.qtaTotale)} / Imp ${_n(r.qtaImpegnata)})',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          isThreeLine: r.descrizione.isNotEmpty,
          trailing: const Icon(Icons.assignment_return),
          onTap: r.qtaLibera <= 0 ? null : () => _apriRientro(r),
        );
      },
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

  static String _n(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }
}

/// Richiesta di rientro confermata.
class _RientroRichiesta {
  final String magazzino;
  final num qta;
  _RientroRichiesta(this.magazzino, this.qta);
}

/// Dialog per scegliere magazzino destinazione e quantità del rientro.
class _RientroDialog extends StatefulWidget {
  const _RientroDialog({required this.rientro});
  final Rientro rientro;

  @override
  State<_RientroDialog> createState() => _RientroDialogState();
}

class _RientroDialogState extends State<_RientroDialog> {
  late final TextEditingController _qtaController;
  String _magazzino = RientriService.magazziniDestinazione.first;

  @override
  void initState() {
    super.initState();
    final q = widget.rientro.qtaLibera;
    _qtaController = TextEditingController(
        text: q == q.roundToDouble() ? q.toInt().toString() : q.toString());
  }

  @override
  void dispose() {
    _qtaController.dispose();
    super.dispose();
  }

  String? get _errore {
    final t = _qtaController.text.trim();
    final q = num.tryParse(t.replaceAll(',', '.'));
    if (q == null) return 'Quantità non valida';
    if (q <= 0) return 'Deve essere maggiore di 0';
    if (q > widget.rientro.qtaLibera) return 'Eccede la quantità libera';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rientro;
    return AlertDialog(
      title: const Text('Rientro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Articolo: ${r.articolo}'),
          if (r.vano.isNotEmpty) Text('Vano: ${r.vano}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _magazzino,
            decoration: const InputDecoration(
              labelText: 'Magazzino destinazione',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: RientriService.magazziniDestinazione
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) =>
                setState(() => _magazzino = v ?? _magazzino),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Quantità',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _errore,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _errore != null
              ? null
              : () {
                  final q = num.parse(
                      _qtaController.text.trim().replaceAll(',', '.'));
                  Navigator.of(context).pop(_RientroRichiesta(_magazzino, q));
                },
          child: const Text('Invia'),
        ),
      ],
    );
  }
}
