import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/articolo_giacenze.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'cerca_service.dart';
import 'movimento_page.dart';

/// Pagina Giacenze → Cerca — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/Cerca.
/// Cerca un articolo e ne mostra la scheda completa con 5 tab:
/// ART (anagrafica + giacenze + foto + disegni), DIST (distinta),
/// MOV (movimenti), ORD (ordini), IMP (impegni).
class CercaPage extends StatefulWidget {
  const CercaPage({super.key, this.codiceArticolo});

  /// Se valorizzato, apre direttamente la scheda di questo articolo
  /// (es. "Link Articolo" dall'Inventario).
  final String? codiceArticolo;

  @override
  State<CercaPage> createState() => _CercaPageState();
}

class _CercaPageState extends State<CercaPage> {
  late final CercaService _service;
  late final String _societa;

  final _controller = TextEditingController();

  static const String _sezione = 'cerca';

  bool _loading = false;
  String? _error;
  String? _info;
  List<ArticoloRicerca> _risultati = [];
  ArticoloGiacenze? _articolo;
  List<LastSearchedItem> _recenti = [];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _service = CercaService(app.api);
    _societa = _service.societaPerUtente(app.utenteLoggato);
    _recenti = LastSearched.get(_sezione);
    final code = widget.codiceArticolo;
    if (code != null && code.trim().isNotEmpty) {
      _controller.text = code.trim();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _caricaArticolo(code.trim()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cerca() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _risultati = [];
      _articolo = null;
    });
    try {
      final lista = await _service.cercaLike(input, _societa);
      if (!mounted) return;
      if (lista.isEmpty) {
        setState(() {
          _info = 'Nessun articolo trovato';
          _loading = false;
        });
      } else if (lista.length == 1) {
        await _caricaArticolo(lista.first.codice);
      } else {
        setState(() {
          _risultati = lista;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore di Rete o del Server';
        _loading = false;
      });
    }
  }

  Future<void> _caricaArticolo(String codice) async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _risultati = [];
    });
    try {
      final art = await _service.getSingoloArticolo(codice, _societa);
      if (!mounted) return;
      if (art != null) {
        await LastSearched.add(_sezione, art.codice);
      }
      if (!mounted) return;
      setState(() {
        _articolo = art;
        _info = art == null ? 'Articolo non trovato' : null;
        _loading = false;
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
    _controller.text = code;
    _cerca();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cerca')),
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
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _cerca(),
              decoration: InputDecoration(
                hintText: 'Codice o descrizione articolo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scansiona',
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
      return _centerMessage(Icons.cloud_off, _error!, retry: _cerca);
    }
    if (_articolo != null) {
      return _ArticoloDettaglio(
        articolo: _articolo!,
        service: _service,
        societa: _societa,
      );
    }
    if (_risultati.isNotEmpty) {
      return _listaRisultati();
    }
    if (_info != null) {
      return _centerMessage(Icons.search_off, _info!);
    }
    return LastSearchedList(
      items: _recenti,
      onTap: (codice) {
        _controller.text = codice;
        _caricaArticolo(codice);
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

  Widget _listaRisultati() {
    return ListView.separated(
      itemCount: _risultati.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = _risultati[i];
        return ListTile(
          title: Text(r.codice,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: r.descrizione.isEmpty ? null : Text(r.descrizione.toLowerCase()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _caricaArticolo(r.codice),
        );
      },
    );
  }
}

/// Dettaglio articolo con 5 tab.
class _ArticoloDettaglio extends StatefulWidget {
  const _ArticoloDettaglio({
    required this.articolo,
    required this.service,
    required this.societa,
  });

  final ArticoloGiacenze articolo;
  final CercaService service;
  final String societa;

  @override
  State<_ArticoloDettaglio> createState() => _ArticoloDettaglioState();
}

class _ArticoloDettaglioState extends State<_ArticoloDettaglio> {
  List<DistintaArticolo>? _distintaEspl;
  List<DistintaArticolo>? _distintaImpl;
  bool _loadingDistinta = false;
  String _tipoDistinta = 'esplosione';

  ArticoloGiacenze get a => widget.articolo;

  static String _n(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  Future<void> _caricaDistinta(String tipo) async {
    final gia = tipo == 'esplosione' ? _distintaEspl : _distintaImpl;
    if (gia != null || _loadingDistinta) return;
    setState(() => _loadingDistinta = true);
    try {
      final lista =
          await widget.service.getListaDistinte(a.codice, tipoDistinta: tipo);
      if (!mounted) return;
      setState(() {
        if (tipo == 'esplosione') {
          _distintaEspl = lista;
        } else {
          _distintaImpl = lista;
        }
        _loadingDistinta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (tipo == 'esplosione') {
          _distintaEspl = [];
        } else {
          _distintaImpl = [];
        }
        _loadingDistinta = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.codice,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (a.descrizione.isNotEmpty)
                  Text(a.descrizione.toLowerCase(),
                      style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            labelColor: AppColors.casagrandeDark,
            tabAlignment: TabAlignment.start,
            onTap: (i) {
              if (i == 1) _caricaDistinta(_tipoDistinta);
            },
            tabs: const [
              Tab(text: 'ART'),
              Tab(text: 'DIST'),
              Tab(text: 'MOV'),
              Tab(text: 'ORD'),
              Tab(text: 'IMP'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _tabArt(),
                _tabDistinta(),
                _tabMovimenti(),
                _tabOrdini(),
                _tabImpegni(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB ART
  // --------------------------------------------------------------------------
  Widget _tabArt() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _totaliCard(),
        const SizedBox(height: 12),
        _infoCard(),
        if (a.arrayImmagini.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Foto'),
          _fotoGallery(),
        ],
        if (a.arrayPdfFile.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Disegni'),
          ...a.arrayPdfFile.map(_disegnoTile),
        ],
        if (a.listaMagazzini.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Magazzini'),
          ...a.listaMagazzini.map(_magazzinoTile),
        ],
        if (a.listaPrezzi.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Listino prezzi'),
          ...a.listaPrezzi.map(_prezzoTile),
        ],
        if (a.listaNote.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Note'),
          ...a.listaNote.map(_notaTile),
        ],
      ],
    );
  }

  Widget _totaliCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _totale('Giacente', a.giacenteTotale, Colors.black87),
                _totale('Impegnato', a.impegnatoTotale, const Color(0xFFC62828)),
                _totale('Disponibile', a.disponibileTotale,
                    const Color(0xFF2E7D32)),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _totale('In Produzione', a.inOrdineProduzione,
                    const Color(0xFF3949AB)),
                _totale('In Acquisto', a.inOrdineAcquisto,
                    const Color(0xFFEF6C00)),
                _totale('Eccedenza', _n(a.eccedenza),
                    a.eccedenza < 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totale(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value.isEmpty ? '-' : value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final rows = <Widget>[
      if (a.unitaMisura.isNotEmpty) _kv('Unità di misura', a.unitaMisura),
      if (a.tipoArticolo.isNotEmpty) _kv('Tipo articolo', a.tipoArticolo),
      if (a.pesoLordo.isNotEmpty) _kv('Peso lordo', a.pesoLordo),
      if (a.pesoNetto.isNotEmpty) _kv('Peso netto', a.pesoNetto),
      if (a.trattamento.isNotEmpty) _kv('Trattamento', a.trattamento),
      if (a.colore.isNotEmpty) _kv('Colore', a.colore),
      if (a.codiceDisegno.isNotEmpty) _kv('Disegno', a.codiceDisegno),
      if (a.magazzinoVanoPreferenziale.isNotEmpty)
        _kv('Vano preferenziale', a.magazzinoVanoPreferenziale),
      if (a.ultimoVersamento.isNotEmpty)
        _kv('Ultimo versamento', a.ultimoVersamento),
      if (a.ultimoConsumo.isNotEmpty) _kv('Ultimo consumo', a.ultimoConsumo),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: rows),
      ),
    );
  }

  Widget _fotoGallery() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: a.arrayImmagini.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final url = a.arrayImmagini[i];
          return GestureDetector(
            onTap: () => _apriUrl(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 160,
                  color: const Color(0xFFEEEEEE),
                  child: const Icon(Icons.broken_image, color: Colors.black26),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _disegnoTile(PdfFileArticolo p) {
    final label = [
      if (p.tipoPdf.isNotEmpty) p.tipoPdf,
      if (p.numeroFoglioPdfDisplay.isNotEmpty) 'Foglio ${p.numeroFoglioPdfDisplay}',
    ].join('  ·  ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFC62828)),
        title: Text(label.isEmpty ? 'Disegno' : label),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _apriUrl(p.url),
      ),
    );
  }

  Widget _magazzinoTile(MagazzinoArticolo m) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        title: Text(
            '${m.codice}${m.vano.isNotEmpty ? '  ·  Vano ${m.vano}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Giac: ${m.giacente.isEmpty ? '-' : m.giacente}   '
            'Imp: ${m.impegnato.isEmpty ? '-' : m.impegnato}'
            '${m.categoria.isNotEmpty ? '   Cat: ${m.categoria}' : ''}'),
        trailing: m.movimentabile
            ? IconButton(
                icon: const Icon(Icons.swap_horiz, color: Color(0xFF3949AB)),
                tooltip: 'Movimenta',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MovimentoPage(codiceArticolo: a.codice),
                  ),
                ),
              )
            : m.isAutomatico
                ? const Icon(Icons.precision_manufacturing_outlined,
                    color: Color(0xFFEF6C00))
                : null,
      ),
    );
  }

  Widget _prezzoTile(PrezzoListino p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        title: Text(
            p.prezzoFmt +
                (p.unitaMisura.isNotEmpty
                    ? ' / ${p.unitaMisura.toLowerCase()}'
                    : ''),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (p.azienda.isNotEmpty) p.azienda.toLowerCase(),
          if (p.tq.isNotEmpty) 'Tq ${p.tq}',
          if (p.tf.isNotEmpty) 'Tf ${p.tf}',
          if (p.dataInizio.isNotEmpty) 'dal ${p.dataInizio}',
        ].join('   ')),
      ),
    );
  }

  Widget _notaTile(NotaArticolo n) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.sticky_note_2_outlined),
        title: Text(n.nota),
        subtitle: n.tipoNota.isEmpty ? null : Text(n.tipoNota),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB DIST
  // --------------------------------------------------------------------------
  Widget _tabDistinta() {
    final isEspl = _tipoDistinta == 'esplosione';
    final d = isEspl ? _distintaEspl : _distintaImpl;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'esplosione', label: Text('Esplosione')),
              ButtonSegment(value: 'implosione', label: Text('Implosione')),
            ],
            selected: {_tipoDistinta},
            onSelectionChanged: (s) {
              setState(() => _tipoDistinta = s.first);
              _caricaDistinta(s.first);
            },
          ),
        ),
        Expanded(child: _distintaLista(d)),
      ],
    );
  }

  Widget _distintaLista(List<DistintaArticolo>? d) {
    if (_loadingDistinta && d == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (d == null) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.account_tree),
          label: const Text('Carica distinta'),
          onPressed: () => _caricaDistinta(_tipoDistinta),
        ),
      );
    }
    if (d.isEmpty) {
      return _empty('Nessuna distinta ($_tipoDistinta)');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: d.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = d[i];
        // Nell'implosione interessa l'assieme padre, nell'esplosione il componente.
        final isEspl = _tipoDistinta == 'esplosione';
        final codice = isEspl ? r.componente : r.assieme;
        final descr =
            isEspl ? r.descrizioneComponente : r.descrizioneAssieme;
        return ListTile(
          dense: true,
          leading: r.pos.isEmpty
              ? null
              : CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE0E0E0),
                  child: Text(r.pos, style: const TextStyle(fontSize: 11)),
                ),
          title: Text(codice,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text([
            if (descr.isNotEmpty) descr.toLowerCase(),
            if (r.disegno.isNotEmpty) 'Dis: ${r.disegno}',
          ].join('\n')),
          isThreeLine: descr.isNotEmpty && r.disegno.isNotEmpty,
          trailing: Text('${r.qta} ${r.mutms}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // TAB MOV
  // --------------------------------------------------------------------------
  Widget _tabMovimenti() {
    if (a.listaMovimenti.isEmpty) return _empty('Nessun movimento');
    final oggiInt = dataIntFromRaw(DateFormat('yyyyMMdd').format(DateTime.now()));
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: a.listaMovimenti.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = a.listaMovimenti[i];
        final causale =
            '${m.movCausale}${m.movValore.isNotEmpty ? ' -${m.movValore}' : ''}'
            '${m.movStorno.isNotEmpty ? ' -${m.movStorno}' : ''}';
        final dataDisp = m.dataDisplay(oggiInt);
        return ListTile(
          dense: true,
          title: Row(
            children: [
              Expanded(
                child: Text(m.riferimento.isEmpty ? causale : m.riferimento,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text(m.quantita,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          subtitle: Text([
            '${m.magazzino}${m.vano.isNotEmpty ? '/${m.vano}' : ''}  ·  $causale',
            if (m.descrizionePadre.isNotEmpty)
              m.descrizionePadre.toLowerCase(),
            if (dataDisp.isNotEmpty) dataDisp,
          ].join('\n')),
          isThreeLine: m.descrizionePadre.isNotEmpty,
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // TAB ORD
  // --------------------------------------------------------------------------
  Widget _tabOrdini() {
    if (a.listaOrdini.isEmpty && a.listaOrdiniOdl.isEmpty) {
      return _empty('Nessun ordine');
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (a.listaOrdini.isNotEmpty) ...[
          _sectionTitle('Ordini di Acquisto (${a.listaOrdini.length})'),
          ...a.listaOrdini.map((o) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(
                      o.numeroOrdine + (o.pos.isNotEmpty ? '/${o.pos}' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    if (o.azienda.isNotEmpty) o.azienda.toLowerCase(),
                    if (o.dataConsegna.isNotEmpty) 'Consegna ${o.dataConsegna}',
                  ].join('   ')),
                  trailing: Text(o.qtaInOrdine,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
        if (a.listaOrdiniOdl.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionTitle('Ordini di Lavoro (${a.listaOrdiniOdl.length})'),
          ...a.listaOrdiniOdl.map((o) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(
                      o.codiceOrdine +
                          (o.statoOrdine.isNotEmpty ? '  ·  S.${o.statoOrdine}' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    o.magazzino +
                        (o.responsabileOrdine.isNotEmpty
                            ? '  ·  ${o.responsabileOrdine}'
                            : ''),
                    if (o.dataConsegna.isNotEmpty) 'Consegna ${o.dataConsegna}',
                  ].join('\n')),
                  isThreeLine: o.dataConsegna.isNotEmpty,
                  trailing: Text(o.qta,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB IMP
  // --------------------------------------------------------------------------
  Widget _tabImpegni() {
    if (a.listaImpegniOdl.isEmpty &&
        a.listaImpegniOdv.isEmpty &&
        a.listaFabbisogni.isEmpty &&
        a.listaMancanti.isEmpty) {
      return _empty('Nessun impegno');
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (a.listaImpegniOdl.isNotEmpty) ...[
          _sectionTitle('Da Ordini di Lavoro (${a.listaImpegniOdl.length})'),
          ...a.listaImpegniOdl.map((i) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(
                      i.odl + (i.fase.isNotEmpty ? '  ·  fase ${i.fase}' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    if (i.descrizione.isNotEmpty) i.descrizione.toLowerCase(),
                    i.magazzino +
                        (i.stato.isNotEmpty ? '  ·  S.${i.stato}' : '') +
                        (i.data.isNotEmpty ? '  ·  ${i.data}' : ''),
                  ].join('\n')),
                  isThreeLine: i.descrizione.isNotEmpty,
                  trailing: Text(_n(i.impegnato),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
        if (a.listaImpegniOdv.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionTitle('Da Ordini di Vendita (${a.listaImpegniOdv.length})'),
          ...a.listaImpegniOdv.map((i) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(i.odv,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    if (i.azienda.isNotEmpty) i.azienda.toLowerCase(),
                    if (i.dataConsegna.isNotEmpty) 'Consegna ${i.dataConsegna}',
                  ].join('   ')),
                  trailing: Text(_n(i.impegnato),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
        if (a.listaFabbisogni.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionTitle('Da Fabbisogni MRP (${a.listaFabbisogni.length})'),
          ...a.listaFabbisogni.map((f) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(f.codicePadre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    if (f.descrizionePadre.isNotEmpty)
                      f.descrizionePadre.toLowerCase(),
                    if (f.data.isNotEmpty) f.data,
                  ].join('   ')),
                  trailing: Text(_n(f.impegnato),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
        if (a.listaMancanti.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionTitle('Mancanti (${a.listaMancanti.length})'),
          ...a.listaMancanti.map((m) => Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(
                      m.odl + (m.tipoodl.isNotEmpty ? '/${m.tipoodl}' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    if (m.mag.isNotEmpty) 'Mag: ${m.mag}',
                    'Prelievi (P/R/W/Y): ${m.statoPrelievi}',
                    if (m.dataFabb.isNotEmpty) 'Data fab: ${m.dataFabb}',
                  ].join('\n')),
                  isThreeLine: true,
                ),
              )),
        ],
      ],
    );
  }

  // --------------------------------------------------------------------------
  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(k, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 3,
            child: Text(v,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) => Center(
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      );

  Future<void> _apriUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire il file')),
      );
    }
  }
}
