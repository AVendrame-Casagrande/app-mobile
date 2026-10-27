import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/local_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/kanban_articolo.dart';
import '../../models/scaffale_kanban.dart';
import '../../state/app_state.dart';
import '../scanner/barcode_scanner_page.dart';
import 'scaffali_service.dart';

/// Voce della lista di rifornimento.
class _RigaRifornimento {
  final ScaffaleKanban scaffale;
  final ArticoloKanban articolo;
  final int quantita;

  _RigaRifornimento({
    required this.scaffale,
    required this.articolo,
    required this.quantita,
  });

  Map<String, dynamic> toJson() => {
        'scaffale': scaffale.toJson(),
        'articolo': articolo.toJson(),
        'quantita': quantita,
        'termid': null,
        'uniqid': null,
        'tipoLista': 'rifornimento',
      };

  factory _RigaRifornimento.fromJson(Map<String, dynamic> json) =>
      _RigaRifornimento(
        scaffale: ScaffaleKanban.fromJson(
            Map<String, dynamic>.from(json['scaffale'] ?? {})),
        articolo: ArticoloKanban.fromJson(
            Map<String, dynamic>.from(json['articolo'] ?? {})),
        quantita: (json['quantita'] ?? 1) is int
            ? json['quantita']
            : int.tryParse('${json['quantita']}') ?? 1,
      );
}

/// Pagina Kanban → Rifornimento — porting di
/// www/scripts/Kanban/Pagine/Rifornimenti.
/// Compone una lista di rifornimenti (scaffale + articolo Kanban + quantità)
/// e la invia ai fornitori.
/// La suddivisione automatica MGAUT/email interna è rimandata: tutte le righe
/// sono inviate come ordini di rifornimento standard.
class RifornimentoPage extends StatefulWidget {
  const RifornimentoPage({super.key});

  @override
  State<RifornimentoPage> createState() => _RifornimentoPageState();
}

class _RifornimentoPageState extends State<RifornimentoPage> {
  static const _storageKey = 'listaRifornimenti';

  late final ScaffaliService _service;

  final _scaffaleController = TextEditingController();
  final _articoloController = TextEditingController();
  final _qtaController = TextEditingController(text: '1');

  bool _busy = false;
  ScaffaleKanban? _scaffale;
  ArticoloKanban? _articolo;
  final List<_RigaRifornimento> _lista = [];

  @override
  void initState() {
    super.initState();
    _service = ScaffaliService(context.read<AppState>().api);
    _caricaDaStorage();
  }

  @override
  void dispose() {
    _scaffaleController.dispose();
    _articoloController.dispose();
    _qtaController.dispose();
    super.dispose();
  }

  void _caricaDaStorage() {
    final raw = LocalStorage.instance.getJson(_storageKey);
    if (raw is List) {
      for (final e in raw.whereType<Map>()) {
        try {
          _lista.add(_RigaRifornimento.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
  }

  Future<void> _salvaInStorage() async {
    await LocalStorage.instance
        .setJson(_storageKey, _lista.map((r) => r.toJson()).toList());
  }

  // ---------------------------------------------------------------------------
  Future<void> _cercaScaffale() async {
    final code = _scaffaleController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final lista = await _service.getSingoloScaffale(code, limitPresent: true);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scaffale = lista.isNotEmpty ? lista.first : null;
        if (_scaffale == null) _alert('Scaffale', 'Scaffale $code non trovato.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore', 'Errore di rete nella ricerca scaffale.');
    }
  }

  Future<void> _cercaArticolo() async {
    final code = _articoloController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final art = await _service.getArticoloKanban(code);
      if (!mounted) return;
      setState(() => _busy = false);
      if (art == null || !art.trovato) {
        _alert('Articolo', 'L\'articolo $code non esiste.');
        return;
      }
      if (!art.isKanban) {
        _alert('Articolo non Kanban',
            'L\'articolo $code non è di tipo N (Kanban).');
        return;
      }
      setState(() => _articolo = art);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore', 'Errore di rete nella ricerca articolo.');
    }
  }

  Future<void> _scan(TextEditingController c, String titolo, VoidCallback then) async {
    final code = await BarcodeScannerPage.scan(context, titolo: titolo);
    if (code == null || !mounted) return;
    c.text = code;
    then();
  }

  Future<void> _aggiungi() async {
    final s = _scaffale;
    final a = _articolo;
    if (s == null || a == null) return;
    final qta = int.tryParse(_qtaController.text.trim()) ?? 0;
    if (qta <= 0) {
      _alert('Quantità', 'Inserisci una quantità valida.');
      return;
    }
    setState(() {
      _lista.add(_RigaRifornimento(scaffale: s, articolo: a, quantita: qta));
      _articolo = null;
      _articoloController.clear();
      _qtaController.text = '1';
    });
    await _salvaInStorage();
  }

  Future<void> _elimina(_RigaRifornimento r) async {
    setState(() => _lista.remove(r));
    await _salvaInStorage();
  }

  Future<void> _invia() async {
    if (_lista.isEmpty) return;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invia rifornimento'),
        content: Text('Inviare ${_lista.length} ordini di rifornimento?'),
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
      final ok = await _service.inviaRifornimento(
          _lista.map((r) => r.toJson()).toList());
      if (!mounted) return;
      if (ok) {
        setState(() {
          _lista.clear();
          _busy = false;
        });
        await _salvaInStorage();
        _alert('Inviato', 'Rifornimento inviato con successo!');
      } else {
        setState(() => _busy = false);
        _alert('Errore', 'Rifornimento non inviato.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore', 'Errore di rete durante l\'invio.');
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

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rifornimento')),
      body: Stack(
        children: [
          Column(
            children: [
              _form(),
              const Divider(height: 1),
              Expanded(child: _listaView()),
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
      bottomNavigationBar: _lista.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text('Invia rifornimento (${_lista.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.casagrandeDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _invia,
                ),
              ),
            ),
    );
  }

  Widget _form() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _campoRicerca(
            controller: _scaffaleController,
            hint: 'Scaffale',
            icon: Icons.shelves,
            onCerca: _cercaScaffale,
            onScan: () => _scan(_scaffaleController, 'Inquadra scaffale', _cercaScaffale),
          ),
          if (_scaffale != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  '✓ ${_scaffale!.codice}'
                  '${_scaffale!.magazzino.isNotEmpty ? ' (${_scaffale!.magazzino})' : ''}'
                  '${_scaffale!.qtaCella.isNotEmpty ? ' · cella ${_scaffale!.qtaCella}' : ''}',
                  style: const TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _campoRicerca(
            controller: _articoloController,
            hint: 'Articolo Kanban',
            icon: Icons.inventory_2_outlined,
            onCerca: _cercaArticolo,
            onScan: () => _scan(_articoloController, 'Inquadra articolo', _cercaArticolo),
          ),
          if (_articolo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  '✓ ${_articolo!.codice} - ${_articolo!.descrizione.toLowerCase()}',
                  style: const TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _qtaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantità',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                  onPressed: (_scaffale != null && _articolo != null) ? _aggiungi : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campoRicerca({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onCerca,
    required VoidCallback onScan,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onCerca(),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _busy ? null : onScan,
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _busy ? null : onCerca,
          child: const Text('Cerca'),
        ),
      ],
    );
  }

  Widget _listaView() {
    if (_lista.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_outlined, size: 48, color: Colors.black38),
            SizedBox(height: 12),
            Text('Nessun rifornimento in lista'),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = _lista[i];
        return Dismissible(
          key: ValueKey('${r.articolo.codice}_${r.scaffale.codice}_$i'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: const Color(0xFFC62828),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _elimina(r),
          child: ListTile(
            title: Text(r.articolo.codice,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text([
              if (r.articolo.descrizione.isNotEmpty)
                r.articolo.descrizione.toLowerCase(),
              'Scaffale ${r.scaffale.codice}',
            ].join('\n')),
            isThreeLine: r.articolo.descrizione.isNotEmpty,
            trailing: Text('Q.tà ${r.quantita}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
