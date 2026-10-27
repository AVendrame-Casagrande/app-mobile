import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';

/// Un documento PDF della Guida.
class _Documento {
  final String file; // nome file senza estensione
  final String label;
  final IconData icon;
  const _Documento(this.file, this.label, this.icon);
}

/// Pagina Guida → Documenti — porting di
/// www/scripts/Guida/Pagine/PaginaPrincipale.
/// Elenco di PDF aperti esternamente (come InAppBrowser '_system').
class GuidaPage extends StatelessWidget {
  const GuidaPage({super.key});

  static const _documenti = <_Documento>[
    _Documento('tutorial', 'Guida App', Icons.menu_book),
    _Documento('layout', 'Layout', Icons.explore),
    _Documento('gestione_magazzini', 'Gest. Magazzini', Icons.warehouse),
    _Documento('acquisto_materiali', 'Acquisto', Icons.shopping_cart),
    _Documento('accettazione_materiali', 'Accettazione', Icons.fact_check),
    _Documento('imballi_merce', 'Imballi', Icons.inventory_2),
    _Documento('attribuzione_materiali', 'Attr. Materiali', Icons.assignment),
  ];

  Future<void> _apri(BuildContext context, _Documento doc) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse('${AppConfig.guidaUrl}/${doc.file}.pdf?$ts');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile aprire ${doc.label}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documenti')),
      body: SafeArea(
        child: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            for (final doc in _documenti)
              _docButton(context, doc),
          ],
        ),
      ),
    );
  }

  Widget _docButton(BuildContext context, _Documento doc) {
    return InkWell(
      onTap: () => _apri(context, doc),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(doc.icon, size: 40, color: const Color(0xFF5966A8)),
              const SizedBox(height: 8),
              Text(doc.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
