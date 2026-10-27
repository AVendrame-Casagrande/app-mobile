import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/storage/last_searched.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/firma_dialog.dart';
import '../../widgets/last_searched_list.dart';
import '../giacenze/inventario_dialogs.dart';
import '../media/photo_picker.dart';
import '../scanner/barcode_scanner_page.dart';
import 'manutenzione_service.dart';

/// Stato della sezione che resta finché l'app è aperta (ManutenzionePage).
class ManutenzioneStore {
  ManutenzioneStore._();
  static OperatoreManutenzione operatore = OperatoreManutenzione.ospite();
  static int? dataVerificaCustom; // yyyyMMdd, null = oggi
  static String filtroServizio = 'In Servizio'; // Tutti, In Servizio, Non in Servizio
  static String filtroVerifica = 'Non Verificati'; // Tutti, Non Verificati, Verificati, Verificati (tuoi)
  static final Set<String> filtroUbicazioni = {};
}

/// Pagina Produzione → Accessori (Manutenzione) — porting di
/// www/scripts/Produzione-Odl/Pagine/Manutenzione.
///
/// - Profilo: login dell'operatore (ID + password, cambio password al primo
///   accesso o a scadenza), nome e cognome.
/// - Verifica: ricerca di un accessorio o di un'ubicazione, scheda, verifica
///   (OK / Non Trovato / Rottamato) con data personalizzabile, foto.
/// - Lista: elenco accessori filtrabile e PDF firmato delle proprie verifiche.
class ManutenzionePage extends StatefulWidget {
  const ManutenzionePage({super.key});

  @override
  State<ManutenzionePage> createState() => _ManutenzionePageState();
}

class _ManutenzionePageState extends State<ManutenzionePage>
    with SingleTickerProviderStateMixin {
  static const _sezione = 'manutenzione';

  late final ManutenzioneService _service;
  late final TabController _tabs;
  final _cercaController = TextEditingController();

  bool _busy = false;

  // Verifica
  bool _loadingCerca = false;
  String? _messaggioCerca;
  AccessorioManutenzione? _accessorio;
  List<RigaAccessorio>? _accessoriUbicazione;
  String? _ubicazioneCercata; // ubicazioneDettaglioSearched
  List<LastSearchedItem> _recenti = [];

  // Lista
  bool _loadingLista = false;
  bool _listaCaricata = false;
  List<RigaAccessorio> _lista = [];
  List<UbicazioneManutenzione> _ubicazioni = [];

  OperatoreManutenzione get _op => ManutenzioneStore.operatore;

  @override
  void initState() {
    super.initState();
    _service = ManutenzioneService(context.read<AppState>().api);
    _recenti = LastSearched.get(_sezione);
    _tabs = TabController(length: 3, vsync: this, initialIndex: _op.isOspite ? 0 : 1);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && _tabs.index == 2 && !_listaCaricata) _caricaLista();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _cercaController.dispose();
    super.dispose();
  }

  void _setBusy(bool v) {
    if (mounted) setState(() => _busy = v);
  }

  /// operatoreIsEnabled(): serve il login e un profilo completo.
  bool _abilitato(String primaDi) {
    if (_op.isOspite) {
      invAlert(context, 'Accesso Richiesto', '$primaDi effettuare il login');
      return false;
    }
    if (!_op.abilitato) {
      invAlert(context, 'Profilo Incompleto',
          '$primaDi finire di compilare i tuoi dati anagrafici su profilo');
      return false;
    }
    return true;
  }

  static String _fmtData(int d) {
    final s = d.toString();
    return s.length == 8 ? '${s.substring(6, 8)}/${s.substring(4, 6)}/${s.substring(0, 4)}' : s;
  }

  static String _fmtOra(int o) {
    final s = o.toString().padLeft(6, '0');
    return '${s.substring(0, 2)}:${s.substring(2, 4)}:${s.substring(4, 6)}';
  }

  // ===========================================================================
  // Profilo / login
  // ===========================================================================

  Future<String?> _promptPassword(String title, String message, {String? Function(String)? valida}) {
    final c = TextEditingController();
    var nascosta = true;
    String? errore;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                autofocus: true,
                obscureText: nascosta,
                decoration: InputDecoration(
                  errorText: errore,
                  suffixIcon: IconButton(
                    icon: Icon(nascosta ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setD(() => nascosta = !nascosta),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Chiudi')),
            TextButton(
              onPressed: () {
                final e = valida?.call(c.text);
                if (e != null) {
                  setD(() => errore = e);
                  return;
                }
                Navigator.of(ctx).pop(c.text);
              },
              child: const Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginLogout() async {
    if (!_op.isOspite) {
      final s = await invChoice(context, 'Logout Account',
          'Vuoi effettuare il Logout da questo Account?', ['Logout', 'Chiudi']);
      if (s != 0 || !mounted) return;
      setState(() => ManutenzioneStore.operatore = OperatoreManutenzione.ospite());
      invToast(context, 'Logout Effettuato');
      return;
    }

    final r = await invPrompt(context, 'Login',
        'Inserisci il tuo Codice Operatore per effettuare il Login:', ['Login', 'Chiudi']);
    if (r == null || r.button != 0 || !mounted) return;
    final username = r.text.trim().toLowerCase();

    try {
      _setBusy(true);
      final esiste = await _service.checkUser(username);
      _setBusy(false);
      if (!mounted) return;
      if (!esiste) {
        await invAlert(context, 'ID Utente Errato', "L'ID Utente che hai inserito non esiste");
        return;
      }

      final password = await _promptPassword('Password', 'Inserisci la tua Password');
      if (password == null || !mounted) return;
      _setBusy(true);
      final op = await _service.checkPassword(username, password);
      _setBusy(false);
      if (!mounted) return;
      if (op == null) {
        await invAlert(context, 'Password Errata', 'La Password che hai inserito è errata');
        return;
      }

      // Primo accesso (password = username) o password scaduta: va cambiata.
      final oggi = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
      if (username == password || oggi > op.passwordDataScadenza) {
        final regola = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
        final nuova = await _promptPassword(
          'Cambia Password',
          'Questo è il tuo primo accesso, oppure la password è scaduta.\n\n'
              'Digita una nuova password per continuare:\n\n'
              '(La Password deve essere di minimo 8 caratteri e contenere almeno 1 numero)',
          valida: (v) => v == password
              ? 'La Password deve essere diversa'
              : regola.hasMatch(v)
                  ? null
                  : 'Password non conforme',
        );
        if (nuova == null || !mounted) return;
        _setBusy(true);
        final ok = await _service.changePassword(username, nuova);
        _setBusy(false);
        if (!mounted) return;
        if (!ok) {
          await invAlert(context, 'Errore di Rete',
              'Errore di Rete o del Server: Impossibile cambiare la password');
          return;
        }
      }

      setState(() => ManutenzioneStore.operatore = op);
      invToast(context, 'Accesso Effettuato');
    } catch (_) {
      _setBusy(false);
      if (mounted) {
        await invAlert(context, 'Errore di Rete',
            "Errore di Rete o del Server: Impossibile verificare l'utente");
      }
    }
  }

  /// Nome e cognome si modificano solo per gli operatori di tipo azienda
  /// (localmente, come nell'originale).
  Future<void> _modificaNome(bool cognome) async {
    if (_op.tipoUtente != 'azienda') return;
    final etichetta = cognome ? 'Cognome' : 'Nome';
    final attuale = cognome ? _op.cognome : _op.nome;
    final azione = attuale.isEmpty ? 'Inserisci' : 'Cambia';
    final r = await invPrompt(context, etichetta, '$azione il tuo $etichetta:', [azione, 'Chiudi'],
        initial: attuale);
    if (r == null || r.button != 0 || !mounted) return;
    setState(() {
      final v = r.text.toUpperCase().trim();
      if (cognome) {
        _op.cognome = v;
      } else {
        _op.nome = v;
      }
    });
    invToast(context, '$etichetta ${attuale.isEmpty ? 'Inserito' : 'Cambiato'}');
  }

  // ===========================================================================
  // Verifica: ricerca
  // ===========================================================================

  /// queryManuntenzioneCercaArticolo: se non è un accessorio si cerca come
  /// ubicazione di dettaglio.
  Future<void> _cerca(String codice, {bool manuale = true}) async {
    codice = codice.trim().toUpperCase();
    if (codice.isEmpty) return;
    FocusScope.of(context).unfocus();
    _cercaController.text = codice;
    if (manuale) _ubicazioneCercata = null;
    await LastSearched.add(_sezione, codice);
    setState(() {
      _loadingCerca = true;
      _messaggioCerca = null;
      _recenti = LastSearched.get(_sezione);
    });
    try {
      final a = await _service.getAccessorio(codice);
      if (!mounted) return;
      if (a != null) {
        setState(() {
          _accessorio = a;
          _accessoriUbicazione = null;
          _loadingCerca = false;
        });
        return;
      }
      final lista = await _service.getAccessoriUbicazione(codice);
      if (!mounted) return;
      setState(() {
        _accessorio = null;
        _accessoriUbicazione = lista.isEmpty ? null : lista;
        _messaggioCerca = lista.isEmpty ? 'Nessun Risultato' : null;
        _loadingCerca = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCerca = false;
        _messaggioCerca = 'Errore di Rete';
      });
    }
  }

  /// Ricarica dopo una verifica: l'accessorio o l'ubicazione da cui si veniva.
  Future<void> _ricaricaDopoVerifica(String id) async {
    final ubi = _ubicazioneCercata;
    if (ubi == null) {
      await _cerca(id, manuale: false);
      return;
    }
    try {
      final lista = await _service.getAccessoriUbicazione(ubi);
      if (!mounted) return;
      setState(() {
        _accessorio = null;
        _accessoriUbicazione = lista;
        _messaggioCerca = lista.isEmpty ? 'Nessun Risultato' : null;
      });
    } catch (_) {}
  }

  /// Pulsante "radar": scelta di un'ubicazione con accessori da verificare.
  Future<void> _sceltaUbicazione() async {
    _setBusy(true);
    List<UbicazioneManutenzione> ubi;
    try {
      ubi = await _service.getUbicazioniDaVerificare();
    } catch (_) {
      _setBusy(false);
      if (mounted) await invAlert(context, 'Errore di Rete', 'Impossibile recuperare le ubicazioni');
      return;
    }
    _setBusy(false);
    if (!mounted) return;
    final voci = <String>[];
    for (final u in ubi) {
      for (final d in u.dettagli) {
        voci.add(d == u.ubicazione ? d : '$d  (${u.ubicazione})');
      }
    }
    final s = await invSelect(context, 'Scegli Ubicazione', voci);
    if (s == null || !mounted) return;
    final dettaglio = s.split('  (').first;
    _setBusy(true);
    try {
      final lista = await _service.getAccessoriUbicazione(dettaglio);
      _setBusy(false);
      if (!mounted) return;
      if (lista.isEmpty) {
        await invAlert(context, 'Nessun Articolo',
            "L'ubicazione $dettaglio non ha nessun articolo da verificare");
        return;
      }
      setState(() {
        _accessorio = null;
        _accessoriUbicazione = lista;
        _messaggioCerca = null;
      });
    } catch (_) {
      _setBusy(false);
      if (mounted) {
        await invAlert(context, 'Errore di Rete',
            "Impossibile recuperare la lista degli Articoli dell'ubicazione $dettaglio");
      }
    }
  }

  // ===========================================================================
  // Verifica: azioni sulla scheda
  // ===========================================================================

  Future<void> _verifica() async {
    final a = _accessorio!;
    if (a.verificato) {
      final stato = switch (a.statoControllo) {
        'ok' => 'OK',
        'non_trovato' => 'Non Trovato',
        'rottamato' => 'Rottamato',
        _ => a.statoControllo,
      };
      final s = await invChoice(
        context,
        'Accessorio Verificato',
        "L'accessorio ${a.id} è già stato verificato il ${_fmtData(a.dataControllo)} alle ore "
            '${_fmtOra(a.oraControllo)} da ${a.utenteControllo} (${a.aziendaUtente})\n\nStato: $stato',
        ['Chiudi', 'Rimuovi Verifica'],
      );
      if (s != 1 || !mounted) return;
      _setBusy(true);
      try {
        final r = await _service.eliminaVerifica(a.idControllo);
        _setBusy(false);
        if (!mounted) return;
        if (r == 'deleted') {
          invToast(context, 'Verifica Rimossa');
        } else {
          await invAlert(context, 'Errore di Rete', r);
        }
      } catch (e) {
        _setBusy(false);
        if (mounted) await invAlert(context, 'Errore di Rete', '$e');
      }
      await _cerca(a.id, manuale: false);
      return;
    }

    // Avvisi mostrati prima della scelta (l'ultimo applicabile vince).
    var avviso = '';
    if (!a.fotoAggiornata) {
      avviso = "Attenzione: la foto in anagrafica deve essere aggiornata per poter verificare l'accessorio";
    }
    if (a.fotoUrl.isEmpty) {
      avviso = "Attenzione: è richiesta una foto in anagrafica per poter verificare l'accessorio";
    }
    if (!_op.abilitato) {
      avviso = "Attenzione: per poter verificare l'accessorio devi prima compilare i tuoi dati anagrafici sul profilo";
    }
    if (_op.isOspite) {
      avviso = "Attenzione: per poter verificare l'accessorio devi prima effettuare il login";
    }
    var data = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
    var testoData = '';
    if (a.inServizio && avviso.isEmpty) {
      final custom = ManutenzioneStore.dataVerificaCustom;
      testoData = custom == null
          ? "\n\nL'accessorio verrà verificato con la data di oggi: (${_fmtData(data)})"
          : "\n\nL'accessorio verrà verificato con la data impostata al: (${_fmtData(custom)})";
      if (custom != null) data = custom;
    }

    final s = await invChoice(
      context,
      'Verifica Accessorio',
      "Dichiara lo stato dell'accessorio ${a.id}${a.inServizio ? '' : ' (non in servizio)'}"
          '${avviso.isEmpty ? '' : '\n\n$avviso'}$testoData',
      ['Rottamato', 'Non Trovato', 'OK'],
    );
    if (s == null || !mounted) return;
    final verifica = const ['rottamato', 'non_trovato', 'ok'][s];

    if (!_abilitato("Prima di poter verificare l'accessorio devi prima")) return;
    if (!a.inServizio) {
      await invAlert(context, 'Non In Servizio',
          "L'accessorio ${a.id} risulta NON IN SERVIZIO e non può essere controllato");
      return;
    }
    if (a.fotoUrl.isEmpty) {
      await invAlert(context, 'Foto Richiesta',
          "È richiesta una foto in anagrafica per poter verificare l'accessorio");
      return;
    }
    if (!a.fotoAggiornata) {
      await invAlert(context, 'Foto da Aggiornare',
          "La foto in anagrafica è vecchia e deve essere aggiornata per poter verificare l'accessorio");
      return;
    }

    _setBusy(true);
    try {
      final r = await _service.inserisciVerifica(
        accessorio: a.id,
        verifica: verifica,
        utenteControllo: _op.nomeCompleto,
        azienda: _op.azienda,
        data: data,
      );
      _setBusy(false);
      if (!mounted) return;
      if (r == 'inserted') {
        invToast(context, 'Accessorio Verificato');
        _listaCaricata = false; // la lista va riscaricata
        await _ricaricaDopoVerifica(a.id);
      } else {
        await invAlert(context, 'Errore di Rete', r);
      }
    } catch (e) {
      _setBusy(false);
      if (mounted) await invAlert(context, 'Errore di Rete', '$e');
    }
  }

  Future<void> _foto() async {
    final a = _accessorio!;
    final haFoto = a.fotoUrl.isNotEmpty;
    final url = haFoto ? ManutenzioneService.urlFoto(a.fotoUrl) : '';
    final testo = haFoto
        ? "La foto dell'accessorio ${a.id} è stata scattata il ${_fmtData(a.fotoData)} alle ore "
            "${_fmtOra(a.fotoOra)}${a.fotoAggiornata ? '' : ' ( foto obsoleta )'}"
        : "Nessuna foto presente per l'accessorio ${a.id}";

    final s = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto Accessorio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (haFoto)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                child: Image.network(url, height: 200, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64)),
              ),
            const SizedBox(height: 8),
            Text(testo),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Chiudi')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(1),
              child: Text(haFoto ? 'Aggiorna' : 'Aggiungi')),
        ],
      ),
    );
    if (s != 1 || !mounted) return;
    if (!_abilitato('Prima di poter scattare una foto devi prima')) return;
    final bytes = await PhotoPicker.pick(context);
    if (bytes == null || !mounted) return;
    _setBusy(true);
    bool ok;
    try {
      ok = await _service.uploadFoto(a.id, bytes);
    } catch (_) {
      ok = false;
    }
    _setBusy(false);
    if (!mounted) return;
    if (ok) {
      invToast(context, 'Foto ${haFoto ? 'Aggiornata' : 'Caricata'}');
      await _cerca(a.id, manuale: false);
    } else {
      await invAlert(context, 'Errore di Rete o del Server', 'Foto non caricata. Riprova');
    }
  }

  Future<void> _dataVerifica() async {
    final custom = ManutenzioneStore.dataVerificaCustom;
    final s = await invChoice(
      context,
      'Data Verifica',
      'Imposta una data di verifica personalizzata. Tutte le verifiche saranno registrate in '
          'questa data.\n\nData Impostata: ${custom == null ? 'OGGI' : _fmtData(custom)}',
      ['Chiudi', 'Oggi', 'Cambia'],
    );
    if (!mounted || s == null || s == 0) return;
    if (s == 1) {
      setState(() => ManutenzioneStore.dataVerificaCustom = null);
      invToast(context, 'Data Cambiata');
      return;
    }
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final v = int.parse(DateFormat('yyyyMMdd').format(d));
    final oggi = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
    setState(() => ManutenzioneStore.dataVerificaCustom = v == oggi ? null : v);
    invToast(context, 'Data Cambiata');
  }

  /// La modifica dell'anagrafica e la creazione di accessori usano script
  /// condivisi del PortaleWeb non presenti nell'app.
  void _soloPortale(String primaDi) {
    if (!_abilitato(primaDi)) return;
    invAlert(context, 'Funzione non disponibile',
        "Questa operazione si fa dal PortaleWeb (Manutenzione accessori sollevamento): "
        "non è ancora disponibile nell'app.");
  }

  // ===========================================================================
  // Lista
  // ===========================================================================

  Future<void> _caricaLista() async {
    setState(() {
      _loadingLista = true;
      _listaCaricata = true;
    });
    try {
      final (lista, ubi) = await _service.getLista();
      if (!mounted) return;
      setState(() {
        _lista = lista;
        _ubicazioni = ubi;
        _loadingLista = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLista = false;
        _listaCaricata = false;
      });
      await invAlert(context, 'Errore di Rete', 'Impossibile scaricare la lista degli accessori');
    }
  }

  List<RigaAccessorio> get _listaFiltrata => _lista.where((r) {
        switch (ManutenzioneStore.filtroServizio) {
          case 'In Servizio':
            if (!r.inServizio) return false;
          case 'Non in Servizio':
            if (r.inServizio) return false;
        }
        switch (ManutenzioneStore.filtroVerifica) {
          case 'Verificati':
            if (!r.verificato) return false;
          case 'Verificati (tuoi)':
            if (!r.verificato || r.utenteControllo != _op.nomeCompleto) return false;
          case 'Non Verificati':
            if (r.verificato) return false;
        }
        final f = ManutenzioneStore.filtroUbicazioni;
        return f.isEmpty || f.contains(r.ubicazioneDettaglio);
      }).toList();

  Future<void> _filtroStato() async {
    var servizio = ManutenzioneStore.filtroServizio;
    var verifica = ManutenzioneStore.filtroVerifica;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Visualizza Accessori per Stato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Servizio', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 6, children: [
                for (final v in const ['Tutti', 'In Servizio', 'Non in Servizio'])
                  ChoiceChip(
                      label: Text(v),
                      selected: servizio == v,
                      onSelected: (_) => setD(() => servizio = v)),
              ]),
              const SizedBox(height: 12),
              const Text('Verifica', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 6, children: [
                for (final v in const ['Tutti', 'Non Verificati', 'Verificati', 'Verificati (tuoi)'])
                  ChoiceChip(
                      label: Text(v),
                      selected: verifica == v,
                      onSelected: (_) => setD(() => verifica = v)),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Visualizza')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      ManutenzioneStore.filtroServizio = servizio;
      ManutenzioneStore.filtroVerifica = verifica;
    });
  }

  Future<void> _filtroUbicazioni() async {
    final sel = Set<String>.of(ManutenzioneStore.filtroUbicazioni);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            builder: (_, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Filtra per Ubicazione',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                for (final u in _ubicazioni) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(u.ubicazione, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    for (final d in u.dettagli)
                      FilterChip(
                        label: Text(d),
                        selected: sel.contains(d),
                        onSelected: (on) => setS(() => on ? sel.add(d) : sel.remove(d)),
                      ),
                  ]),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  TextButton(onPressed: () => setS(sel.clear), child: const Text('Azzera filtri')),
                  const Spacer(),
                  ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Applica')),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => ManutenzioneStore.filtroUbicazioni
      ..clear()
      ..addAll(sel));
  }

  void _apriDaLista(RigaAccessorio r) {
    _tabs.animateTo(1);
    _cerca(r.id);
  }

  /// PDF delle proprie verifiche (oggi o tutte) firmato, inviato via email.
  Future<void> _firmaVerifiche() async {
    if (!_abilitato("Prima di poter firmare l'elenco delle tue verifiche devi prima")) return;
    final r = await showFirmaDialog(
      context,
      title: 'Firma Verifiche',
      message: "Firma e conferma l'elenco delle TUE verifiche effettuate.\n\n"
          'Puoi scegliere se firmare quelle di OGGI oppure TUTTE.\n\n'
          'Viene richiesta una firma digitale qui sotto:',
      buttons: ['TUTTE', 'OGGI'],
    );
    if (r == null || !mounted) return;
    if (r.dataUrl.isEmpty) {
      await invAlert(context, 'Firma Richiesta',
          "Devi effettuare la firma digitale prima di poter scaricare l'elenco delle verifiche");
      return;
    }

    _setBusy(true);
    try {
      final (urlFirma, verificate) = await _service.getVerificate(
        utenteControllo: _op.nomeCompleto,
        firmaDataUrl: r.dataUrl,
        dataQuery: r.button == 1 ? 'oggi' : 'tutte',
      );
      final now = DateTime.now();
      final filename =
          'Verifica_${DateFormat('yyyyMMdd').format(now)}_${DateFormat('HHmmss').format(now)}.pdf';
      final (url, systemUrl) = await _service.creaPdf(_htmlPdf(urlFirma, verificate), filename);
      _setBusy(false);
      if (!mounted) return;
      if (!url.startsWith('http')) {
        await invAlert(context, 'Errore di Rete', 'Errore di Sistema');
        return;
      }
      _service.inviaEmailVerifiche(_op.nomeCompleto, _op.azienda, systemUrl).ignore();
      final s = await invChoice(
        context,
        'Verifiche Confermate',
        'Il PDF delle tue verifiche firmate è stato generato con successo, ed è stato inviato '
            'via e-mail a Massimo Gerarduz',
        ['Chiudi', 'Visualizza'],
      );
      if (s == 1) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _setBusy(false);
      if (mounted) await invAlert(context, 'Errore di Rete', '$e');
    }
  }

  /// Porting di getHtmlVerificaPDF().
  String _htmlPdf(String firma, List<Map<String, dynamic>> lista) {
    const px = 'font-size: 12px';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tbody = StringBuffer();
    for (final r in lista) {
      final data = _fmtData(int.tryParse('${r['data_controllo']}') ?? 0);
      final url =
          'http://app.casagrandegroup.local/mobile/server/storage/manutenzione/accessori/${r['foto_url']}.jpg?$ts';
      tbody.write('<tr class="details">'
          '<td style="width: 15%;$px;"><b>${r['id']}</b></td>'
          '<td style="width: 27%;$px;">${r['attrezzatura']}</td>'
          '<td style="width: 16%;$px;text-transform: capitalize;">${r['stato_controllo']}</td>'
          '<td style="width: 10%;$px;">$data</td>'
          '<td style="width: 27%;$px">${r['note']}</td>'
          '<td style="width: 5%;$px"><a href="$url">Link</a></td>'
          '</tr>');
    }
    final nome = _op.nomeCompleto;
    return '<div class="invoice-box for_pdf"><table cellpadding="0" cellspacing="0"><tr class="information">'
        '<td class="title" style="width: 15%;"><img src="http://app.casagrandegroup.local/mobile/server/queryDesktop/modifiche_tecniche/cs_logo.png" style="width:100%; max-width:100px;margin-top: 1%;"></td>'
        '<td style="width:40%;text-align: left;margin-left: 8%;"><b>Verifica Accessori Casagrande</b><br><br>Elenco degli accessori verificati da: <u>$nome</u></td>'
        '<td style="width: 37%; text-align: right;">Operatore: <b>$nome</b><br>Azienda: <b>${_op.azienda}</b><br><br>Data: <i>${DateFormat('dd/MM/yyyy').format(DateTime.now())}</i></td>'
        '</tr></table><br>'
        '<table style="border-collapse: collapse; border: 1px solid #555;"><tr class="heading">'
        '<td style="width: 15%;">Accessorio</td><td style="width: 27%;">Descrizione</td>'
        '<td style="width: 16%;">Valutazione</td><td style="width:10%;text-align: center">Data</td>'
        '<td style="width:27%;">Note</td><td style="width:5%;">Foto</td></tr>$tbody</table><br>'
        '<table cellpadding="0" cellspacing="0"><tr class="information"><td class="title"><b>Firma:</b></td></tr>'
        '<tr class="information"><td class="title"><img src="$firma" style="max-width:200px;"></td></tr></table></div>';
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessori'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'PROFILO'), Tab(text: 'VERIFICA'), Tab(text: 'LISTA')],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(controller: _tabs, children: [_tabProfilo(), _tabVerifica(), _tabLista()]),
          if (_busy)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator(color: AppColors.spinner)),
            ),
        ],
      ),
    );
  }

  Widget _riga(String etichetta, Widget valore, {VoidCallback? onTap, Widget? azione}) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          title: Text(etichetta, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: valore,
          trailing: azione,
          onTap: onTap,
        ),
      );

  Widget _tabProfilo() {
    const rosso = TextStyle(color: Color(0xFF8B0000));
    final op = _op;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _riga(
          'ID Operatore',
          Text(op.isOspite ? '-' : op.username),
          azione: TextButton.icon(
            icon: Icon(op.isOspite ? Icons.login : Icons.logout),
            label: Text(op.isOspite ? 'Login' : 'Logout'),
            onPressed: _busy ? null : _loginLogout,
          ),
        ),
        if (!op.isOspite) ...[
          _riga('Nome',
              Text(op.nome.isEmpty ? 'Richiesto' : op.nome.toLowerCase(),
                  style: op.nome.isEmpty ? rosso : null),
              onTap: () => _modificaNome(false)),
          _riga('Cognome',
              Text(op.cognome.isEmpty ? 'Richiesto' : op.cognome.toLowerCase(),
                  style: op.cognome.isEmpty ? rosso : null),
              onTap: () => _modificaNome(true)),
          _riga('Azienda', Text(op.azienda)),
        ],
        _riga(
          'Stato',
          Text(
            op.isOspite
                ? 'Login Richiesto'
                : op.abilitato
                    ? 'Abilitato'
                    : 'Dati Anagrafici Mancanti',
            style: TextStyle(
                color: !op.isOspite && op.abilitato
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF8B0000)),
          ),
          onTap: !op.isOspite && !op.abilitato
              ? () => invAlert(context, 'Dati Anagrafici Mancanti',
                  'Inserisci i Dati Anagrafici mancanti per essere abilitato alla Verifica e alla Gestione degli Accessori.')
              : null,
        ),
      ],
    );
  }

  Widget _tabVerifica() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Ubicazioni da verificare',
                icon: const Icon(Icons.radar),
                onPressed: _busy ? null : _sceltaUbicazione,
              ),
              Expanded(
                child: TextField(
                  controller: _cercaController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => _cerca(v),
                  decoration: InputDecoration(
                    hintText: 'Accessorio / Ubicazione',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final c = await BarcodeScannerPage.scan(context, titolo: 'Inquadra accessorio');
                        if (c != null && mounted) _cerca(c);
                      },
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => _cerca(_cercaController.text), child: const Text('Cerca')),
            ],
          ),
        ),
        Expanded(child: _corpoVerifica()),
      ],
    );
  }

  Widget _corpoVerifica() {
    if (_loadingCerca) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_messaggioCerca != null) {
      return Center(child: Text(_messaggioCerca!, style: const TextStyle(fontSize: 18)));
    }
    final lista = _accessoriUbicazione;
    if (lista != null) {
      return ListView.separated(
        itemCount: lista.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = lista[i];
          return ListTile(
            title: Text(r.id, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(r.attrezzatura.length > 50 ? r.attrezzatura.substring(0, 50) : r.attrezzatura),
            trailing: Text('${r.ubicazioneDettaglio}\n${r.ubicazione}', textAlign: TextAlign.right),
            onTap: () {
              _ubicazioneCercata = r.ubicazioneDettaglio;
              _cerca(r.id, manuale: false);
            },
          );
        },
      );
    }
    final a = _accessorio;
    if (a == null) {
      return LastSearchedList(
        items: _recenti,
        onTap: (c) => _cerca(c),
        onClear: _recenti.isEmpty
            ? null
            : () async {
                await LastSearched.clear(_sezione);
                if (!mounted) return;
                setState(() => _recenti = LastSearched.get(_sezione));
              },
      );
    }
    return _scheda(a);
  }

  Widget _scheda(AccessorioManutenzione a) {
    const si = Text('SI', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold));
    const no = Text('NO', style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold));
    void modifica() => _soloPortale('Prima di poter modificare un accessorio devi prima');

    Widget campo(String etichetta, String valore, {Color? colore}) => ListTile(
          dense: true,
          title: Text(etichetta),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(valore,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w600, color: colore)),
          ),
          onTap: modifica,
        );

    final dettaglio = a.ubicazione == a.ubicazioneDettaglio ? '' : a.ubicazioneDettaglio;
    final custom = ManutenzioneStore.dataVerificaCustom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              ListTile(
                title: Text(a.attrezzatura,
                    textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${a.id}\n${a.ubicazione.toLowerCase()}'
                    '${dettaglio.isEmpty ? '' : ' · ${dettaglio.toLowerCase()}'}',
                    textAlign: TextAlign.center),
                onTap: modifica,
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                title: const Text('In Servizio  |  Verificato'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  a.inServizio ? si : no,
                  const Text('  |  '),
                  a.verificato ? si : no,
                ]),
                onTap: modifica,
              ),
              campo('Matr. Costr.', a['matric_costr']),
              campo('Tiranti', a['tiranti']),
              campo('N° accorciatori', a['accorc']),
              campo('Ø o Larghezza', a['larghezza']),
              campo('Lunghezza (mm)', a['lunghezza_mm']),
              campo('Terminali', a['terminali']),
              campo('Portata Punz.', a['portata_punzon']),
              campo('Grado', a['grado']),
              campo('Interno', a['int']),
              campo('Assegnato', a['assegnato']),
              campo('Rif. Cons.', a['riferimento_consegna']),
              campo('Note Rspp', a['ultimo_ritrovamento'].toLowerCase(), colore: const Color(0xFF8B0000)),
              ListTile(
                title: Text(a.note.isEmpty ? 'Nessuna Nota' : a.note.toLowerCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
                onTap: modifica,
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.event,
                        color: custom == null ? Colors.grey : Colors.purple),
                    label: Text(custom == null ? 'Oggi' : _fmtData(custom)),
                    onPressed: _dataVerifica,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(a.fotoUrl.isEmpty ? Icons.photo_camera : Icons.photo_library,
                        color: a.fotoUrl.isNotEmpty && !a.fotoAggiornata ? Colors.red : null),
                    label: const Text('Foto'),
                    onPressed: _busy ? null : _foto,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Verifica'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: a.verificato || !a.inServizio
                          ? Colors.grey
                          : AppColors.casagrandeDark,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _busy ? null : _verifica,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabLista() {
    if (_loadingLista) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spinner));
    }
    final lista = _listaFiltrata;
    final filtroStatoAttivo =
        ManutenzioneStore.filtroServizio != 'Tutti' || ManutenzioneStore.filtroVerifica != 'Tutti';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Accessori ( ${lista.length} )',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(tooltip: 'Aggiorna', icon: const Icon(Icons.refresh), onPressed: _caricaLista),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = lista[i];
              final stessa = r.ubicazioneDettaglio == r.ubicazione;
              final att = r.attrezzatura.toLowerCase();
              final icona = !r.verificato
                  ? ''
                  : switch (r.statoControllo) {
                      'ok' => '✔️',
                      'rottamato' => '❌',
                      'non_trovato' => '❓',
                      _ => '',
                    };
              return ListTile(
                title: Text(r.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(att.length > 22 ? att.substring(0, 22) : att),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stessa
                          ? r.ubicazione.toLowerCase()
                          : '${r.ubicazioneDettaglio.toLowerCase()}\n${r.ubicazione.toLowerCase()}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 24, child: Text(icona)),
                  ],
                ),
                onTap: () => _apriDaLista(r),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Stato',
                  icon: Icon(Icons.visibility, color: filtroStatoAttivo ? Colors.amber.shade800 : null),
                  onPressed: _filtroStato,
                ),
                IconButton(
                  tooltip: 'Ubicazioni',
                  icon: Icon(Icons.filter_alt,
                      color: ManutenzioneStore.filtroUbicazioni.isNotEmpty ? Colors.amber.shade800 : null),
                  onPressed: _ubicazioni.isEmpty ? null : _filtroUbicazioni,
                ),
                IconButton(
                  tooltip: 'Nuovo accessorio',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _soloPortale('Prima di poter creare un nuovo accessorio devi prima'),
                ),
                IconButton(
                  tooltip: 'Firma verifiche (PDF)',
                  icon: const Icon(Icons.draw),
                  onPressed: _busy ? null : _firmaVerifiche,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
