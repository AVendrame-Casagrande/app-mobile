import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/situazione_odv.dart';
import '../../state/app_state.dart';
import 'situazione_odv_service.dart';

/// Pagina Situazione ODV — porting di www/scripts/SituazioneOdv.
/// L'utente sceglie il tipo ordine (OR/OM), poi vede la lista filtrabile
/// per stato materiale e per numero ordine, con righe espandibili.
class SituazioneOdvPage extends StatefulWidget {
  const SituazioneOdvPage({super.key});

  @override
  State<SituazioneOdvPage> createState() => _SituazioneOdvPageState();
}

class _SituazioneOdvPageState extends State<SituazioneOdvPage> {
  late final SituazioneOdvService _service;

  bool _loading = false;
  String? _error;
  String _tipoOrdine = ''; // 'OR' o 'OM'
  List<OdvLista> _liste = [];

  // Filtri
  String _filtroStato = 'Tutti';
  String _filtroTarget = 'Tutti';

  static const Map<String, String> _statoLabels = {
    'Tutti': 'Tutti',
    'disp_tutti': 'Disponibili (Tutti)',
    'disp_reparto': 'Disponibili (MISP002)',
    'disp_prel': 'Disponibili (Da Prelevare)',
    'odl': 'In Ordine di Lavoro',
    'oda': 'In Ordine di Acquisto',
    'mancanti': 'Mancanti',
  };

  @override
  void initState() {
    super.initState();
    _service = SituazioneOdvService(context.read<AppState>().api);
  }

  Future<void> _scegliTipoOrdine() async {
    final scelta = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Seleziona il tipo di Ordine'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'OR'),
            child: const Text('OR — Ordine di Riferimento'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'OM'),
            child: const Text('OM — Ordine di Magazzino'),
          ),
        ],
      ),
    );
    if (scelta != null) _load(scelta);
  }

  Future<void> _load(String orOm) async {
    setState(() {
      _loading = true;
      _error = null;
      _tipoOrdine = orOm;
      _filtroTarget = 'Tutti';
    });
    try {
      final liste = await _service.getSituazioneOdv(orOm);
      if (!mounted) return;
      setState(() {
        _liste = liste;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore di Rete o del Server';
        _loading = false;
      });
    }
  }

  /// Righe visibili di una lista in base al filtro stato.
  List<OdvRiga> _righeVisibili(OdvLista lista) =>
      lista.righe.where((r) => r.matchFiltro(_filtroStato)).toList();

  /// Liste effettivamente mostrate (hanno righe visibili + match target).
  List<OdvLista> get _listeVisibili {
    return _liste.where((l) {
      if (_righeVisibili(l).isEmpty) return false;
      if (_filtroTarget != 'Tutti' && l.numero != _filtroTarget) return false;
      return true;
    }).toList();
  }

  /// Numeri ordine disponibili per il filtro target (solo liste con righe visibili).
  List<String> get _targets {
    final s = _liste
        .where((l) => _righeVisibili(l).isNotEmpty)
        .map((l) => l.numero)
        .toSet()
        .toList();
    s.sort();
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final visibili = _listeVisibili;
    final totRighe =
        visibili.fold<int>(0, (sum, l) => sum + _righeVisibili(l).length);

    return Scaffold(
      appBar: AppBar(
        title: Text(_tipoOrdine.isEmpty
            ? 'Situazione ODV'
            : 'Situazione ODV — $_tipoOrdine'),
        actions: [
          if (_tipoOrdine.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : () => _load(_tipoOrdine),
            ),
        ],
      ),
      body: _buildBody(visibili, totRighe),
      bottomNavigationBar:
          _tipoOrdine.isEmpty || _loading ? null : _buildFilterBar(),
    );
  }

  Widget _buildBody(List<OdvLista> visibili, int totRighe) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_tipoOrdine.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.list_alt, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            const Text('Scegli il tipo di ordine da visualizzare'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.touch_app),
              label: const Text('Seleziona Ordine'),
              onPressed: _scegliTipoOrdine,
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => _load(_tipoOrdine),
                child: const Text('Riprova')),
          ],
        ),
      );
    }
    if (visibili.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(_tipoOrdine),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Nessuna lista ODV da visualizzare')),
          ],
        ),
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            '$_tipoOrdine: ${visibili.length}  |  Righe: $totRighe',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(_tipoOrdine),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: visibili.length,
              itemBuilder: (_, i) => _listaCard(visibili[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _listaCard(OdvLista lista) {
    final righe = _righeVisibili(lista);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        backgroundColor:
            lista.haProblemi ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
        collapsedBackgroundColor:
            lista.haProblemi ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
        title: Text(lista.numero,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Causale: ${lista.causale}  |  ${lista.dataConsegnaFmt}'
          '${lista.nomecliente.isNotEmpty ? '\n${lista.nomecliente.toLowerCase()}' : ''}',
        ),
        trailing: CircleAvatar(
          radius: 14,
          backgroundColor:
              lista.haProblemi ? Colors.orange : Colors.green,
          child: Text('${righe.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        children: righe.map((r) => _rigaTile(r)).toList(),
      ),
    );
  }

  Widget _rigaTile(OdvRiga riga) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${riga.articolo}  |  Pos ${riga.pos}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (riga.descarticolo.isNotEmpty)
            Text(
              riga.descarticolo.toLowerCase(),
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: riga.statoOdv.map((s) => _statoChip(riga, s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statoChip(OdvRiga riga, StatoOdv stato) {
    late final Color color;
    late final String label;
    switch (stato) {
      case StatoOdv.disponibile:
        color = const Color(0xFF2E7D32);
        label = 'Disponibile (${riga.magazzino})  '
            'Giac ${riga.giacmag} · Imp ${riga.qtaape}';
        break;
      case StatoOdv.disponibilePrel:
        color = const Color(0xFF6A1B9A);
        label = 'Disponibile (${riga.magdispo})  '
            'Giac ${riga.giacdispo} · Imp ${riga.qtaape}';
        break;
      case StatoOdv.inOda:
        color = const Color(0xFFEF6C00);
        label = 'ODA ${riga.numsoda} · ${riga.dataConsegnaOda}  '
            'In Oda ${riga.qtaisoda} · Fabb ${riga.qtafab} · Imp ${riga.qtaape}';
        break;
      case StatoOdv.inOdl:
        color = const Color(0xFF3949AB);
        label = 'ODL ${riga.numodl} · ${riga.dataConsegnaOdl}  '
            'In Odl ${riga.qtaiodl} · Fabb ${riga.qtafab} · Imp ${riga.qtaape}';
        break;
      case StatoOdv.mancante:
        color = const Color(0xFFC62828);
        label = 'Mancante ${riga.qtaMancante} · Imp ${riga.qtaape}';
        break;
      case StatoOdv.sconosciuto:
        color = Colors.black45;
        label = 'Sconosciuto';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, height: 1.3)),
    );
  }

  Widget _buildFilterBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _dropdown<String>(
                label: 'Stato',
                value: _filtroStato,
                items: _statoLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _filtroStato = v ?? 'Tutti';
                  _filtroTarget = 'Tutti'; // reset come nell'originale
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdown<String>(
                label: 'Numero',
                value: _targets.contains(_filtroTarget) ? _filtroTarget : 'Tutti',
                items: [
                  const DropdownMenuItem(value: 'Tutti', child: Text('TUTTI')),
                  ..._targets.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t))),
                ],
                onChanged: (v) =>
                    setState(() => _filtroTarget = v ?? 'Tutti'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
