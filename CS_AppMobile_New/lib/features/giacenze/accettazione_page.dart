import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/accettazione.dart';
import '../../state/app_state.dart';
import '../scanner/barcode_scanner_page.dart';
import 'accettazione_service.dart';

/// Pagina Giacenze → Accettazione (scrittura) — porting (core) di
/// www/scripts/Giacenze-Magazzino/Pagine/Accettazione.
/// Scarica le accettazioni di un magazzino, permette di selezionare gli
/// articoli con quantità e inviarli al magazzino automatico (lista di carico).
/// Auto-refresh ogni 60s come nell'originale.
///
/// Sotto-funzioni rimandate: import lista di precarico, gestione UDC automha
/// avanzata, PDF movimenti, dettaglio mancanti/ordini.
class AccettazionePage extends StatefulWidget {
  const AccettazionePage({super.key});

  @override
  State<AccettazionePage> createState() => _AccettazionePageState();
}

class _AccettazionePageState extends State<AccettazionePage> {
  late final AccettazioneService _service;
  late final String _utente;

  final _magController = TextEditingController(text: 'MIRC001');
  final _magDestController = TextEditingController();

  bool _loading = false;
  bool _busy = false;
  String? _error;
  String? _info;

  List<Accettazione> _lista = [];
  String _magazzino = '';
  String _filtro = '';

  Timer? _timer;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _service = AccettazioneService(app.api);
    _utente = app.utenteLoggato.codiceUtente;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _magController.dispose();
    _magDestController.dispose();
    super.dispose();
  }

  void _avviaTimer() {
    _timer?.cancel();
    _countdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        _countdown = 60;
        if (!_busy && !_loading) _carica(silenzioso: true);
      }
    });
  }

  Future<void> _carica({bool silenzioso = false}) async {
    final mag = _magController.text.trim();
    if (mag.isEmpty) return;
    if (!silenzioso) FocusScope.of(context).unfocus();
    setState(() {
      if (!silenzioso) _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final res = await _service.getAccettazioni(mag);
      if (!mounted) return;
      // Mantengo selezioni/qta se ricarico lo stesso magazzino in silenzioso.
      final precedenti = {for (final a in _lista) a.id: a};
      if (silenzioso) {
        for (final a in res.lista) {
          final old = precedenti[a.id];
          if (old != null) {
            a.selezionato = old.selezionato;
            a.qtaCarico = old.qtaCarico;
          }
        }
      }
      setState(() {
        _magazzino = mag;
        _lista = res.lista;
        _loading = false;
        if (res.lista.isEmpty) _info = 'Nessuna accettazione per $mag';
        if (_magDestController.text.trim().isEmpty) {
          _magDestController.text = AccettazioniResult.magazzinoDestDefault(mag);
        }
      });
      _avviaTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silenzioso) _error = 'Errore di Rete o del Server';
        _loading = false;
      });
    }
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra magazzino');
    if (code == null || !mounted) return;
    _magController.text = code;
    _magDestController.clear();
    _carica();
  }

  List<Accettazione> get _filtrati {
    final q = _filtro.trim().toLowerCase();
    if (q.isEmpty) return _lista;
    return _lista
        .where((a) =>
            a.articolo.toLowerCase().contains(q) ||
            a.descrizione.toLowerCase().contains(q) ||
            a.fornitore.toLowerCase().contains(q) ||
            a.bolla.toLowerCase().contains(q))
        .toList();
  }

  List<Accettazione> get _selezionati =>
      _lista.where((a) => a.selezionato).toList();

  void _toggleAll(bool v) {
    setState(() {
      for (final a in _filtrati) {
        a.selezionato = v;
      }
    });
  }

  Future<void> _modificaQta(Accettazione a) async {
    final ctrl = TextEditingController(text: _n(a.qtaCarico));
    final nuovo = await showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Quantità ${a.articolo}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Quantità',
            helperText: 'Max ${_n(a.qtaGiacenza)} ${a.um}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final q = num.tryParse(ctrl.text.trim().replaceAll(',', '.'));
              if (q != null && q > 0) Navigator.of(ctx).pop(q);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (nuovo != null) setState(() => a.qtaCarico = nuovo);
  }

  Future<void> _invia() async {
    final sel = _selezionati;
    if (sel.isEmpty) return;

    // Validazione: qta non superiore alla giacenza.
    final eccesso = sel.where((a) => a.qtaCarico > a.qtaGiacenza).toList();
    if (eccesso.isNotEmpty) {
      _alert('Impossibile inviare',
          'Alcuni articoli hanno quantità superiore alla giacenza:\n${eccesso.map((a) => '• ${a.articolo}').join('\n')}');
      return;
    }

    final magDest = _magDestController.text.trim();
    if (magDest.isEmpty) {
      _alert('Magazzino destinazione', 'Specifica il magazzino di destinazione.');
      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invia lista di carico'),
        content: Text(
            'Inviare ${sel.length} articolo/i da $_magazzino a $magDest?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Invia'),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    setState(() => _busy = true);
    try {
      final esito = await _service.inviaListaCarico(
        utente: _utente,
        magazzinoOrigine: _magazzino,
        magazzinoDestinazione: magDest,
        righe: sel,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (esito.isSuccess) {
        _alert('Lista inviata', 'Lista di carico inviata con successo!');
        _carica(silenzioso: true);
      } else {
        _alert('Errore', 'Invio non riuscito:\n${esito.response.trim()}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore di rete', 'Invio della lista non riuscito.');
    }
  }

  void _alert(String title, String msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(msg)),
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
    final sel = _selezionati.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accettazione'),
        actions: [
          if (_lista.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 4),
                    Text('${_countdown}s', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(),
              if (_lista.isNotEmpty) _toolbar(),
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
      bottomNavigationBar: (_lista.isNotEmpty && sel > 0)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text('Invia lista di carico ($sel)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.casagrandeDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _invia,
                ),
              ),
            )
          : null,
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _magController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    _magDestController.clear();
                    _carica();
                  },
                  decoration: InputDecoration(
                    hintText: 'Magazzino accettazione',
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
                onPressed: _loading
                    ? null
                    : () {
                        _magDestController.clear();
                        _carica();
                      },
                child: const Text('Cerca'),
              ),
            ],
          ),
          if (_lista.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _magDestController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Magazzino destinazione (automatico)',
                prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolbar() {
    final filtrati = _filtrati;
    final tutti = filtrati.isNotEmpty && filtrati.every((a) => a.selezionato);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _filtro = v),
              decoration: const InputDecoration(
                hintText: 'Filtra',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          TextButton(
            onPressed: filtrati.isEmpty ? null : () => _toggleAll(!tutti),
            child: Text(tutti ? 'Deselez.' : 'Selez. tutti'),
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
      return _centerMsg(Icons.cloud_off, _error!, retry: _carica);
    }
    if (_lista.isEmpty) {
      return _centerMsg(Icons.fact_check_outlined,
          _info ?? 'Inserisci un magazzino per vedere le accettazioni');
    }
    final lista = _filtrati;
    if (lista.isEmpty) {
      return _centerMsg(Icons.filter_alt_off, 'Nessun risultato per il filtro');
    }
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _tile(lista[i]),
    );
  }

  Widget _tile(Accettazione a) {
    return CheckboxListTile(
      value: a.selezionato,
      onChanged: (v) => setState(() => a.selezionato = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Row(
        children: [
          if (a.isMancante)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.warning_amber, size: 16, color: Color(0xFFEF6C00)),
            ),
          Expanded(
            child: Text(a.articolo,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: a.selezionato ? () => _modificaQta(a) : null,
            child: Text(
              '${_n(a.qtaCarico)} ${a.um}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: a.selezionato ? const Color(0xFF3949AB) : Colors.black87,
                decoration:
                    a.selezionato ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text([
        if (a.descrizione.isNotEmpty) a.descrizione.toLowerCase(),
        'Bolla ${a.bolla} · ${a.fornitore.toLowerCase()}',
        'Giac ${_n(a.qtaGiacenza)}'
            '${a.ordine.isNotEmpty ? ' · ord ${a.ordine}' : ''}'
            '${a.dataMovimento.isNotEmpty ? ' · ${a.dataMovimento}' : ''}',
      ].join('\n')),
      isThreeLine: true,
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
