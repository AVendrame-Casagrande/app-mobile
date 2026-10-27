import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/inventario.dart';
import '../../state/app_state.dart';
import '../chat/chat_service.dart';
import 'inventario_dialogs.dart';
import 'inventario_lista_page.dart';
import 'inventario_service.dart';

/// Pagina Giacenze → Inventario (elenco liste) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/Inventario
/// (drawInnerPageTab1 senza lista corrente + Query.getElencoListe/writeLista).
/// Crea una nuova lista; tieni premuto su una lista per completarla,
/// riaprirla o eliminarla; tocca una lista aperta per lavorarci.
class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  late final InventarioService _service;
  late final AppState _app;

  bool _loading = false;
  String? _error;
  List<InventarioTestata> _liste = [];
  bool _mostraChiuse = false;

  /// codiceUtente → nomePortale (applicazione.listaUtentiTotali).
  Map<String, String> _nomiUtenti = {};

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _service = InventarioService(_app.api);
    _caricaUtenti();
    _carica();
  }

  Future<void> _caricaUtenti() async {
    try {
      final utenti = await ChatService(_app.api).getUsersList();
      if (!mounted) return;
      setState(() {
        _nomiUtenti = {for (final u in utenti) u.codiceUtente: u.nomePortale};
      });
    } catch (_) {
      // Senza elenco utenti si mostrano i codici.
    }
  }

  String _nomeUtente(String codice) {
    final me = _app.utenteLoggato;
    if (codice == me.codiceUtente && me.nomePortale.isNotEmpty) {
      return me.nomePortale;
    }
    return _nomiUtenti[codice] ?? codice;
  }

  Future<void> _carica() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final liste = await _service.getElencoListe();
      if (!mounted) return;
      setState(() {
        _liste = liste;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Impossibile scaricare l'Elenco delle Liste";
        _loading = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Nuova lista (#newList → checkAndWriteLista → Query.writeLista).
  // -------------------------------------------------------------------------
  Future<void> _nuovaLista() async {
    final r = await invPrompt(
      context,
      'Nuova Lista Inventario',
      'Digita il Nome della Nuova Lista.\n\nIl Nome può essere quello di un '
          'Magazzino (es: MGCOLDC) o di un Vano (es: 119 o 11901)',
      ['Vano - Preciso', 'Vano - Radice', 'Magazzino', 'Annulla'],
      uppercase: true,
    );
    if (r == null || r.button == 3 || !mounted) return;
    const tipi = ['vano_preciso', 'vano_radice', 'magazzino'];
    final tipo = tipi[r.button];
    final nome = r.text.trim().toUpperCase();
    if (nome.isEmpty) {
      await invAlert(context, 'Errore', 'Non hai inserito un Nome valido per la Lista');
      return;
    }

    String res;
    try {
      res = await _service.writeLista(nome, tipo, _app.utenteLoggato.codiceUtente);
    } catch (_) {
      res = 'error';
    }
    if (!mounted) return;
    switch (res) {
      case 'error':
        await invAlert(context, 'Errore di Rete',
            'Errore di Rete o del Server: Impossibile creare la Lista');
      case 'lista_already_exists':
        await invAlert(
            context, 'Lista Esistente', 'Esiste già una Lista Aperta con questo Nome');
      case 'magazzino_not_found':
        await invAlert(context, 'Magazzino Errato',
            'Magazzino $nome non trovato.\n\nAssicurati di aver scritto il Nome del Magazzino correttamente.');
      case 'vano_preciso_not_found':
        await invAlert(context, 'Vano Preciso Errato',
            'Il Vano $nome ( Preciso ) non è stato trovato.\n\nAssicurati di aver scritto il Nome del Vano correttamente.');
      case 'vano_radice_not_found':
        await invAlert(context, 'Vano Radice Errato',
            'Il Vano $nome ( Radice ) non è stato trovato.\n\nAssicurati di aver scritto il Nome del Vano correttamente.');
      default:
        invToast(context, 'Lista $nome creata');
        _carica();
    }
  }

  // -------------------------------------------------------------------------
  // Pressione lunga: completa / riapri / elimina (cambiaStatoLista.php).
  // -------------------------------------------------------------------------
  Future<void> _azioniLista(InventarioTestata l) async {
    final completa = l.aperta ? 'Completa' : 'Riapri';
    final scelta = await invChoice(
      context,
      'Lista ${l.nomeLista}',
      l.aperta
          ? 'Vuoi Completare (archiviare) questa Lista o Eliminarla?'
          : 'Vuoi Riaprire questa Lista e continuare a modificarla o Eliminarla?',
      [completa, 'Elimina', 'Annulla'],
    );
    if (scelta == null || scelta == 2 || !mounted) return;

    int nuovoStato;
    String esito;
    String errore;
    if (scelta == 1) {
      final conferma = await invChoice(
        context,
        'Elimina Lista',
        'Sei sicuro di voler eliminare la Lista ${l.nomeLista}?',
        ['Elimina', 'Annulla'],
      );
      if (conferma != 0) return;
      nuovoStato = 9;
      esito = 'eliminata';
      errore = 'Lista non Eliminata';
    } else if (l.aperta) {
      nuovoStato = 1;
      esito = 'archiviata';
      errore = 'Lista non Archiviata';
    } else {
      nuovoStato = 0;
      esito = 'Riaperta';
      errore = 'Lista non Riaperta';
    }

    bool ok;
    try {
      ok = await _service.cambiaStatoLista(
          l.id, _app.utenteLoggato.codiceUtente, nuovoStato);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      invToast(context, 'Lista ${l.nomeLista} $esito');
      _carica();
    } else {
      await invAlert(context, 'Errore', 'Errore di Rete: $errore. Riprova');
    }
  }

  Future<void> _apriLista(InventarioTestata l) async {
    if (!l.aperta) {
      await invAlert(context, 'Impossibile Aprire',
          'Questa Lista è Completata. Tieni premuto per Riaprirla o Eliminarla');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventarioListaPage(
          service: _service,
          testata: l,
          nomiUtenti: _nomiUtenti,
        ),
      ),
    );
    if (mounted) _carica();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            icon: const Icon(Icons.refresh),
            onPressed: _carica,
          ),
          IconButton(
            tooltip: _mostraChiuse ? 'Nascondi chiuse' : 'Mostra chiuse',
            icon: Icon(_mostraChiuse ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() => _mostraChiuse = !_mostraChiuse);
              invToast(context,
                  _mostraChiuse ? 'Liste Chiuse Visualizzate' : 'Liste Chiuse Nascoste');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuovaLista,
        icon: const Icon(Icons.add),
        label: const Text('Crea'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
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
            ElevatedButton(onPressed: _carica, child: const Text('Riprova')),
          ],
        ),
      );
    }

    final aperte = _liste.where((l) => l.aperta).toList();
    final chiuse = _liste.where((l) => !l.aperta).toList();

    return RefreshIndicator(
      onRefresh: _carica,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          _header('IN CORSO'),
          if (aperte.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nessuna lista in corso',
                  style: TextStyle(color: Colors.black54)),
            ),
          for (final l in aperte) _tile(l),
          if (_mostraChiuse && chiuse.isNotEmpty) ...[
            _header('CHIUSE'),
            for (final l in chiuse) _tile(l),
          ],
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF5966A8))),
      );

  Widget _tile(InventarioTestata l) {
    final nome = _nomeUtente(l.utenteCreazione);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          l.aperta ? Icons.lock_open : Icons.lock,
          color: l.aperta ? const Color(0xFF2E7D32) : Colors.black45,
        ),
        title: Text('${l.nomeLista} ( ${l.tipoAbbreviato} )',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${l.dataCreazione} ${l.oraCreazione}'
            '${nome.isNotEmpty ? '   ·   $nome' : ''}'),
        trailing: l.aperta ? const Icon(Icons.chevron_right) : null,
        onTap: () => _apriLista(l),
        onLongPress: () => _azioniLista(l),
      ),
    );
  }
}
