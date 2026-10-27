import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/zebra_printer_service.dart';
import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stampa_verniciatura.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'stampa_service.dart';

/// Pagina Stampa Etichette (verniciatura) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/Stampa.
/// Cerca gli ODL per magazzino destinazione, compila l'etichetta e la stampa
/// sulla stampante Zebra di rete (ZPL via HTTP, nessun Bluetooth).
class StampaPage extends StatefulWidget {
  const StampaPage({super.key});

  @override
  State<StampaPage> createState() => _StampaPageState();
}

class _StampaPageState extends State<StampaPage> {
  late final StampaService _service;
  final _printer = ZebraPrinterService();

  final _magController = TextEditingController();
  final _noteController = TextEditingController();
  final _qtaController = TextEditingController(text: '1');

  static const String _sezione = 'stampa';

  bool _loading = false;
  String? _error;
  bool _libera = false;

  List<OdlStampa> _listaOdl = [];
  StampaVerniciatura? _etichetta;
  List<String> _fasi = [];
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    _service = StampaService(context.read<AppState>().api);
    _recenti = LastSearched.get(_sezione);
  }

  @override
  void dispose() {
    _magController.dispose();
    _noteController.dispose();
    _qtaController.dispose();
    super.dispose();
  }

  String get _codiceUtente => context.read<AppState>().utenteLoggato.codiceUtente;

  Future<void> _cercaOdl() async {
    final mag = _magController.text.trim();
    if (mag.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _listaOdl = [];
      _etichetta = null;
    });
    try {
      final lista = await _service.getOdlList(mag);
      if (!mounted) return;
      if (lista.isNotEmpty) {
        await LastSearched.add(_sezione, mag);
      }
      if (!mounted) return;
      setState(() {
        _listaOdl = lista;
        _loading = false;
        if (lista.isEmpty) _error = 'Nessun ODL per il magazzino $mag';
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

  Future<void> _selezionaOdl(String odl) async {
    setState(() => _loading = true);
    try {
      final info =
          _libera ? await _service.addInfoOdlLibera(odl) : await _service.addInfoOdl(odl);
      if (!mounted) return;
      final mag = _magController.text.trim();
      setState(() {
        _fasi = info.listaFasi;
        _etichetta = StampaVerniciatura(
          magazzinoDestinazione: mag,
          odlSelected: odl,
          padre: info.padre,
          descrizionePadre: info.descrizionePadre,
          colore: info.colore,
          faseSelected: info.listaFasi.isNotEmpty ? info.listaFasi.first : '',
          etichettaIsLibera: _libera,
        );
        _noteController.text = '';
        _qtaController.text = '1';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore: impossibile contattare il server';
        _loading = false;
      });
    }
  }

  void _nuovaEtichettaLibera() {
    setState(() {
      _libera = true;
      _fasi = [];
      _etichetta = StampaVerniciatura(
        magazzinoDestinazione: _magController.text.trim(),
        etichettaIsLibera: true,
      );
      _noteController.text = '';
      _qtaController.text = '1';
    });
  }

  Future<void> _stampa() async {
    final e = _etichetta;
    if (e == null) return;
    e.note = _noteController.text.trim();
    e.qtaEtichetteDaStampare = int.tryParse(_qtaController.text.trim()) ?? 1;

    final zpl = e.toZpl(codiceUtente: _codiceUtente);
    setState(() => _loading = true);
    try {
      await _printer.printCopies(zpl, e.qtaEtichetteDaStampare);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Stampate ${e.qtaEtichetteDaStampare} etichette su ${ZebraPrinterService.printerIp}')),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore stampa: ${ZebraPrinterService.printerIp} non raggiungibile')),
      );
    }
  }

  Future<void> _impostaIp() async {
    final controller =
        TextEditingController(text: ZebraPrinterService.printerIp);
    final nuovo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('IP stampante Zebra'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            hintText: 'es. 10.0.0.98',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (nuovo != null && nuovo.isNotEmpty) {
      await ZebraPrinterService.setPrinterIp(nuovo);
      if (mounted) setState(() {});
    }
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra magazzino');
    if (code == null || !mounted) return;
    _magController.text = code;
    _cercaOdl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etichette'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'IP stampante (${ZebraPrinterService.printerIp})',
            onPressed: _impostaIp,
          ),
        ],
      ),
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
              controller: _magController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _cercaOdl(),
              decoration: InputDecoration(
                hintText: 'Magazzino destinazione',
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
            onPressed: _loading ? null : _cercaOdl,
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
    if (_etichetta != null) {
      return _formEtichetta(_etichetta!);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _listaOdl.isEmpty
                      ? (_error ?? 'Cerca un magazzino o crea un\'etichetta libera')
                      : 'ODL trovati: ${_listaOdl.length}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('Libera'),
                onPressed: _nuovaEtichettaLibera,
              ),
            ],
          ),
        ),
        Expanded(
          child: _listaOdl.isEmpty
              ? (_error != null
                  ? const Center(
                      child: Icon(Icons.local_printshop_outlined,
                          size: 48, color: Colors.black26),
                    )
                  : LastSearchedList(
                      items: _recenti,
                      onTap: (codice) {
                        _magController.text = codice;
                        _cercaOdl();
                      },
                      onClear: _recenti.isEmpty
                          ? null
                          : () async {
                              await LastSearched.clear(_sezione);
                              if (!mounted) return;
                              setState(() => _recenti = LastSearched.get(_sezione));
                            },
                    ))
              : ListView.separated(
                  itemCount: _listaOdl.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final o = _listaOdl[i];
                    return ListTile(
                      title: Text(o.odl,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${o.padre}  ·  ${o.desPadre}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selezionaOdl(o.odl),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _formEtichetta(StampaVerniciatura e) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                e.etichettaIsLibera ? 'Etichetta libera' : 'ODL ${e.odlSelected}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _etichetta = null),
              child: const Text('Indietro'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _campo('Padre', e.padre, (v) => e.padre = v),
        _campo('Descrizione', e.descrizionePadre, (v) => e.descrizionePadre = v),
        _campo('ODL', e.odlSelected, (v) => e.odlSelected = v),
        if (_fasi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<String>(
              value: e.faseSelected.isNotEmpty ? e.faseSelected : null,
              decoration: const InputDecoration(
                labelText: 'Fase',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _fasi
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => e.faseSelected = v ?? ''),
            ),
          )
        else
          _campo('Fase', e.faseSelected, (v) => e.faseSelected = v),
        _campo('Colore', e.colore, (v) => e.colore = v),
        _campo('Magazzino', e.magazzinoDestinazione,
            (v) => e.magazzinoDestinazione = v),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: _qtaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantità etichette',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Stampa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.casagrandeDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _stampa,
        ),
      ],
    );
  }

  Widget _campo(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
