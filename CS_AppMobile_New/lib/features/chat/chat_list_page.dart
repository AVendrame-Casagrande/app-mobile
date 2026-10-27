import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';
import '../../models/utente.dart';
import '../../state/app_state.dart';
import 'chat_controller.dart';
import 'chat_conversation_page.dart';
import 'chat_service.dart';

/// Pagina Chat → elenco conversazioni — porting di
/// www/scripts/Chat/Chat.js (drawChatPage).
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return ChangeNotifierProvider(
      create: (_) => ChatController(
        service: ChatService(app.api),
        utenteLoggato: app.utenteLoggato,
      )..caricaTutto(),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ChatController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      floatingActionButton: FloatingActionButton(
        onPressed: ctrl.loading ? null : () => _nuovaChat(context, ctrl),
        backgroundColor: AppColors.casagrandeDark,
        child: const Icon(Icons.add_comment),
      ),
      body: _body(context, ctrl),
    );
  }

  Widget _body(BuildContext context, ChatController ctrl) {
    if (ctrl.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (ctrl.error != null && ctrl.conversazioni.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(ctrl.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: ctrl.caricaTutto,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }
    if (ctrl.conversazioni.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.black38),
            SizedBox(height: 12),
            Text('Nessuna conversazione.\nTocca + per iniziarne una.',
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: ctrl.conversazioni.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _tile(context, ctrl, ctrl.conversazioni[i]),
    );
  }

  Widget _tile(BuildContext context, ChatController ctrl, Conversazione c) {
    final nonLetti = c.nonLetti;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: c.isGruppo
            ? AppColors.casagrandeDark
            : const Color(0xFF5966A8),
        backgroundImage:
            c.immagineUrl.isNotEmpty ? NetworkImage(c.immagineUrl) : null,
        child: c.immagineUrl.isEmpty
            ? Icon(c.isGruppo ? Icons.groups : Icons.person,
                color: Colors.white)
            : null,
      ),
      title: Text(c.utente.nomeUtente,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(c.anteprima,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: nonLetti > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFC62828),
                shape: BoxShape.circle,
              ),
              child: Text('$nonLetti',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => _apriConversazione(context, ctrl, c),
    );
  }

  void _apriConversazione(
      BuildContext context, ChatController ctrl, Conversazione c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: ctrl,
          child: ChatConversationPage(codiceUtente: c.utente.codiceUtente),
        ),
      ),
    );
  }

  Future<void> _nuovaChat(BuildContext context, ChatController ctrl) async {
    final utente = await showModalBottomSheet<Utente>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelezionaUtenteSheet(utenti: ctrl.utentiTotali),
    );
    if (utente == null || !context.mounted) return;
    final conv = ctrl.apriOCreaConversazione(utente);
    if (!context.mounted) return;
    _apriConversazione(context, ctrl, conv);
  }
}

/// Bottom sheet per scegliere un utente/gruppo con cui iniziare una chat.
class _SelezionaUtenteSheet extends StatefulWidget {
  const _SelezionaUtenteSheet({required this.utenti});
  final List<Utente> utenti;

  @override
  State<_SelezionaUtenteSheet> createState() => _SelezionaUtenteSheetState();
}

class _SelezionaUtenteSheetState extends State<_SelezionaUtenteSheet> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final q = _filtro.trim().toLowerCase();
    final lista = widget.utenti
        .where((u) =>
            q.isEmpty ||
            u.nomeUtente.toLowerCase().contains(q) ||
            u.codiceUtente.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.nomeUtente.toLowerCase().compareTo(
            b.nomeUtente.toLowerCase(),
          ));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scroll) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Nuova chat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => setState(() => _filtro = v),
              decoration: const InputDecoration(
                hintText: 'Cerca utente o gruppo',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final u = lista[i];
                final isGruppo = u.accountType == 'Group';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGruppo
                        ? AppColors.casagrandeDark
                        : const Color(0xFF5966A8),
                    child: Icon(isGruppo ? Icons.groups : Icons.person,
                        color: Colors.white),
                  ),
                  title: Text(u.nomeUtente),
                  subtitle: Text(u.codiceUtente),
                  onTap: () => Navigator.of(context).pop(u),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
