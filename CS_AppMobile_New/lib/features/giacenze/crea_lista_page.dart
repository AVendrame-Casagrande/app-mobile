import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/storage/local_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/riga_crea_lista.dart';
import '../../state/app_state.dart';
import '../scanner/barcode_scanner_page.dart';
import 'crea_lista_service.dart';

/// Pagina Giacenze → Crea Lista (lista libera inventario CSUSA) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/CreaLista.
/// Aggiunge articoli a una lista locale (persistita), poi la esporta in Excel
/// sul server e la invia via e-mail.
class CreaListaPage extends StatefulWidget {
  const CreaListaPage({super.key});

  @override
  State<CreaListaPage> createState() => _CreaListaPageState();
}

class _CreaListaPageState extends State<CreaListaPage> {
  static const _storageKey = 'listaArticoliDiCreaLista';

  late final CreaListaService _service;
  late final String _societa;
  late final String _utente;

  final _articoloController = TextEditingController();

  bool _busy = false;
  final List<RigaCreaLista> _righe = [];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _service = CreaListaService(app.api);
    _societa = app.utenteLoggato.societaApi;
    _utente = app.utenteLoggato.codiceUtente;
    _caricaDaStorage();
  }

  @override
  void dispose() {
    _articoloController.dispose();
    super.dispose();
  }

  void _caricaDaStorage() {
    final raw = LocalStorage.instance.getJson(_storageKey);
    if (raw is List) {
      _righe.addAll(raw
          .whereType<Map>()
          .map((e) => RigaCreaLista.fromJson(Map<String, dynamic>.from(e))));
    }
  }

  Future<void> _salvaInStorage() async {
    await LocalStorage.instance
        .setJson(_storageKey, _righe.map((r) => r.toJson()).toList());
  }

  // ---------------------------------------------------------------------------
  Future<void> _aggiungi() async {
    final articolo = _articoloController.text.trim().toUpperCase();
    if (articolo.isEmpty) return;
    FocusScope.of(context).unfocus();

    if (_righe.any((r) => r.articolo == articolo)) {
      _alert('Duplicato', 'L\'articolo $articolo è già nella lista.');
      return;
    }

    setState(() => _busy = true);
    try {
      final descrizione = await _service.getDescrizioneArticolo(articolo, _societa);
      if (!mounted) return;
      setState(() => _busy = false);
      if (descrizione == null) {
        _alert('Articolo non trovato', 'L\'articolo $articolo non esiste.');
        return;
      }
      final dati = await _chiediQtaNota();
      if (dati == null || !mounted) return;
      final now = DateTime.now();
      setState(() {
        _righe.add(RigaCreaLista(
          articolo: articolo,
          descrizione: descrizione,
          qta: dati.qta,
          note: dati.note,
          user: _utente,
          data: DateFormat('yyyy-MM-dd').format(now),
          ora: DateFormat('HH:mm:ss').format(now),
        ));
        _articoloController.clear();
      });
      await _salvaInStorage();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore', 'Errore di rete durante la ricerca articolo.');
    }
  }

  Future<void> _scansiona() async {
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra articolo');
    if (code == null || !mounted) return;
    _articoloController.text = code;
    _aggiungi();
  }

  Future<_QtaNota?> _chiediQtaNota() {
    final qtaCtrl = TextEditingController(text: '1');
    final noteCtrl = TextEditingController();
    return showDialog<_QtaNota>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quantità e nota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtaCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantità',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opzionale)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final q = qtaCtrl.text.trim();
              if (q.isEmpty) return;
              Navigator.of(ctx).pop(_QtaNota(q, noteCtrl.text.trim()));
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _elimina(RigaCreaLista r) async {
    setState(() => _righe.remove(r));
    await _salvaInStorage();
  }

  Future<void> _svuota() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Svuota lista'),
        content: const Text('Eliminare tutti gli articoli dalla lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Svuota'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _righe.clear());
      await _salvaInStorage();
    }
  }

  // ---------------------------------------------------------------------------
  Future<void> _salvaEInvia() async {
    if (_righe.isEmpty) return;
    final email = await _chiediEmail();
    if (email == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final filename =
          'Inventory_${DateFormat('yyyyMMdd').format(now)}_${DateFormat('HHmmss').format(now)}_$_utente';
      final saved = await _service.writeExcel(_righe, filename);
      if (!mounted) return;
      if (saved == null) {
        setState(() => _busy = false);
        _alert('Errore', 'Errore durante la creazione del file Excel.');
        return;
      }
      final count = await _service.sendEmail(saved, email);
      if (!mounted) return;
      setState(() => _busy = false);
      if (count > 0) {
        _alert('E-mail inviata', 'Lista inviata con successo a:\n$email');
      } else {
        _alert('Attenzione', 'File creato ma e-mail non inviata.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore', 'Errore di rete durante il salvataggio.');
    }
  }

  Future<String?> _chiediEmail() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invia lista'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail destinatario',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final e = ctrl.text.trim();
              if (_emailValida(e)) Navigator.of(ctx).pop(e);
            },
            child: const Text('Invia'),
          ),
        ],
      ),
    );
  }

  bool _emailValida(String e) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

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
      appBar: AppBar(
        title: const Text('Crea Lista'),
        actions: [
          if (_righe.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Svuota lista',
              onPressed: _svuota,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _addBar(),
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
      bottomNavigationBar: _righe.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.email),
                  label: Text('Salva e invia (${_righe.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.casagrandeDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _salvaEInvia,
                ),
              ),
            ),
    );
  }

  Widget _addBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _articoloController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _aggiungi(),
              decoration: InputDecoration(
                hintText: 'Codice articolo',
                prefixIcon: const Icon(Icons.add),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _busy ? null : _scansiona,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _busy ? null : _aggiungi,
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_righe.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add, size: 48, color: Colors.black38),
            SizedBox(height: 12),
            Text('Aggiungi articoli alla lista'),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _righe.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = _righe[i];
        return Dismissible(
          key: ValueKey('${r.articolo}_$i'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: const Color(0xFFC62828),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _elimina(r),
          child: ListTile(
            title: Text(r.articolo,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text([
              if (r.descrizione.isNotEmpty) r.descrizione.toLowerCase(),
              if (r.note.isNotEmpty) 'Nota: ${r.note}',
            ].join('\n')),
            isThreeLine: r.note.isNotEmpty && r.descrizione.isNotEmpty,
            trailing: Text('Q.tà ${r.qta}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class _QtaNota {
  final String qta;
  final String note;
  _QtaNota(this.qta, this.note);
}
