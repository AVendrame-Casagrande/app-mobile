import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../giacenze/inventario_dialogs.dart';
import '../media/photo_picker.dart';
import 'qualita_service.dart';

/// Pagina Produzione → Qualità — porting di
/// www/scripts/Produzione-Odl/Pagine/Qualita.
///
/// - Ricondizionati: codici R da controllare; con foto e bolla si confermano
///   (verdi, nascosti di default) e la conferma si può annullare.
/// - Arrivi: ricerca degli arrivi per articolo, fornitore e data.
class QualitaPage extends StatefulWidget {
  const QualitaPage({super.key});

  @override
  State<QualitaPage> createState() => _QualitaPageState();
}

class _QualitaPageState extends State<QualitaPage> {
  late final QualitaService _service;
  late final AppState _app;

  bool _loading = false;
  String? _error;
  List<RigaQualita> _lista = [];
  bool _mostraConfermati = false;
  final Set<RigaQualita> _busy = Set.identity();

  // Arrivi
  final _artController = TextEditingController();
  final _fornController = TextEditingController();
  DateTime? _dataArrivo = DateTime.now();
  bool _loadingArrivi = false;
  List<ArrivoQualita>? _arrivi;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _service = QualitaService(_app.api);
    _carica();
  }

  @override
  void dispose() {
    _artController.dispose();
    _fornController.dispose();
    super.dispose();
  }

  Future<void> _carica() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final l = await _service.getRicondizionati();
      if (!mounted) return;
      setState(() {
        _lista = l;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Errore di Rete o del Server: impossibile scaricare la Lista della Qualità';
      });
    }
  }

  List<RigaQualita> get _visibili =>
      _mostraConfermati ? _lista : _lista.where((q) => !q.confermato).toList();

  // ---------------------------------------------------------------------------
  // Ricondizionati
  // ---------------------------------------------------------------------------

  Future<void> _azione(RigaQualita q) async {
    if (!q.confermato) {
      if (q.urlFoto.isEmpty) {
        await invAlert(context, 'Foto Richiesta',
            'Per confermare un codice R è richiesto il caricamento di 1 Foto');
        return;
      }
      if (q.bolla.isEmpty) {
        await invAlert(context, 'Bolla Inesistente', 'Non puoi confermare un codice R senza Bolla');
        return;
      }
      await _confermaOAnnulla(q, 'confirm');
      return;
    }
    final s = await invChoice(context, 'Elimina Conferma',
        "Vuoi eliminare la Conferma dell'articolo ${q.articolo}?", ['Elimina', 'Chiudi']);
    if (s == 0 && mounted) await _confermaOAnnulla(q, 'delete');
  }

  Future<void> _confermaOAnnulla(RigaQualita q, String action) async {
    setState(() => _busy.add(q));
    try {
      final id = await _service.confermaOAnnulla(q, _app.utenteLoggato.codiceUtente, action);
      if (!mounted) return;
      setState(() {
        _busy.remove(q);
        if (action == 'confirm') {
          q.confermato = true;
          q.id = id;
        } else {
          q.confermato = false;
          q.id = '0';
        }
      });
      invToast(context,
          action == 'confirm' ? 'Codice ${q.articolo} confermato' : 'Conferma ${q.articolo} cancellata');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy.remove(q));
      await invAlert(context, 'Errore di Rete',
          'Errore di Rete o del Server: Impossibile ${action == 'confirm' ? 'confermare' : 'cancellare'} il codice ${q.articolo}');
    }
  }

  Future<void> _foto(RigaQualita q) async {
    var modifica = false;
    if (q.urlFoto.isNotEmpty) {
      final s = await invChoice(
        context,
        'Foto ${q.articolo}',
        "La Foto dell' Articolo ${q.articolo} è già stata scattata.\n\nCosa vuoi fare?",
        ['Visualizza', 'Aggiungi Foto'],
      );
      if (!mounted || s == null) return;
      if (s == 0) {
        await launchUrl(Uri.parse(QualitaService.urlFoto(q.urlFoto)),
            mode: LaunchMode.externalApplication);
        return;
      }
      modifica = true;
    }
    final bytes = await PhotoPicker.pick(context);
    if (bytes == null || !mounted) return;
    setState(() => _busy.add(q));
    bool ok;
    try {
      ok = await _service.uploadFoto(q, bytes);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _busy.remove(q);
      if (ok) q.urlFoto = q.nomeFoto;
    });
    if (ok) {
      invToast(context, 'Foto di ${q.articolo} ${modifica ? 'modificata' : 'caricata'} con successo');
    } else {
      await invAlert(context, 'Errore di Rete', 'Foto di ${q.articolo} non caricata. Riprova');
    }
  }

  void _info(RigaQualita q) {
    invAlert(
      context,
      q.articolo,
      'Articolo: ${q.articolo} ( ${q.um} ) ( ${q.descrizione.toLowerCase()} )\n\n'
          'Fornitore: ${q.fornitore}\nMagazzino: ${q.magazzino}'
          '${q.vano.isNotEmpty ? ' ( ${q.vano} )' : ''}\n\n'
          'Trattamento: ${q.trattamento}\nColore: ${q.colore.toLowerCase()}',
    );
  }

  // ---------------------------------------------------------------------------
  // Arrivi
  // ---------------------------------------------------------------------------

  Future<void> _cercaArrivi() async {
    if (_artController.text.isEmpty && _fornController.text.isEmpty && _dataArrivo == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loadingArrivi = true);
    try {
      final l = await _service.getArrivi(
        societa: _app.utenteLoggato.isEnglish ? 'CSUSA' : 'CSPRO',
        articolo: _artController.text.trim().toUpperCase(),
        ragioneSociale: _fornController.text.trim().toUpperCase(),
        data: _dataArrivo == null ? '' : DateFormat('yyyyMMdd').format(_dataArrivo!),
      );
      if (!mounted) return;
      setState(() {
        _arrivi = l;
        _loadingArrivi = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingArrivi = false);
      await invAlert(context, 'Errore di Rete', 'Errore di Rete o del Server: impossibile scaricare gli Arrivi');
    }
  }

  Future<void> _scegliData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataArrivo ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _dataArrivo = d);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Qualità'),
          bottom: const TabBar(tabs: [Tab(text: 'RICONDIZIONATI'), Tab(text: 'ARRIVI')]),
        ),
        body: TabBarView(children: [_tabRicondizionati(), _tabArrivi()]),
      ),
    );
  }

  Widget _tabRicondizionati() {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _carica, child: const Text('Riprova')),
          ],
        ),
      );
    }
    final lista = _visibili;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Codici R ( ${lista.length} )',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: _mostraConfermati ? 'Nascondi confermati' : 'Mostra confermati',
                icon: Icon(_mostraConfermati ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() => _mostraConfermati = !_mostraConfermati);
                  invToast(context,
                      'Articoli R (confermati) ${_mostraConfermati ? 'visualizzati' : 'nascosti'}');
                },
              ),
              IconButton(tooltip: 'Aggiorna', icon: const Icon(Icons.refresh), onPressed: _carica),
            ],
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? const Center(child: Text('Lista codici R vuota'))
              : RefreshIndicator(
                  onRefresh: _carica,
                  child: ListView.separated(
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _rigaRicondizionato(lista[i], i),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _rigaRicondizionato(RigaQualita q, int i) {
    final busy = _busy.contains(q);
    final descr = q.descrizione.toLowerCase();
    final forn = q.fornitore.toLowerCase();
    final bg = q.confermato
        ? const Color(0xFFDFF5D8)
        : (i.isEven ? Colors.white : const Color(0xFFF2F2F2));
    return InkWell(
      onTap: () => _info(q),
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.articolo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(descr.length > 40 ? descr.substring(0, 40) : descr,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.bolla, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(q.ordine.isEmpty ? 'N.D.' : q.ordine, style: const TextStyle(fontSize: 12)),
                  Text(forn.isEmpty ? 'N.D.' : (forn.length > 15 ? forn.substring(0, 15) : forn),
                      style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Column(
                children: [
                  Text('${q.tipoMovimento}/${q.movimento}', style: const TextStyle(fontSize: 12)),
                  Text(q.qtaMovimento, style: const TextStyle(fontSize: 12)),
                  Text(q.qtaGiacenza, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Foto',
                    icon: Icon(q.urlFoto.isEmpty ? Icons.photo_camera : Icons.photo_library,
                        color: const Color(0xFF5966A8)),
                    onPressed: () => _foto(q),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: q.confermato ? 'Elimina conferma' : 'Conferma',
                    icon: Icon(q.confermato ? Icons.delete : Icons.check_circle,
                        color: q.confermato ? Colors.redAccent : const Color(0xFF2E7D32)),
                    onPressed: () => _azione(q),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tabArrivi() {
    final arrivi = _arrivi;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _artController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                          hintText: 'Articolo', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fornController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                          hintText: 'Fornitore', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(_dataArrivo == null
                          ? 'Qualsiasi data'
                          : DateFormat('dd/MM/yyyy').format(_dataArrivo!)),
                      onPressed: _scegliData,
                    ),
                  ),
                  if (_dataArrivo != null)
                    IconButton(
                      tooltip: 'Togli la data',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dataArrivo = null),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Cerca'),
                    onPressed: _loadingArrivi ? null : _cercaArrivi,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingArrivi
              ? const Center(child: CircularProgressIndicator(color: AppColors.spinner))
              : arrivi == null
                  ? const SizedBox.shrink()
                  : arrivi.isEmpty
                      ? const Center(child: Text('Lista arrivi vuota'))
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Arrivi ( ${arrivi.length} )',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: arrivi.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final a = arrivi[i];
                                  final d = a.descrizione.toLowerCase();
                                  final r = a.ragioneSociale.toLowerCase();
                                  return ListTile(
                                    title: Text(a.articolo,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        '${d.length > 20 ? d.substring(0, 20) : d}\n'
                                        '${a.bolla} · ${a.ordine.isEmpty ? 'N.D.' : a.ordine} · '
                                        '${r.length > 15 ? r.substring(0, 15) : r}'),
                                    isThreeLine: true,
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${formatQta(a.qta)} ${a.um}',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(a.dataArrivo, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
        ),
      ],
    );
  }
}
