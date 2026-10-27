import 'package:flutter/material.dart';

import '../core/storage/last_searched.dart';

/// Elenco delle ultime ricerche di una sezione — porting di
/// getHtmlLastSearched (Applicazione.js). Mostrato nelle pagine di ricerca
/// quando non c'è ancora un risultato; al tap rilancia la ricerca.
class LastSearchedList extends StatelessWidget {
  const LastSearchedList({
    super.key,
    required this.items,
    required this.onTap,
    this.onClear,
  });

  final List<LastSearchedItem> items;
  final ValueChanged<String> onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text('Nessuna ricerca recente',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Ricerche recenti (${items.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (onClear != null)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Svuota'),
                  onPressed: onClear,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = items[i];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.black45),
                title: Text(it.codice,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: (it.data.isEmpty && it.ora.isEmpty)
                    ? null
                    : Text([
                        if (it.data.isNotEmpty) it.data,
                        if (it.ora.isNotEmpty) it.ora,
                      ].join('  ·  ')),
                trailing: const Icon(Icons.north_west, size: 18),
                onTap: () => onTap(it.codice),
              );
            },
          ),
        ),
      ],
    );
  }
}
