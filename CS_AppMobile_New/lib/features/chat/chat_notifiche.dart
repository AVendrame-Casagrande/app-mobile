import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../models/chat_message.dart';
import '../../state/app_state.dart';
import 'chat_controller.dart';
import 'chat_conversation_page.dart';
import 'chat_servizio_background.dart';

/// Popup e notifiche dei nuovi messaggi — porting di
/// applicazione.chatPageFunctions.notificateMessages (www/scripts/Chat/Chat.js):
/// - app aperta: popup "Nuovo Messaggio da ..." con Segna come letto / Vai alla chat / Rispondi
///   (niente popup se quella conversazione è già aperta);
/// - app in background: notifica di sistema, che al tocco apre la conversazione;
/// - Attività create/modificate/completate: notifica di sistema sempre.
/// I messaggi dei gruppi si notificano solo con l'impostazione "notifiche gruppi" attiva.
class ChatNotifiche {
  ChatNotifiche(this._app, this.navigatorKey);

  final AppState _app;
  final GlobalKey<NavigatorState> navigatorKey;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inizializzato = false;
  bool _popupAperto = false;

  static const canaleChat = AndroidNotificationDetails(
    'chat',
    'Messaggi Chat',
    channelDescription: 'Nuovi messaggi della Chat',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.message,
  );

  static const canaleAttivita = AndroidNotificationDetails(
    'attivita',
    'Attività',
    channelDescription: 'Attività create, modificate o completate',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const tipiAttivita = {'avviso_creato', 'avviso_modificato', 'avviso_completato'};

  /// Inizializza il plugin e chiede il permesso (Android 13+).
  Future<void> init() async {
    if (_inizializzato) return;
    _inizializzato = true;
    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('ic_notifica')),
      onDidReceiveNotificationResponse: (r) {
        final mittente = r.payload;
        if (mittente != null && mittente.isNotEmpty) _apriConversazione(mittente);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // App avviata toccando una notifica.
    final avvio = await _plugin.getNotificationAppLaunchDetails();
    final mittente = avvio?.notificationResponse?.payload;
    if (avvio?.didNotificationLaunchApp == true && mittente != null && mittente.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apriConversazione(mittente));
    }
  }

  bool get _inPrimoPiano =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  /// Callback dei nuovi messaggi non letti (AppState.onNuoviMessaggiChat).
  void gestisci(List<ChatMessage> nuovi) {
    final chat = _app.chat;
    if (chat == null) return;
    final inPrimoPiano = _inPrimoPiano;
    // In background le notifiche le mostra il servizio (ChatServizioBackground): niente doppioni.
    if (!inPrimoPiano && ChatServizioBackground.attivo) return;

    for (final m in nuovi) {
      final daGruppo = m.senderidGroup.isNotEmpty;
      if (daGruppo && !_app.casagrandeGroupNotificationsActive) continue;

      final nome = chat.nomeUtente(m.senderid);
      final autore = daGruppo ? '${chat.nomeUtente(m.senderidGroup)}: ' : '';
      final testo = m.isFoto ? '$nome ti ha inviato una Foto!' : senzaTag(m.messaggio);

      if (tipiAttivita.contains(m.tipoMessaggio)) mostraAttivita(_plugin, m.tipoMessaggio, nome);

      if (inPrimoPiano) {
        _popup(chat, m, nome, '$autore$testo');
      } else {
        mostraMessaggio(_plugin, m.senderid, nome, '$autore$testo');
      }
    }
  }

  /// Notifica di sistema di un messaggio: una per mittente, il tocco apre la conversazione.
  static Future<void> mostraMessaggio(
          FlutterLocalNotificationsPlugin plugin, String mittente, String titolo, String testo) =>
      plugin.show(idNotifica(mittente), titolo, testo, const NotificationDetails(android: canaleChat),
          payload: mittente);

  /// Notifica di sistema di un'Attività creata, modificata o completata.
  static Future<void> mostraAttivita(FlutterLocalNotificationsPlugin plugin, String tipo, String nome) {
    final (titolo, testo) = switch (tipo) {
      'avviso_creato' => ('Attività Creata', 'È stata creata una nuova Attività per te da parte di $nome'),
      'avviso_completato' => ('Attività Completata', "L'utente $nome ha completato una tua Attività"),
      _ => ('Attività Modificata', "L'utente $nome ha modificato una tua Attività"),
    };
    return plugin.show(
      DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      titolo,
      testo,
      const NotificationDetails(android: canaleAttivita),
    );
  }

  Future<void> _popup(ChatController chat, ChatMessage m, String nome, String testo) async {
    final context = navigatorKey.currentContext;
    // Un popup alla volta: gli altri messaggi restano nel contatore della home.
    if (context == null || _popupAperto) return;
    _popupAperto = true;
    try {
      final scelta = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Nuovo Messaggio da $nome'),
          content: Text(testo),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(0), child: const Text('Segna come letto')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(1), child: const Text('Vai alla chat')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(2), child: const Text('Rispondi')),
          ],
        ),
      );
      final conv = chat.conversazioneCon(m.senderid);
      if (conv == null) return;
      switch (scelta) {
        case 0:
          await chat.segnaLetti(conv);
        case 1:
          _apriConversazione(m.senderid);
        case 2:
          final ctx = navigatorKey.currentContext;
          if (ctx == null || !ctx.mounted) return;
          final risposta = await _chiediRisposta(ctx, nome, testo);
          if (risposta == null || risposta.trim().isEmpty) return;
          await chat.inviaMessaggio(conv, risposta);
          await chat.segnaLetti(conv);
      }
    } finally {
      _popupAperto = false;
    }
  }

  Future<String?> _chiediRisposta(BuildContext context, String nome, String testo) {
    final input = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rispondi a $nome'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(testo),
            const SizedBox(height: 12),
            TextField(
              controller: input,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Scrivi un messaggio'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Chiudi')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(input.text), child: const Text('Invia Risposta')),
        ],
      ),
    ).whenComplete(input.dispose);
  }

  void _apriConversazione(String codiceUtente) {
    final chat = _app.chat;
    final nav = navigatorKey.currentState;
    if (chat == null || nav == null) return;
    if (chat.conversazioneAperta == codiceUtente) return;
    _plugin.cancel(idNotifica(codiceUtente));
    nav.push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: chat,
        child: ChatConversationPage(codiceUtente: codiceUtente),
      ),
    ));
  }

  /// Una notifica per mittente, che si aggiorna con l'ultimo messaggio (hashCode di Chat.js).
  static int idNotifica(String mittente) {
    var h = 0;
    for (final c in mittente.codeUnits) {
      h = (31 * h + c) & 0x7fffffff;
    }
    return h;
  }

  static String senzaTag(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '');
}
