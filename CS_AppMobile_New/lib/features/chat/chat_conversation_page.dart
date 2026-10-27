import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';
import '../media/photo_picker.dart';
import 'chat_controller.dart';

/// Pagina di una singola conversazione — porting di drawSingleChat.
class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({super.key, required this.codiceUtente});

  final String codiceUtente;

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _segnatiLetti = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _segnaLetti();
      _scrollInFondo(animato: false);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _segnaLetti() {
    if (_segnatiLetti) return;
    _segnatiLetti = true;
    final ctrl = context.read<ChatController>();
    final conv = ctrl.conversazioneCon(widget.codiceUtente);
    if (conv != null) ctrl.segnaLetti(conv);
  }

  void _scrollInFondo({bool animato = true}) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position.maxScrollExtent;
    if (animato) {
      _scroll.animateTo(pos,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(pos);
    }
  }

  Future<void> _invia() async {
    final testo = _input.text;
    if (testo.trim().isEmpty) return;
    final ctrl = context.read<ChatController>();
    final conv = ctrl.conversazioneCon(widget.codiceUtente);
    if (conv == null) return;
    _input.clear();
    await ctrl.inviaMessaggio(conv, testo);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollInFondo());
  }

  Future<void> _inviaFoto() async {
    final ctrl = context.read<ChatController>();
    final conv = ctrl.conversazioneCon(widget.codiceUtente);
    if (conv == null) return;
    final bytes = await PhotoPicker.pick(context);
    if (bytes == null || !mounted) return;
    final ok = await ctrl.inviaFoto(conv, bytes);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invio foto non riuscito')),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollInFondo());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ChatController>();
    final conv = ctrl.conversazioneCon(widget.codiceUtente);

    // Auto-scroll quando arrivano nuovi messaggi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients &&
          _scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 120) {
        _scrollInFondo();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(conv?.utente.nomeUtente ?? widget.codiceUtente),
      ),
      body: Column(
        children: [
          Expanded(
            child: conv == null || conv.messaggi.isEmpty
                ? const Center(
                    child: Text('Nessun messaggio. Scrivi qualcosa!',
                        style: TextStyle(color: Colors.black54)),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: conv.messaggi.length,
                    itemBuilder: (_, i) =>
                        _bubble(context, ctrl, conv, conv.messaggi[i]),
                  ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, ChatController ctrl, Conversazione conv,
      ChatMessage m) {
    final inviato = m.tipo == 'inviato';
    final align = inviato ? Alignment.centerRight : Alignment.centerLeft;
    final color =
        inviato ? const Color(0xFFDCEBFA) : const Color(0xFFF1F1F1);

    return Align(
      alignment: align,
      child: GestureDetector(
        onLongPress:
            inviato ? () => _menuMessaggio(context, ctrl, conv, m) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conv.isGruppo && !inviato && m.senderidGroup.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(m.senderidGroup,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5966A8))),
                ),
              if (m.isFoto && m.fotoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(m.fotoUrl,
                      errorBuilder: (_, __, ___) => const Text('📷 Foto')),
                )
              else
                Text(_pulisci(m.messaggio)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_oraFmt(m.oraInvio),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black45)),
                  if (inviato) ...[
                    const SizedBox(width: 4),
                    Icon(
                      m.letto ? Icons.done_all : Icons.done,
                      size: 14,
                      color: m.letto ? const Color(0xFF3949AB) : Colors.black45,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _menuMessaggio(BuildContext context, ChatController ctrl,
      Conversazione conv, ChatMessage m) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
              title: const Text('Elimina messaggio'),
              onTap: () async {
                Navigator.of(context).pop();
                final ok = await ctrl.eliminaMessaggio(conv, m);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eliminazione non riuscita')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera, color: AppColors.casagrandeDark),
              tooltip: 'Invia foto',
              onPressed: _inviaFoto,
            ),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Scrivi un messaggio…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.casagrandeDark,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _invia,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pulisci(String s) => s
      .replaceAll(RegExp(r'</?b>'), '')
      .replaceAll(RegExp(r'</?i>'), '')
      .replaceAll('`', "'");

  String _oraFmt(int hhmmss) {
    final s = hhmmss.toString().padLeft(6, '0');
    if (s.length < 4) return '';
    return '${s.substring(0, 2)}:${s.substring(2, 4)}';
  }
}
