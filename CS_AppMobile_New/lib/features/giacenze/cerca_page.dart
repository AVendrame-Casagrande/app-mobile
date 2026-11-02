import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../models/articolo_giacenze.dart';
import '../../state/app_state.dart';
import '../../widgets/last_searched_list.dart';
import '../scanner/barcode_scanner_page.dart';
import 'cerca_service.dart';
import 'inventario_dialogs.dart';
import 'mgaut_aggiunta.dart';
import 'mgaut_page.dart';
import 'mgaut_service.dart';
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
        key: ValueKey(_articolo!.codice),
        articolo: _articolo!,
        service: _service,
        societa: _societa,
        // Link articolo dalla distinta: apre la scheda dell'articolo scelto.
        onApriArticolo: (codice) {
          _controller.text = codice;
          _caricaArticolo(codice);
        },
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
    super.key,
    required this.articolo,
    required this.service,
    required this.societa,
    required this.onApriArticolo,
  });

  final ArticoloGiacenze articolo;
  final CercaService service;
  final String societa;

  /// Apre la scheda di un altro articolo (link dalla distinta).
  final ValueChanged<String> onApriArticolo;

  @override
  State<_ArticoloDettaglio> createState() => _ArticoloDettaglioState();
}

class _ArticoloDettaglioState extends State<_ArticoloDettaglio> {
  // Distinta: per ciascun tipo ('esplosione' / 'implosione') l'articolo di cui
  // si sta visualizzando la distinta, la pila degli articoli precedenti (per
  // il pulsante "indietro", come esplosioniPrecedenti/implosioniPrecedenti
  // di Cordova) e la lista caricata.
  final Map<String, String> _codiceDistinta = {};
  final Map<String, List<String>> _distintePrecedenti = {
    'esplosione': [],
    'implosione': [],
  };
  final Map<String, List<DistintaArticolo>?> _distinte = {};
  bool _loadingDistinta = false;
  String _tipoDistinta = 'esplosione';

  // Filtri del tab movimenti: statici come giacenze.filtroCercaMov di Cordova
  // (restano validi per tutta la sessione, anche cambiando articolo).
  static final Set<String> _filtroCausali = {};
  static final Set<String> _filtroMagazzini = {};

  ArticoloGiacenze get a => widget.articolo;

  static String _n(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  String _codiceCorrenteDistinta(String tipo) => _codiceDistinta[tipo] ?? a.codice;

  /// Carica la distinta [tipo] di [codice] (default: articolo corrente della
  /// distinta). Senza [forza] non ricarica una distinta già presente.
  Future<void> _caricaDistinta(String tipo,
      {String? codice, bool forza = false}) async {
    if (_loadingDistinta) return;
    if (!forza && _distinte[tipo] != null) return;
    final cod = codice ?? _codiceCorrenteDistinta(tipo);
    setState(() => _loadingDistinta = true);
    List<DistintaArticolo> lista;
    try {
      lista = await widget.service.getListaDistinte(cod, tipoDistinta: tipo);
    } catch (e) {
      lista = [];
      if (mounted) invToast(context, 'Errore di Rete o del Server');
    }
    if (!mounted) return;
    setState(() {
      _codiceDistinta[tipo] = cod;
      _distinte[tipo] = lista;
      _loadingDistinta = false;
    });
  }

  /// Scende nella distinta di un componente/assieme (pulsante "cerca" di
  /// Cordova: #distintaEsplSearch / #distintaImplSearch).
  Future<void> _scendiDistinta(String tipo, String codice) async {
    if (_loadingDistinta) return;
    _distintePrecedenti[tipo]!.add(_codiceCorrenteDistinta(tipo));
    await _caricaDistinta(tipo, codice: codice, forza: true);
  }

  /// Torna alla distinta precedente (#distintaEsplBack / #distintaImplBack).
  Future<void> _risaliDistinta(String tipo) async {
    final pila = _distintePrecedenti[tipo]!;
    if (pila.isEmpty || _loadingDistinta) return;
    final codice = pila.removeLast();
    await _caricaDistinta(tipo, codice: codice, forza: true);
  }

  /// Torna alla distinta dell'articolo della scheda.
  Future<void> _distintaRadice(String tipo) async {
    if (_loadingDistinta) return;
    _distintePrecedenti[tipo]!.clear();
    await _caricaDistinta(tipo, codice: a.codice, forza: true);
  }

  /// Tap su una riga di distinta: popup con dati riga, disegni (solo se
  /// presenti), link alla scheda articolo e discesa nella sua distinta
  /// (solo se l'articolo ha a sua volta una distinta).
  Future<void> _apriRigaDistinta(DistintaArticolo r) async {
    final tipo = _tipoDistinta;
    final codice = tipo == 'esplosione' ? r.componente : r.assieme;
    final azione = await showDialog<_AzioneDistinta>(
      context: context,
      builder: (_) => _RigaDistintaDialog(
        riga: r,
        tipo: tipo,
        service: widget.service,
      ),
    );
    if (azione == null || !mounted) return;
    switch (azione) {
      case _AzioneDistinta.scendi:
        await _scendiDistinta(tipo, codice);
      case _AzioneDistinta.apriArticolo:
        final scelta = await invChoice(
          context,
          'LINK ARTICOLO $codice',
          "Vuoi effettuare la Ricerca dell'Articolo $codice?",
          ['Cerca', 'Chiudi'],
        );
        if (scelta == 0 && mounted) widget.onApriArticolo(codice);
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
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _FotoPage(foto: a.arrayImmagini, iniziale: i),
            )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                headers: _headersFoto(url),
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

  /// Icona MGAUT00/MGAUT10: aggiunge l'articolo alla lista prelievi di quel
  /// magazzino automatico — porting del click su .goToMgaut (Cerca/EventHandlers.js).
  Future<void> _aggiungiAMgaut(String codiceArticolo, String magazzino) async {
    final utente = context.read<AppState>().utenteLoggato;
    if (utente.isEnglish) {
      await invAlert(context, 'Accesso Negato', 'The MGAUT section is only available for CSPRO users');
      return;
    }
    if (utente.accountType == 'Utente Standard' || utente.isOspite) {
      await invAlert(context, 'Accesso Negato', 'Non sei abilitato ad accedere alla sezione MGAUT');
      return;
    }
    final aggiunto = await MgautAggiunta(
      context: context,
      service: MgautService(context.read<AppState>().api),
      magazzinoOrigine: magazzino,
      nomePortale: utente.nomePortale,
      articoloIniziale: codiceArticolo,
    ).avvia();
    if (!aggiunto || !mounted) return;
    final scelta = await invChoice(
      context,
      '$codiceArticolo Aggiunto',
      'Articolo $codiceArticolo aggiunto alla Lista $magazzino\n\n'
          'Vuoi aprire e visualizzare la Lista $magazzino?',
      ['Visualizza', 'Chiudi'],
    );
    if (scelta != 0 || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MgautPage(magazzinoIniziale: magazzino)),
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
                ? IconButton(
                    icon: const Icon(Icons.precision_manufacturing_outlined,
                        color: Color(0xFFEF6C00)),
                    tooltip: 'Aggiungi alla Lista ${m.codice}',
                    onPressed: () => _aggiungiAMgaut(a.codice, m.codice),
                  )
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
    final tipo = _tipoDistinta;
    final d = _distinte[tipo];
    final codiceCorrente = _codiceCorrenteDistinta(tipo);
    final pila = _distintePrecedenti[tipo]!;
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
        // Navigazione nella distinta (indietro / torna all'articolo).
        if (pila.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Distinta precedente',
                  onPressed:
                      _loadingDistinta ? null : () => _risaliDistinta(tipo),
                ),
                Expanded(
                  child: Text(
                    '${tipo == 'esplosione' ? 'Esplosione' : 'Implosione'} di $codiceCorrente',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Torna a ${a.codice}',
                  onPressed:
                      _loadingDistinta ? null : () => _distintaRadice(tipo),
                ),
              ],
            ),
          ),
        Expanded(child: _distintaLista(d)),
      ],
    );
  }

  Widget _distintaLista(List<DistintaArticolo>? d) {
    if (_loadingDistinta) {
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
          onTap: () => _apriRigaDistinta(r),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // TAB MOV
  // --------------------------------------------------------------------------
  bool get _filtriMovAttivi =>
      _filtroCausali.isNotEmpty || _filtroMagazzini.isNotEmpty;

  /// Movimenti filtrati per causale ("causale-valore") e magazzino, come
  /// drawInnerPageMovimenti di Cordova (OR dentro il gruppo, AND tra gruppi).
  List<MovimentoArticolo> get _movimentiFiltrati => a.listaMovimenti
      .where((m) =>
          (_filtroMagazzini.isEmpty || _filtroMagazzini.contains(m.magazzino)) &&
          (_filtroCausali.isEmpty || _filtroCausali.contains(m.chiaveCausale)))
      .toList();

  /// Etichetta di una causale del filtro ("VE-" → "VE").
  static String _etichettaCausale(String c) =>
      c.endsWith('-') ? c.substring(0, c.length - 1) : c;

  void _azzeraFiltriMovimenti() {
    setState(() {
      _filtroCausali.clear();
      _filtroMagazzini.clear();
    });
  }

  /// Selettore filtri (select multipla #filterMovimento di Cordova):
  /// "Filtri causali" e "Filtri magazzini" + "Azzera filtri".
  Future<void> _apriFiltriMovimenti() async {
    final causali = {
      ...a.listaMovimenti.map((m) => m.chiaveCausale),
      ..._filtroCausali,
    }.toList()
      ..sort();
    final magazzini = {
      ...a.listaMovimenti.map((m) => m.magazzino),
      ..._filtroMagazzini,
    }.toList()
      ..sort();
    final selCausali = {..._filtroCausali};
    final selMagazzini = {..._filtroMagazzini};

    Widget gruppo(String titolo, List<String> valori, Set<String> sel,
        StateSetter setD, String Function(String) etichetta) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titolo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final v in valori)
                FilterChip(
                  label: Text(v.isEmpty ? '(vuoto)' : etichetta(v)),
                  selected: sel.contains(v),
                  onSelected: (on) => setD(() {
                    if (on) {
                      sel.add(v);
                    } else {
                      sel.remove(v);
                    }
                  }),
                ),
            ],
          ),
        ],
      );
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Filtri movimenti'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  gruppo('Filtri causali', causali, selCausali, setD,
                      _etichettaCausale),
                  const SizedBox(height: 16),
                  gruppo('Filtri magazzini', magazzini, selMagazzini, setD,
                      (v) => v),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                selCausali.clear();
                selMagazzini.clear();
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Azzera filtri'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Applica'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _filtroCausali
        ..clear()
        ..addAll(selCausali);
      _filtroMagazzini
        ..clear()
        ..addAll(selMagazzini);
    });
  }

  /// Dettaglio movimento (openPopupMovimento di Cordova).
  Future<void> _apriDettaglioMovimento(MovimentoArticolo m) {
    final utente = context.read<AppState>().utenteLoggato;
    return showDialog<void>(
      context: context,
      builder: (_) => _MovimentoDialog(
        movimento: m,
        service: widget.service,
        // Il recupero del padre dell'ODL è solo per CSPRO (lingua 'I').
        recuperaPadre: utente.language == 'I',
      ),
    );
  }

  Widget _tabMovimenti() {
    if (a.listaMovimenti.isEmpty) return _empty('Nessun movimento');
    final oggiInt = dataIntFromRaw(DateFormat('yyyyMMdd').format(DateTime.now()));
    final lista = _movimentiFiltrati;
    final filtri = _filtriMovAttivi;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ultimi 2 anni: ${lista.length}'
                  '${filtri ? ' di ${a.listaMovimenti.length}' : ''} movimenti',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (filtri)
                TextButton(
                  onPressed: _azzeraFiltriMovimenti,
                  child: const Text('Azzera'),
                ),
              IconButton(
                icon: Icon(
                  filtri ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: filtri ? AppColors.casagrandeDark : Colors.black45,
                ),
                tooltip: 'Filtri',
                onPressed: _apriFiltriMovimenti,
              ),
            ],
          ),
        ),
        if (filtri)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final c in _filtroCausali)
                    InputChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Causale ${_etichettaCausale(c)}'),
                      onDeleted: () =>
                          setState(() => _filtroCausali.remove(c)),
                    ),
                  for (final mag in _filtroMagazzini)
                    InputChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Mag $mag'),
                      onDeleted: () =>
                          setState(() => _filtroMagazzini.remove(mag)),
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: lista.isEmpty
              ? _empty('Nessun movimento con i filtri selezionati')
              : _listaMovimenti(lista, oggiInt),
        ),
      ],
    );
  }

  Widget _listaMovimenti(List<MovimentoArticolo> lista, int oggiInt) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = lista[i];
        final causale =
            '${m.movCausale}${m.movValore.isNotEmpty ? ' -${m.movValore}' : ''}'
            '${m.movStorno.isNotEmpty ? ' -${m.movStorno}' : ''}';
        final dataDisp = m.dataDisplay(oggiInt);
        return ListTile(
          dense: true,
          onTap: () => _apriDettaglioMovimento(m),
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
                  onTap: () => _apriDettaglioOda(o),
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
                  onTap: () => _apriDettaglioOdl(o),
                  title: Text(
                      o.codiceOrdine +
                          (o.statoOrdine.isNotEmpty ? '  ·  S.${o.statoOrdine}' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    o.magazzino +
                        (o.responsabileOrdine.isNotEmpty
                            ? '  ·  ${o.responsabileOrdine}'
                            : ''),
                    [
                      if (o.dataInizio.isNotEmpty) 'Inizio ${o.dataInizio}',
                      if (o.dataConsegna.isNotEmpty)
                        'Consegna ${o.dataConsegna}',
                    ].join('  ·  '),
                  ].where((s) => s.isNotEmpty).join('\n')),
                  isThreeLine:
                      o.dataInizio.isNotEmpty || o.dataConsegna.isNotEmpty,
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
                // Stato > 10 = fa impegno → verde (come Cordova).
                color: (int.tryParse(i.stato) ?? 0) > 10
                    ? const Color(0xFFE8F5E9)
                    : null,
                child: ListTile(
                  dense: true,
                  onTap: () => _apriDettaglioImpegnoOdl(i),
                  title: Text(
                      i.odl + (i.fase.isNotEmpty ? '  ·  fase ${i.fase}' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text([
                    if (i.padre.isNotEmpty) 'Padre ${i.padre}',
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
  // POPUP DETTAGLIO (ORD / IMP)
  // --------------------------------------------------------------------------

  /// Ordine di acquisto: date e quantità confermate dal fornitore
  /// (openPopupOrdineOda di Cordova: Q.tà | Data Conf | Note).
  Future<void> _apriDettaglioOda(OrdineAcquisto o) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(o.numeroOrdine + (o.pos.isNotEmpty ? '/${o.pos}' : '')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rigaKv('Fornitore', o.azienda.toLowerCase()),
                _rigaKv('Q.tà in ordine', o.qtaInOrdine),
                _rigaKv('Data consegna', o.dataConsegna),
                const Divider(height: 20),
                const Text('Conferme fornitore',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (o.dettagliOrdine.isEmpty)
                  const Text('Nessuna conferma',
                      style: TextStyle(color: Colors.black54))
                else ...[
                  const _RigaTabella(
                    ['Q.tà', 'Data Conf', 'Note'],
                    grassetto: true,
                  ),
                  for (final d in o.dettagliOrdine)
                    _RigaTabella([
                      d.qtaConfermata.isEmpty ? '-' : d.qtaConfermata,
                      d.dataConfermata.isEmpty ? '-' : d.dataConfermata,
                      d.note.toLowerCase(),
                    ]),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Chiudi')),
        ],
      ),
    );
  }

  /// Ordine di lavoro (openPopupOrdineOdl di Cordova: Magazzino,
  /// Responsabile Ordine, Data Inizio).
  Future<void> _apriDettaglioOdl(OrdineLavoro o) {
    return _dialogDettaglio(o.codiceOrdine, [
      ('Magazzino', o.magazzino),
      ('Responsabile Ordine', o.responsabileOrdine),
      ('Data Inizio', o.dataInizio),
      ('Data Consegna', o.dataConsegna),
      ('Stato', o.statoOrdine),
      ('Q.tà', o.qta),
    ]);
  }

  /// Impegno da ODL (openPopupImpegniOdl di Cordova: descrizione, Copertura,
  /// Fase, Stato, Tipologia).
  Future<void> _apriDettaglioImpegnoOdl(ImpegnoOdl i) {
    return _dialogDettaglio(
      i.odl,
      [
        ('Padre', i.padre),
        ('Magazzino', i.magazzino),
        ('Impegnato', _n(i.impegnato)),
        ('Data fabbisogno', i.data),
        ('Copertura', i.copertura),
        ('Fase', i.fase),
        ('Stato', i.stato),
        ('Tipologia', i.tipologia),
      ],
      sottotitolo: i.descrizione.toLowerCase(),
    );
  }

  Future<void> _dialogDettaglio(String titolo, List<(String, String)> righe,
      {String sottotitolo = ''}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titolo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sottotitolo.isNotEmpty) ...[
                Text(sottotitolo,
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
              ],
              for (final r in righe) _rigaKv(r.$1, r.$2),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Chiudi')),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _kv(String k, String v) => _rigaKv(k, v);

  Widget _empty(String text) => Center(
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      );

  Future<void> _apriUrl(String url) => _apriUrlEsterno(context, url);
}

// ----------------------------------------------------------------------------
// WIDGET / FUNZIONI CONDIVISE DAI POPUP
// ----------------------------------------------------------------------------

/// Riga "etichetta: valore" (valore vuoto → "-").
Widget _rigaKv(String k, String v) {
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
          child: Text(v.trim().isEmpty ? '-' : v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

/// Apre un URL (PDF/foto) nell'app esterna, come cordova.InAppBrowser '_system'.
Future<void> _apriUrlEsterno(BuildContext context, String url) async {
  if (url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossibile aprire il file')),
    );
  }
}

/// Riga di una tabellina a 3 colonne (Q.tà | Data Conf | Note).
class _RigaTabella extends StatelessWidget {
  const _RigaTabella(this.celle, {this.grassetto = false});

  final List<String> celle;
  final bool grassetto;

  @override
  Widget build(BuildContext context) {
    final stile = TextStyle(
        fontWeight: grassetto ? FontWeight.bold : FontWeight.normal);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(celle[0], style: stile)),
          Expanded(flex: 3, child: Text(celle[1], style: stile)),
          Expanded(flex: 5, child: Text(celle[2], style: stile)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// POPUP RIGA DISTINTA
// ----------------------------------------------------------------------------

enum _AzioneDistinta { apriArticolo, scendi }

/// Popup di una riga di distinta (click su .singolaEsplosione /
/// .singolaImplosione di Cordova): codice e descrizione, POS | EM, link
/// all'articolo, icone PDF dei disegni (solo se getPdfList ne restituisce) e
/// discesa nella distinta dell'articolo (solo se ne ha una).
/// Ritorna l'azione scelta (null = chiuso).
class _RigaDistintaDialog extends StatefulWidget {
  const _RigaDistintaDialog({
    required this.riga,
    required this.tipo,
    required this.service,
  });

  final DistintaArticolo riga;
  final String tipo;
  final CercaService service;

  @override
  State<_RigaDistintaDialog> createState() => _RigaDistintaDialogState();
}

class _RigaDistintaDialogState extends State<_RigaDistintaDialog> {
  List<PdfFileArticolo>? _pdf;
  bool _haDistinta = false;

  bool get _isEspl => widget.tipo == 'esplosione';
  DistintaArticolo get r => widget.riga;

  /// Articolo collegato: il componente nell'esplosione, l'assieme
  /// nell'implosione.
  String get _codice => _isEspl ? r.componente : r.assieme;
  String get _descrizione =>
      _isEspl ? r.descrizioneComponente : r.descrizioneAssieme;

  @override
  void initState() {
    super.initState();
    _caricaPdf();
    _controllaDistinta();
  }

  Future<void> _caricaPdf() async {
    List<PdfFileArticolo> lista;
    try {
      lista = await widget.service.getPdfList(_codice, r.disegno);
    } catch (_) {
      lista = const [];
    }
    if (mounted) setState(() => _pdf = lista);
  }

  Future<void> _controllaDistinta() async {
    bool ha;
    try {
      ha = await widget.service.haDistinta(_codice, widget.tipo);
    } catch (_) {
      ha = false;
    }
    if (mounted) setState(() => _haDistinta = ha);
  }

  String _etichettaPdf(PdfFileArticolo p) {
    final parti = [
      if (p.tipoPdf.isNotEmpty) p.tipoPdf,
      if (p.numeroFoglioPdfDisplay.isNotEmpty)
        'Foglio ${p.numeroFoglioPdfDisplay}',
    ];
    return parti.isEmpty ? 'Disegno' : parti.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final pdf = _pdf;
    return AlertDialog(
      title: Text(_codice),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_descrizione.isNotEmpty) ...[
                Text(_descrizione.toLowerCase(),
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
              ],
              _rigaKv(_isEspl ? 'Assieme' : 'Componente',
                  _isEspl ? r.assieme : r.componente),
              _rigaKv('POS | EM', '${r.pos} | ${r.em}'),
              _rigaKv('Q.tà', '${r.qta} ${r.mutms}'.trim()),
              if (r.disegno.isNotEmpty) _rigaKv('Disegno', r.disegno),
              if (pdf == null)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(color: AppColors.spinner),
                )
              else if (pdf.isNotEmpty) ...[
                const Divider(height: 20),
                const Text('Disegni',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                for (final p in pdf)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf,
                        color: Color(0xFFC62828)),
                    title: Text(_etichettaPdf(p)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _apriUrlEsterno(context, p.url),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_haDistinta)
          TextButton.icon(
            icon: const Icon(Icons.account_tree_outlined),
            label: Text(_isEspl ? 'Esplodi' : 'Implodi'),
            onPressed: () =>
                Navigator.of(context).pop(_AzioneDistinta.scendi),
          ),
        TextButton.icon(
          icon: const Icon(Icons.link),
          label: const Text('Scheda'),
          onPressed: () =>
              Navigator.of(context).pop(_AzioneDistinta.apriArticolo),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// POPUP DETTAGLIO MOVIMENTO
// ----------------------------------------------------------------------------

/// Dettaglio di un movimento (openPopupMovimento di Cordova): Fornitore,
/// Padre + descrizione, Utente Movimento, Vano, Nota, Comm | Bolla.
/// Se il riferimento è un ODL e manca il padre, lo recupera dal server
/// (addPadreDescrizioneFixToMovimento, solo CSPRO).
class _MovimentoDialog extends StatefulWidget {
  const _MovimentoDialog({
    required this.movimento,
    required this.service,
    required this.recuperaPadre,
  });

  final MovimentoArticolo movimento;
  final CercaService service;
  final bool recuperaPadre;

  @override
  State<_MovimentoDialog> createState() => _MovimentoDialogState();
}

class _MovimentoDialogState extends State<_MovimentoDialog> {
  late String _codicePadre;
  late String _descrizionePadre;
  bool _loadingPadre = false;

  MovimentoArticolo get m => widget.movimento;

  @override
  void initState() {
    super.initState();
    _codicePadre = m.codicePadre;
    _descrizionePadre = m.descrizionePadre;
    final rif = m.riferimento.trim();
    if (widget.recuperaPadre &&
        rif.isNotEmpty &&
        num.tryParse(rif) != null &&
        _codicePadre.isEmpty) {
      _loadingPadre = true;
      _caricaPadre(rif);
    }
  }

  Future<void> _caricaPadre(String odl) async {
    var codice = '';
    var descrizione = '';
    try {
      (codice, descrizione) = await widget.service.getPadreOdl(odl);
    } catch (_) {
      // In caso di errore mostra comunque il popup senza padre.
    }
    if (!mounted) return;
    setState(() {
      _codicePadre = codice.isEmpty ? '-' : codice;
      _descrizionePadre = descrizione.isEmpty ? '-' : descrizione;
      _loadingPadre = false;
    });
  }

  /// Visualizzazione bolla da Arxivar: in Cordova non è ancora disponibile
  /// (applicazione.query.downloadArxivarBolla mostra solo un avviso).
  void _apriBolla() {
    invAlert(context, m.bolla,
        'Visualizzazione ( da Arxivar ) della Bolla ${m.bolla} non ancora disponibile');
  }

  @override
  Widget build(BuildContext context) {
    final causale = [m.movCausale, m.movValore, m.movStorno]
        .where((s) => s.isNotEmpty)
        .join(' - ');
    final data = [m.data, m.ora].where((s) => s.isNotEmpty).join(' ');
    final fornitore = [
      m.codiceFornitore,
      m.descrizioneFornitore.toLowerCase(),
    ].where((s) => s.trim().isNotEmpty).join(' | ');
    return AlertDialog(
      title: Text(m.riferimento.isEmpty ? 'Movimento' : m.riferimento),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rigaKv('Magazzino', m.magazzino),
              _rigaKv('Causale', causale),
              _rigaKv('Q.tà', m.quantita),
              _rigaKv('Data', data),
              const Divider(height: 20),
              _rigaKv('Fornitore', fornitore),
              if (_loadingPadre)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(color: AppColors.spinner),
                )
              else ...[
                _rigaKv('Padre', _codicePadre),
                if (_descrizionePadre.isNotEmpty && _descrizionePadre != '-')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(_descrizionePadre.toLowerCase(),
                        style: const TextStyle(color: Colors.black54)),
                  ),
              ],
              _rigaKv('Utente Movimento', m.responsabile),
              _rigaKv('Vano', m.vano),
              _rigaKv('Nota', m.nota.toLowerCase()),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text('Comm | Bolla',
                          style: TextStyle(color: Colors.black54)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          Text('${m.trni.isEmpty ? '-' : m.trni} | ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          if (m.bolla.isEmpty)
                            const Text('-')
                          else
                            GestureDetector(
                              onTap: _apriBolla,
                              child: Text(
                                m.bolla,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}

/// Le foto ARXivar arrivano dall'API (azione giacenze/fotoArxivar) e richiedono il
/// token; quelle dell'archivio del tecnico sono file statici del web server.
Map<String, String>? _headersFoto(String url) =>
    url.startsWith(AppConfig.apiBaseUrl) ? AuthToken.headers : null;

/// Foto dell'articolo a schermo intero, scorrevoli e ingrandibili.
class _FotoPage extends StatefulWidget {
  const _FotoPage({required this.foto, required this.iniziale});

  final List<String> foto;
  final int iniziale;

  @override
  State<_FotoPage> createState() => _FotoPageState();
}

class _FotoPageState extends State<_FotoPage> {
  late final PageController _pagine = PageController(initialPage: widget.iniziale);
  late int _corrente = widget.iniziale;

  @override
  void dispose() {
    _pagine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Foto ${_corrente + 1} di ${widget.foto.length}'),
      ),
      body: PageView.builder(
        controller: _pagine,
        itemCount: widget.foto.length,
        onPageChanged: (i) => setState(() => _corrente = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.network(
              widget.foto[i],
              headers: _headersFoto(widget.foto[i]),
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const CircularProgressIndicator(color: Colors.white),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
