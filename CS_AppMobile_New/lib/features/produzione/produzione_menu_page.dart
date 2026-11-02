import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../state/app_state.dart';
import '../giacenze/cambio_odl_page.dart';
import 'impegno_odl_page.dart';
import 'lista_precarico_page.dart';
import 'manutenzione_page.dart';
import 'prestazioni.dart';
import 'pallinatura.dart';
import 'qualita_page.dart';
import 'situazione_odl_page.dart';

/// Sezioni del menu Produzione (id = id del bottone in PaginaPrincipale.js).
enum _Sezione {
  situazioneOdl('Situazione ODL', Icons.account_tree),
  cambioOdl('Cambio ODL', Icons.sync_alt),
  impegnoOdl('Impegno ODL', Icons.assignment_turned_in),
  qualita('Qualità', Icons.verified),
  listaPrecarico('Pre-Carico', Icons.playlist_add_check),
  // Accessori (Manutenzione): nascosta, i servizi PHP non esistono più sul server.
  manutenzione('Accessori', Icons.build),
  pallinatura('Pallinatura', Icons.photo_camera),
  prestazioni('Prestazioni', Icons.speed);

  const _Sezione(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Sezioni che per l'Utente Produzione partono disabilitate e si sbloccano
/// con checkPermessiSezioniProduzione.php.
const _sezioniConPermesso = {_Sezione.listaPrecarico, _Sezione.pallinatura};

/// Voci del menu Produzione in base al tipo account — porting dello switch di
/// produzione.mainPageFunctions.drawMainPage()
/// (www/scripts/Produzione-Odl/Pagine/PaginaPrincipale/PaginaPrincipale.js).
List<_Sezione> _sezioniForUser(String accountType) {
  switch (accountType) {
    case 'Ospite':
    case 'Utente Standard':
      return const [_Sezione.situazioneOdl, _Sezione.prestazioni];

    case 'Utente Qualità':
      return const [
        _Sezione.situazioneOdl,
        _Sezione.prestazioni,
        _Sezione.qualita,
      ];

    case 'Utente Magazzino':
      return const [
        _Sezione.situazioneOdl,
        _Sezione.cambioOdl,
        _Sezione.prestazioni,
        _Sezione.qualita,
      ];

    case 'Utente Produzione':
      return const [
        _Sezione.situazioneOdl,
        _Sezione.cambioOdl,
        _Sezione.impegnoOdl,
        _Sezione.listaPrecarico,
        _Sezione.prestazioni,
        _Sezione.pallinatura,
      ];

    case 'Utente Avanzato':
      return const [
        _Sezione.situazioneOdl,
        _Sezione.cambioOdl,
        _Sezione.impegnoOdl,
        _Sezione.qualita,
        _Sezione.listaPrecarico,
        _Sezione.prestazioni,
        _Sezione.pallinatura,
      ];

    default:
      return const [];
  }
}

/// Pagina Produzione (sottomenu) — porting di
/// www/scripts/Produzione-Odl/Pagine/PaginaPrincipale.
class ProduzioneMenuPage extends StatefulWidget {
  const ProduzioneMenuPage({super.key});

  @override
  State<ProduzioneMenuPage> createState() => _ProduzioneMenuPageState();
}

class _ProduzioneMenuPageState extends State<ProduzioneMenuPage> {
  /// Sezioni sbloccate dal server per l'Utente Produzione.
  final Set<_Sezione> _sbloccate = {};

  @override
  void initState() {
    super.initState();
    final utente = context.read<AppState>().utenteLoggato;
    if (utente.accountType == 'Utente Produzione') {
      _checkPermessi(utente.codiceUtente);
    }
  }

  /// POST /produzione/checkPermessiSezioniProduzione.php {utente}
  /// → {pre_carico, pallinatura}. In caso di errore le voci restano bloccate.
  Future<void> _checkPermessi(String codiceUtente) async {
    try {
      final res = await context.read<AppState>().api.postJson(
        '${AppConfig.produzioneUrl}/checkPermessiSezioniProduzione',
        data: {'utente': codiceUtente},
      );
      if (!mounted || res is! Map) return;
      setState(() {
        if (_isTrue(res['pre_carico'])) _sbloccate.add(_Sezione.listaPrecarico);
        if (_isTrue(res['pallinatura'])) _sbloccate.add(_Sezione.pallinatura);
      });
    } catch (_) {
      // Come l'originale: nessun messaggio, le voci restano disabilitate.
    }
  }

  static bool _isTrue(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';

  bool _isAbilitata(String accountType, _Sezione s) {
    if (accountType != 'Utente Produzione') return true;
    return !_sezioniConPermesso.contains(s) || _sbloccate.contains(s);
  }

  @override
  Widget build(BuildContext context) {
    final accountType = context.watch<AppState>().utenteLoggato.accountType;
    final sezioni = _sezioniForUser(accountType);

    return Scaffold(
      appBar: AppBar(title: const Text('Produzione')),
      body: SafeArea(
        child: sezioni.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Nessuna sezione disponibile per il tuo tipo di account.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  for (final s in sezioni)
                    _button(context, s, _isAbilitata(accountType, s)),
                ],
              ),
      ),
    );
  }

  Widget _button(BuildContext context, _Sezione s, bool abilitata) {
    return InkWell(
      onTap: abilitata ? () => _open(context, s) : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: abilitata ? 1 : 0.4,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(s.icon,
                    size: 38,
                    color: abilitata ? const Color(0xFF5966A8) : Colors.grey),
                const SizedBox(height: 8),
                Text(s.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, _Sezione s) {
    final Widget page;
    switch (s) {
      // Pallinatura e Prestazioni sono popup, non pagine.
      case _Sezione.pallinatura:
        apriPallinatura(context);
        return;
      case _Sezione.prestazioni:
        apriPrestazioni(context);
        return;
      case _Sezione.situazioneOdl:
        page = const SituazioneOdlPage();
      case _Sezione.cambioOdl:
        page = const CambioOdlPage();
      case _Sezione.impegnoOdl:
        page = const ImpegnoOdlPage();
      case _Sezione.listaPrecarico:
        page = const ListaPrecaricoPage();
      case _Sezione.qualita:
        page = const QualitaPage();
      case _Sezione.manutenzione:
        page = const ManutenzionePage();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
