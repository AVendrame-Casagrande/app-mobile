import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/translator.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/block_button.dart';
import '../profilo/profilo_page.dart';
import '../avvisi/avvisi_page.dart';
import '../situazione_odv/situazione_odv_page.dart';
import '../aggiorna/aggiorna_page.dart';
import '../giacenze/cerca_page.dart';
import '../giacenze/magazzino_menu_page.dart';
import '../kanban/kanban_menu_page.dart';
import '../produzione/produzione_menu_page.dart';
import '../guida/guida_page.dart';
import '../fotoarm/foto_arm_page.dart';
import '../chat/chat_list_page.dart';
import '../stampa/stampa_page.dart';
import 'home_modules.dart';

/// Pagina Principale — porting di www/scripts/PaginaPrincipale.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final utente = app.utenteLoggato;

    final modules = modulesForUser(
      accountType: utente.accountType,
      language: utente.language,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casagrande'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                utente.isOspite ? 'Ospite' : utente.nomeUtente,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
            children: [
              for (final m in modules)
                BlockButton(
                  label: Translator.translate(m.label),
                  iconAsset: m.iconAsset,
                  badge: m == AppModule.aggiorna
                      ? Text(
                          app.webClientVersion,
                          style: const TextStyle(
                            color: Color(0xFFADFF2F), // greenyellow
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        )
                      : null,
                  onTap: () => _openModule(context, m),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openModule(BuildContext context, AppModule module) {
    switch (module) {
      case AppModule.profilo:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfiloPage()),
        );
        break;
      case AppModule.attivita:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AvvisiPage()),
        );
        break;
      case AppModule.situazioneOdv:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SituazioneOdvPage()),
        );
        break;
      case AppModule.aggiorna:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AggiornaPage()),
        );
        break;
      case AppModule.cerca:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CercaPage()),
        );
        break;
      case AppModule.kanban:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KanbanMenuPage()),
        );
        break;
      case AppModule.produzione:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProduzioneMenuPage()),
        );
        break;
      case AppModule.guida:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GuidaPage()),
        );
        break;
      case AppModule.magazzino:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MagazzinoMenuPage()),
        );
        break;
      case AppModule.fotoarm:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FotoArmPage()),
        );
        break;
      case AppModule.chat:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatListPage()),
        );
        break;
      case AppModule.stampa:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StampaPage()),
        );
        break;
    }
  }
}

/// Spinner standard Casagrande (colore rgba(89,102,168)).
class CasagrandeSpinner extends StatelessWidget {
  const CasagrandeSpinner({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          color: AppColors.spinner,
          strokeWidth: 5,
        ),
      ),
    );
  }
}
