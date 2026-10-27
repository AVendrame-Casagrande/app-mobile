import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cambio_odl.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'cambio_odl_service.dart';

/// Pagina Giacenze → Cambio ODL (scrittura) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/CambioOdl.
/// Cerca un ODL (o padre/magazzino), seleziona le righe, sceglie nuovo ODL
/// e fase, ed esegue il cambio con doppio movimento (storno + carico).
class CambioOdlPage extends StatefulWidget {
  const CambioOdlPage({super.key});

  @override
  State<CambioOdlPage> createState() => _CambioOdlPageState();
}

class _CambioOdlPageState extends State<CambioOdlPage> {
  late final CambioOdlService _service;
  late final String _societa;

  final _searchController = TextEditingController();
  final _odlManualeController = TextEditingController();

  bool _loading = false;
  bool _busy = false;
  String? _error;
  String? _info;

  CambioOdlResult? _result;
  String _oldOdl = '';

  String _newOdl = '';
  List<FasePossibile> _fasi = [];
  String _newFase = '';
  String _magDes = '';
  String _vanoDes = '';

  static const String _sezione = 'cambio odl';
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _service = CambioOdlService(app.api);
    _societa = app.utenteLoggato.isEnglish ? 'CSUSA' : 'CSPRO';
    _recenti = LastSearched.get(_sezione);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _odlManualeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  Future<void> _cerca([String? codiceParam]) async {
    final codice = (codiceParam ?? _searchController.text).trim();
    if (codice.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _result = null;
      _resetNuovoOdl();
    });
    try {
      final res = await _service.selectCambioOdl(codice);
      if (!mounted) return;
      // Ricerca per padre/magazzino con 1 solo risultato → ricerca per ODL.
      if (!res.isOdl && res.listaBase.length == 1) {
        await _cerca(res.listaBase.first.odl);
        return;
      }
      if (res.isOdl && !res.vuoto) {
        await LastSearched.add(_sezione, res.righe.first.odl);
        if (!mounted) return;
      }
      setState(() {
        _loading = false;
        if (res.vuoto) {
          _info = 'Nessun risultato per "$codice"';
        } else {
          _result = res;
          if (res.isOdl) _oldOdl = res.righe.first.odl;
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
    final code = await BarcodeScannerPage.scan(context, titolo: 'Inquadra ODL / Padre');
    if (code == null || !mounted) return;
    _searchController.text = code;
    _cerca();
  }

  void _resetNuovoOdl() {
    _newOdl = '';
    _fasi = [];
    _newFase = '';
    _magDes = '';
    _vanoDes = '';
    _odlManualeController.clear();
  }

  // ---------------------------------------------------------------------------
  Future<void> _validaNuovoOdl(String odl) async {
    final o = odl.trim().toUpperCase();
    if (o.isEmpty) {
      setState(_resetNuovoOdl);
      return;
    }
    setState(() => _busy = true);
    try {
      final fasi = await _service.validateOdlSelectFasi(o);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (fasi.isEmpty) {
          _alert('ODL non valido', 'Nessuna fase trovata per l\'ODL $o');
          _resetNuovoOdl();
        } else {
          _newOdl = o;
          _fasi = fasi;
          _selezionaFase(fasi.first.fase);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _alert('Errore', 'Impossibile validare l\'ODL');
    }
  }

  void _selezionaFase(String fase) {
    for (final f in _fasi) {
      if (f.fase == fase) {
        _newFase = f.fase;
        _magDes = f.magDes;
        _vanoDes = f.vanoDes;
        break;
      }
    }
  }

  List<CambioOdlRiga> get _selezionate =>
      _result?.righe.where((r) => r.selezionato).toList() ?? [];

  bool get _canInvia =>
      _selezionate.isNotEmpty && _newOdl.isNotEmpty && _newFase.isNotEmpty;

  // ---------------------------------------------------------------------------
  Future<void> _invia() async {
    final righe = _selezionate;
    if (righe.isEmpty || !_canInvia) return;

    final utente = context.read<AppState>().utenteLoggato.codiceUtente;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma Cambio ODL'),
        content: Text(
            'Cambiare ${righe.length} riga/e dall\'ODL $_oldOdl al nuovo ODL '
            '$_newOdl (fase $_newFase)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cambia'),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    setState(() => _busy = true);

    final riepilogo = StringBuffer();
    var completati = 0;
    var errore = false;

    for (final r in righe) {
      // MOV 1 (storno) → MIRC001
      final mov1 = await _service.inviaMovimento(
        articolo: r.articolo,
        damag: r.queryMagDes,
        davano: r.queryVanoDes,
        amag: 'MIRC001',
        avano: '',
        qta: r.qtatrasftot,
        odl: _oldOdl,
        utente: utente,
        societa: _societa,
      );
      if (!mov1.isSuccess) {
        riepilogo.writeln('❌ ${r.articolo}: storno fallito → ${mov1.response.trim()}');
        errore = true;
        break;
      }
      // MOV 2 (cambio) → mag destinazione nuova fase
      final mov2 = await _service.inviaMovimento(
        articolo: r.articolo,
        damag: 'MIRC001',
        davano: '',
        amag: _magDes,
        avano: _vanoDes,
        qta: r.qtatrasftot,
        odl: _newOdl,
        utente: utente,
        societa: _societa,
      );
      if (!mov2.isSuccess) {
        riepilogo.writeln('❌ ${r.articolo}: cambio fallito → ${mov2.response.trim()}');
        errore = true;
        break;
      }
      completati++;
      riepilogo.writeln('✔️ ${r.articolo} (${_n(r.qtatrasftot)})');
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!errore) {
        // Rimuovo le righe cambiate.
        _result?.righe.removeWhere((r) => righe.contains(r));
        _resetNuovoOdl();
      }
    });
    _alert(
      errore ? 'Cambio interrotto' : 'Cambio completato',
      '${errore ? 'Completati $completati di ${righe.length}.\n\n' : 'Cambiate $completati righe.\n\n'}$riepilogo',
    );
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

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambio ODL')),
      body: Stack(
        children: [
          Column(
            children: [
              _searchBar(),
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
              controller: _searchController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _cerca(),
              decoration: InputDecoration(
                hintText: 'ODL / Padre / Magazzino',
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
            onPressed: _loading ? null : () => _cerca(),
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
      return _centerMsg(Icons.cloud_off, _error!, retry: () => _cerca());
    }
    final res = _result;
    if (res == null) {
      if (_info != null) {
        return _centerMsg(Icons.sync_alt, _info!);
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
    if (!res.isOdl) {
      return _listaScelta(res.listaBase);
    }
    return _formCambio(res);
  }

  Widget _listaScelta(List<CambioOdlBase> lista) {
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final b = lista[i];
        return ListTile(
          title: Text(b.odl, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${b.padre}  ·  ${b.desPadre}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _cerca(b.odl),
        );
      },
    );
  }

  Widget _formCambio(CambioOdlResult res) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('ODL attuale: $_oldOdl',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...res.righe.map(_rigaTile),
        const Divider(height: 24),
        _selettoreNuovoOdl(res),
        if (_fasi.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _newFase.isEmpty ? null : _newFase,
            decoration: const InputDecoration(
              labelText: 'Nuova fase',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _fasi
                .map((f) => DropdownMenuItem(
                    value: f.fase,
                    child: Text('${f.fase}  →  ${f.magDes}'
                        '${f.vanoDes.isNotEmpty ? ' / ${f.vanoDes}' : ''}')))
                .toList(),
            onChanged: (v) => setState(() => _selezionaFase(v ?? '')),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: Text('Cambia ${_selezionate.length} riga/e'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.casagrandeDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _canInvia ? _invia : null,
        ),
      ],
    );
  }

  Widget _rigaTile(CambioOdlRiga r) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: CheckboxListTile(
        value: r.selezionato,
        onChanged: (v) => setState(() => r.selezionato = v ?? false),
        title: Text('${r.articolo}  ·  fase ${r.fase}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text([
          if (r.descArticolo.isNotEmpty) r.descArticolo.toLowerCase(),
          'Q.tà ${_n(r.qtatrasftot)}'
              '${r.magDes.isNotEmpty ? '  ·  ${r.magDes}${r.vanoDes.isNotEmpty ? '/${r.vanoDes}' : ''}' : ''}',
        ].join('\n')),
        isThreeLine: r.descArticolo.isNotEmpty,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }

  Widget _selettoreNuovoOdl(CambioOdlResult res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nuovo ODL', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (res.listaPossibiliOdl.isNotEmpty)
          DropdownButtonFormField<String>(
            value: res.listaPossibiliOdl.contains(_newOdl) ? _newOdl : null,
            decoration: const InputDecoration(
              labelText: 'Scegli da lista',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: res.listaPossibiliOdl
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: _busy ? null : (v) {
              if (v != null) _validaNuovoOdl(v);
            },
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _odlManualeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'oppure digita ODL',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _validaNuovoOdl(_odlManualeController.text),
              child: const Text('Valida'),
            ),
          ],
        ),
        if (_newOdl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Nuovo ODL: $_newOdl',
                style: const TextStyle(
                    color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
      ],
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
