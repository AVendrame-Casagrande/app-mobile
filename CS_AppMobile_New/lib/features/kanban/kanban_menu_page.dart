import 'package:flutter/material.dart';

import 'kanban_articoli_page.dart';
import 'rifornimento_page.dart';
import 'scaffali_page.dart';

/// Voce del menu Kanban.
class _Voce {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _Voce(this.label, this.icon, this.builder);
}

/// Pagina Kanban (sottomenu) — porting di
/// www/scripts/Kanban/Pagine/PaginaPrincipale.
/// Tre sezioni: Articoli, Rifornimento, Scaffali.
class KanbanMenuPage extends StatelessWidget {
  const KanbanMenuPage({super.key});

  static final _voci = <_Voce>[
    _Voce('Articoli', Icons.search, (_) => const KanbanArticoliPage()),
    _Voce('Rifornimento', Icons.local_shipping, (_) => const RifornimentoPage()),
    _Voce('Scaffali', Icons.shelves, (_) => const ScaffaliPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kanban')),
      body: SafeArea(
        child: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [for (final v in _voci) _button(context, v)],
        ),
      ),
    );
  }

  Widget _button(BuildContext context, _Voce v) {
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
              Icon(v.icon, size: 40, color: const Color(0xFF5966A8)),
              const SizedBox(height: 8),
              Text(v.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
