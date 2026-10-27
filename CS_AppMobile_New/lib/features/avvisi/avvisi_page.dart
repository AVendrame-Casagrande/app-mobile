import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/avviso.dart';
import '../../state/app_state.dart';
import 'avvisi_service.dart';

/// Pagina Attività/Avvisi — porting di www/scripts/Avvisi.
class AvvisiPage extends StatefulWidget {
  const AvvisiPage({super.key});

  @override
  State<AvvisiPage> createState() => _AvvisiPageState();
}

class _AvvisiPageState extends State<AvvisiPage> {
  late final AvvisiService _service;
  late final AppState _app;

  bool _loading = true;
  String? _error;
  List<Avviso> _validi = [];
  bool _soloMie = false;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _service = AvvisiService(_app.api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tutti = await _service.getAllAvvisi(_app.utenteLoggato.nomePortale);
      if (!mounted) return;
      setState(() {
        _validi = _service.filtraValidiOggi(tutti);
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

  List<Avviso> get _visibili {
    if (!_soloMie) return _validi;
    final me = _app.utenteLoggato.codiceUtente;
    return _validi.where((a) => a.dest == me).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mie = _service.contaPerDestinatario(
        _validi, _app.utenteLoggato.codiceUtente);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: _tabButton('Tutte (${_validi.length})', !_soloMie,
                    () => setState(() => _soloMie = false)),
              ),
              Expanded(
                child: _tabButton('Mie ($mie)', _soloMie,
                    () => setState(() => _soloMie = true)),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spinner));
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
            ElevatedButton(onPressed: _load, child: const Text('Riprova')),
          ],
        ),
      );
    }
    final items = _visibili;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Nessuna attività da visualizzare')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _avvisoCard(items[i]),
      ),
    );
  }

  Widget _avvisoCard(Avviso a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (a.isUrgente)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.priority_high, color: Colors.red, size: 20),
                  ),
                Expanded(
                  child: Text(
                    a.avviso,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _meta(Icons.person, a.dest.isEmpty ? a.utente : a.dest),
                _meta(Icons.schedule, a.timest),
                if (a.scadenza.isNotEmpty) _meta(Icons.event, 'Scad. ${a.scadenza}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Elimina', style: TextStyle(color: Colors.red)),
                  onPressed: () => _onElimina(a),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Completa'),
                  onPressed: () => _onCompleta(a),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      );

  Future<void> _onCompleta(Avviso a) async {
    final ok = await _service.completaAvviso(a);
    if (!mounted) return;
    _snack(ok ? "L'Attività è stata Completata" : "Errore: impossibile completare l'Attività");
    if (ok) _load();
  }

  Future<void> _onElimina(Avviso a) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina Attività'),
        content: const Text('Vuoi eliminare questa attività?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (conferma != true) return;
    final ok = await _service.eliminaAvviso(a);
    if (!mounted) return;
    _snack(ok ? 'Attività eliminata' : 'Errore: impossibile eliminare');
    if (ok) _load();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
