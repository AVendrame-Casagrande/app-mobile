import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'accettazione_page.dart';
import 'crea_lista_page.dart';
import 'giacenza_inventario_page.dart';
import 'inventario_page.dart';
import 'mancanti_page.dart';
import 'mgaut_page.dart';
import 'movimento_page.dart';
import 'rientri_page.dart';

/// Voce del menu Magazzino.
class _Voce {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _Voce(this.label, this.icon, this.builder);
}

// Voci disponibili (id = id del bottone in PaginaPrincipale.js).
final _giacenze = _Voce('Giacenze', Icons.shelves,
    (_) => const GiacenzaInventarioPage());
final _mancanti = _Voce('Prel. Manc.', Icons.report_problem_outlined,
    (_) => const MancantiPage());
final _prelievi = _Voce('Prelievi', Icons.move_to_inbox,
    (_) => const MancantiPage(isPrelievi: true));
final _accettazione =
    _Voce('Accettazione', Icons.fact_check, (_) => const AccettazionePage());
final _movimento =
    _Voce('Mov. Singolo', Icons.swap_horiz, (_) => const MovimentoPage());
final _rientri =
    _Voce('Rientri', Icons.assignment_return, (_) => const RientriPage());
final _inventario =
    _Voce('Inventario', Icons.inventory, (_) => const InventarioPage());
final _listeAut = _Voce('Liste AUT', Icons.list_alt, (_) => const MgautPage());
final _creaLista =
    _Voce('Crea Lista', Icons.playlist_add, (_) => const CreaListaPage());

/// Restituisce le voci del menu Magazzino in base a tipo account e lingua —
/// porting dello switch di giacenze.mainPageFunctions.drawMainPage()
/// (www/scripts/Giacenze-Magazzino/Pagine/PaginaPrincipale/PaginaPrincipale.js).
List<_Voce> _vociForUser({
  required String accountType,
  required String language,
}) {
  // Utenti USA: solo Stock Mov e Inventory (che apre la Crea Lista CSUSA).
  if (language == 'E') {
    return [
      _Voce('Stock Mov', Icons.swap_horiz, (_) => const MovimentoPage()),
      _Voce('Inventory', Icons.playlist_add, (_) => const CreaListaPage()),
    ];
  }

  switch (accountType) {
    case 'Ospite':
    case 'Utente Standard':
      return [_giacenze, _creaLista];

    case 'Utente Produzione':
    case 'Utente Qualità':
      return [_giacenze, _movimento, _rientri, _listeAut, _creaLista];

    case 'Utente Magazzino':
    case 'Utente Avanzato':
      return [
        _giacenze,
        _mancanti,
        _prelievi,
        _accettazione,
        _movimento,
        _rientri,
        _inventario,
        _listeAut,
        _creaLista,
      ];

    default:
      return const [];
  }
}

/// Pagina Magazzino (sottomenu) — porting di
/// www/scripts/Giacenze-Magazzino/Pagine/PaginaPrincipale.
/// Le voci visibili dipendono dal tipo di account, come nell'originale.
class MagazzinoMenuPage extends StatelessWidget {
  const MagazzinoMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final utente = context.watch<AppState>().utenteLoggato;
    final voci = _vociForUser(
      accountType: utente.accountType,
      language: utente.language,
    );

    return Scaffold(
      appBar: AppBar(
          title: Text(utente.language == 'E' ? 'Warehouse' : 'Magazzino')),
      body: SafeArea(
        child: voci.isEmpty
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
                children: [for (final v in voci) _vociButton(context, v)],
              ),
      ),
    );
  }

  Widget _vociButton(BuildContext context, _Voce v) {
    return InkWell(
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: v.builder)),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(v.icon, size: 38, color: const Color(0xFF5966A8)),
              const SizedBox(height: 8),
              Text(v.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
