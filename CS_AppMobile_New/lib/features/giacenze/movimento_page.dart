import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movimento_giacenza.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'movimento_service.dart';

/// Pagina Giacenze → Movimento (Stock Mov, scrittura) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/Movimento.
/// Cerca un articolo, sceglie magazzino origine/destinazione, quantità e
/// invia il movimento all'API Diapason (con conferma via SSE).
class MovimentoPage extends StatefulWidget {
  const MovimentoPage({super.key, this.codiceArticolo});

  /// Se valorizzato, all'apertura cerca subito questo articolo.
  final String? codiceArticolo;

  @override
  State<MovimentoPage> createState() => _MovimentoPageState();
}

class _MovimentoPageState extends State<MovimentoPage> {
  late final MovimentoService _service;
  late final String _societa;
  late final bool _isEnglish;

  final _searchController = TextEditingController();
  final _qtaController = TextEditingController();
  final _aVanoController = TextEditingController();
  final _notaController = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _info;

  ArticoloMovimento? _articolo;
  MagazzinoMovimento? _origine;
  String? _aMagazzino;
  String _odl = '';

  bool _submitting = false;
  StreamSubscription<EsitoMovimento>? _esitoSub;

  static const String _sezione = 'movimento';
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _service = MovimentoService(app.api);
    _isEnglish = app.utenteLoggato.isEnglish;
    _societa = _isEnglish ? 'CSUSA' : 'CSPRO';
    _recenti = LastSearched.get(_sezione);
    final code = widget.codiceArticolo;
    if (code != null && code.trim().isNotEmpty) {
      _searchController.text = code.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) => _cerca());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qtaController.dispose();
    _aVanoController.dispose();
    _notaController.dispose();
    _esitoSub?.cancel();
    _service.closeStream();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Ricerca articolo
  // ---------------------------------------------------------------------------
  Future<void> _cerca() async {
    final code = _searchController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _articolo = null;
      _resetForm();
    });
    try {
      final art = await _service.selectArticoloMagazzini(code, _societa);
      if (!mounted) return;
      if (art != null && art.trovato) {
        await LastSearched.add(_sezione, art.articoloId);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (art == null || !art.trovato) {
          _info = 'Articolo non trovato';
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
    _searchController.text = code;
    _cerca();
  }

  void _resetForm() {
    _origine = null;
    _aMagazzino = null;
    _odl = '';
    _qtaController.clear();
    _aVanoController.clear();
    _notaController.clear();
  }

  // ---------------------------------------------------------------------------
  // Selezione origine / destinazione
  // ---------------------------------------------------------------------------
  void _selezionaOrigine(MagazzinoMovimento m) {
    if (m.giacente <= 0) return;
    setState(() {
      _origine = m;
    });
  }

  void _selezionaDestinazione(String? mag) {
    setState(() {
      _aMagazzino = mag;
      _odl = '';
      // Vano preferenziale auto-compilato
      final art = _articolo;
      if (mag != null && art != null) {
        String vano = '';
        for (final p in art.listaMagazziniPreferenziali) {
          if (p.codice == mag) vano = p.vano;
        }
        _aVanoController.text = vano;
      }
    });
  }

  List<String> get _odlList {
    final art = _articolo;
    if (art == null || _aMagazzino == null) return [];
    return art.listaPossibiliOdl
        .where((o) => o.magazzino == _aMagazzino || o.magazzino.isEmpty)
        .map((o) => o.odl)
        .toList();
  }

  bool get _vanoRichiesto =>
      (_aMagazzino ?? '').toUpperCase().startsWith('MISK');

  bool get _canSend {
    final art = _articolo;
    final origine = _origine;
    if (art == null || origine == null) return false;
    if (_aMagazzino == null || _aMagazzino!.isEmpty) return false;
    final qta = num.tryParse(_qtaController.text.trim()) ?? 0;
    if (qta <= 0 || qta > origine.giacente) return false;
    if (_vanoRichiesto && _aVanoController.text.trim().isEmpty) return false;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Invio movimento
  // ---------------------------------------------------------------------------
  Future<void> _invia() async {
    if (_isEnglish) {
      _alert('Non disponibile',
          "Non puoi eseguire un movimento in questa versione (utente EN).");
      return;
    }
    final art = _articolo;
    final origine = _origine;
    if (art == null || origine == null || !_canSend) return;

    final utente = context.read<AppState>().utenteLoggato.codiceUtente;

    final conferma = await _confermaDialog(art, origine);
    if (conferma != true) return;

    final now = DateTime.now();
    final idApi =
        '${DateFormat('yyyy_MM_dd_HH_mm_ss_SSS').format(now)}_$utente';
    final nomeLista = 'mov_singolo_${DateFormat('HH_mm_ss').format(now)}';

    final movimento = MovimentoApi(
      idApi: idApi,
      societa: _societa,
      utente: utente,
      articolo: art.articoloId,
      qta: num.tryParse(_qtaController.text.trim()) ?? 0,
      damag: origine.codice,
      davano: origine.vano,
      amag: _aMagazzino ?? '',
      avano: _aVanoController.text.trim(),
      odl: _odl,
      nota: _notaController.text.trim(),
    );

    setState(() => _submitting = true);

    try {
      // Avvio lo stream PRIMA di inviare per non perdere eventi.
      _esitoSub?.cancel();
      _esitoSub = _service.streamEsito(idApi).listen((esito) {
        if (esito.id != idApi) return;
        if (esito.completato) {
          _esitoSub?.cancel();
          _service.closeStream();
          if (!mounted) return;
          setState(() => _submitting = false);
          _mostraEsito(esito);
        }
      }, onError: (_) {});

      await _service.writeMovimentiMultipli(
        [movimento],
        idApi: idApi,
        nomeLista: nomeLista,
        utente: utente,
        sezione: 'mov_singolo',
      );

      // Timeout di sicurezza se l'SSE non risponde.
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _submitting) {
          _esitoSub?.cancel();
          _service.closeStream();
          setState(() => _submitting = false);
          _alert('Movimento inviato',
              'Movimento inviato. Conferma non ricevuta in tempo: verifica in Cerca.');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _alert('Errore', 'Invio movimento non riuscito: errore di rete.');
    }
  }

  void _mostraEsito(EsitoMovimento esito) {
    final ok = esito.isSuccess;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.error,
                color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
            const SizedBox(width: 8),
            Text(ok ? 'Successo' : 'Errore'),
          ],
        ),
        content: Text(esito.response.isEmpty ? 'Movimento completato' : esito.response),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Reset per un nuovo movimento sullo stesso articolo.
              setState(() {
                _resetForm();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confermaDialog(
      ArticoloMovimento art, MagazzinoMovimento origine) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma movimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Articolo: ${art.articoloId}'),
            Text('Da: ${origine.codice}${origine.vano.isNotEmpty ? ' / ${origine.vano}' : ''}'),
            Text('A: ${_aMagazzino ?? ''}${_aVanoController.text.trim().isNotEmpty ? ' / ${_aVanoController.text.trim()}' : ''}'),
            Text('Q.tà: ${_qtaController.text.trim()} ${art.unitaMisura}'),
            if (_odl.isNotEmpty) Text('ODL: $_odl'),
            if (_notaController.text.trim().isNotEmpty)
              const Text('Nota: presente'),
          ],
        ),
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
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimento')),
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_submitting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.spinner),
                        SizedBox(height: 16),
                        Text('Invio movimento in corso…'),
                      ],
                    ),
                  ),
                ),
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
              controller: _searchController,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.characters,
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
    final art = _articolo;
    if (art == null) {
      if (_info != null) {
        return _centerMsg(Icons.swap_horiz, _info!);
      }
      return LastSearchedList(
        items: _recenti,
        onTap: (codice) {
          _searchController.text = codice;
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
    if (_origine == null) {
      return _listaOrigini(art);
    }
    return _form(art);
  }

  Widget _listaOrigini(ArticoloMovimento art) {
    return Column(
      children: [
        _articoloHeader(art),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Seleziona magazzino di ORIGINE',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: art.listaMagazziniArticolo.isEmpty
              ? _centerMsg(Icons.inbox, 'Nessun magazzino con giacenza')
              : ListView.separated(
                  itemCount: art.listaMagazziniArticolo.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = art.listaMagazziniArticolo[i];
                    final disabled = m.giacente <= 0;
                    return ListTile(
                      enabled: !disabled,
                      leading: Icon(Icons.warehouse,
                          color: disabled ? Colors.black26 : const Color(0xFF5966A8)),
                      title: Text(m.codice,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(m.vano.isNotEmpty ? 'Vano ${m.vano}' : '—'),
                      trailing: Text('Giac: ${_n(m.giacente)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: disabled
                                  ? Colors.black38
                                  : const Color(0xFF2E7D32))),
                      onTap: disabled ? null : () => _selezionaOrigine(m),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _articoloHeader(ArticoloMovimento art) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(art.articoloId,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (art.descrizioneArticolo.isNotEmpty)
            Text(art.descrizioneArticolo.toLowerCase(),
                style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _form(ArticoloMovimento art) {
    final origine = _origine!;
    final odlList = _odlList;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(child: _articoloHeader(art)),
            TextButton(
              onPressed: () => setState(() => _origine = null),
              child: const Text('Cambia origine'),
            ),
          ],
        ),
        Card(
          color: const Color(0xFFE8F5E9),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.logout, color: Color(0xFF2E7D32)),
            title: Text('Origine: ${origine.codice}'
                '${origine.vano.isNotEmpty ? ' / ${origine.vano}' : ''}'),
            subtitle: Text('Giacenza residua: ${_n(origine.giacente)} ${art.unitaMisura}'),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _aMagazzino,
          decoration: const InputDecoration(
            labelText: 'Magazzino destinazione',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: art.listaPossibiliMagazzini
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => _selezionaDestinazione(v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _aVanoController,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: _vanoRichiesto ? 'Vano destinazione (richiesto)' : 'Vano destinazione (opz.)',
            border: const OutlineInputBorder(),
            isDense: true,
            errorText: _vanoRichiesto && _aVanoController.text.trim().isEmpty
                ? 'Vano richiesto per magazzini MISK'
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (odlList.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _odl.isEmpty ? null : _odl,
            decoration: const InputDecoration(
              labelText: 'ODL (opzionale)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('—')),
              ...odlList.map((o) => DropdownMenuItem(value: o, child: Text(o))),
            ],
            onChanged: (v) => setState(() => _odl = v ?? ''),
          ),
        if (odlList.isNotEmpty) const SizedBox(height: 12),
        TextField(
          controller: _qtaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Quantità da spostare',
            helperText: 'Max ${_n(origine.giacente)} ${art.unitaMisura}',
            border: const OutlineInputBorder(),
            isDense: true,
            errorText: _qtaError(origine),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notaController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Nota (opzionale)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text('Invia movimento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.casagrandeDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _canSend ? _invia : null,
        ),
        if (_isEnglish)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Movimenti non disponibili per utenti EN in questa versione.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String? _qtaError(MagazzinoMovimento origine) {
    final t = _qtaController.text.trim();
    if (t.isEmpty) return null;
    final q = num.tryParse(t);
    if (q == null) return 'Quantità non valida';
    if (q <= 0) return 'Deve essere maggiore di 0';
    if (q > origine.giacente) return 'Supera la giacenza';
    return null;
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
