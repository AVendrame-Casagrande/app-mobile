import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/foto_arm.dart';
import '../../state/app_state.dart';
import '../media/photo_picker.dart';
import 'foto_arm_service.dart';

/// Pagina Foto ARM (read-only) — porting di www/scripts/FotoArm.
/// Elenco degli ARM con ricerca. Il caricamento foto da camera/galleria
/// richiede i plugin nativi e sarà aggiunto in una fase successiva.
class FotoArmPage extends StatefulWidget {
  const FotoArmPage({super.key});

  @override
  State<FotoArmPage> createState() => _FotoArmPageState();
}

class _FotoArmPageState extends State<FotoArmPage> {
  late final FotoArmService _service;

  bool _loading = false;
  String? _error;
  List<FotoArm> _tutti = [];
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _service = FotoArmService(context.read<AppState>().api);
    _carica();
  }

  Future<void> _carica() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await _service.getListaArm();
      if (!mounted) return;
      setState(() {
        _tutti = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'ARM Offline o errore di rete';
        _loading = false;
      });
    }
  }

  List<FotoArm> get _filtrati {
    final q = _filtro.trim().toLowerCase();
    if (q.isEmpty) return _tutti;
    return _tutti
        .where((a) =>
            a.numero.toLowerCase().contains(q) ||
            a.cliente.toLowerCase().contains(q))
        .toList();
  }

  void _apri(FotoArm a) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(a.numero),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.causale.isNotEmpty) Text('Causale: ${a.causale}'),
            if (a.cliente.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Cliente: ${a.cliente}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Chiudi'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_camera),
            label: const Text('Carica foto'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _caricaFoto(a);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _caricaFoto(FotoArm a) async {
    final bytes = await PhotoPicker.pick(context);
    if (bytes == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Caricamento foto ARM ${a.numero}…')),
    );
    try {
      final ok = await _service.uploadFoto(a.numero, bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'ARM ${a.numero} caricato con successo!'
              : 'Errore: foto non caricata'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore di rete durante il caricamento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto ARM')),
      body: Column(
        children: [
          if (_tutti.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _filtro = v),
                decoration: const InputDecoration(
                  hintText: 'Filtra per numero o cliente',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          Expanded(child: _buildBody()),
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
      return _centerMessage(Icons.cloud_off, _error!, retry: _carica);
    }
    final lista = _filtrati;
    if (lista.isEmpty) {
      return _centerMessage(Icons.photo_camera_back_outlined,
          _tutti.isEmpty ? 'Nessun ARM disponibile' : 'Nessun risultato');
    }
    return RefreshIndicator(
      onRefresh: _carica,
      child: ListView.separated(
        itemCount: lista.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final a = lista[i];
          return ListTile(
            title: Text(a.numero,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text([
              if (a.causale.isNotEmpty) a.causale.toLowerCase(),
              if (a.cliente.isNotEmpty) a.cliente.toLowerCase(),
            ].join('\n')),
            isThreeLine: a.causale.isNotEmpty && a.cliente.isNotEmpty,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _apri(a),
          );
        },
      ),
    );
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
}
