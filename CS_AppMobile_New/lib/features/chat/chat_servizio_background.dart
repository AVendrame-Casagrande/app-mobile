import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';
import '../../models/chat_message.dart';
import '../../models/utente.dart';
import 'chat_notifiche.dart';

/// Servizio in background delle notifiche chat — sostituisce cordova-plugin-background-mode
/// (activateBackgroundMode in www/scripts/Classi/GestioneDispositivo.js).
///
/// Un servizio Android in primo piano, con la notifica fissa "Servizio Notifiche Stokky",
/// tiene viva l'app anche chiusa o con lo schermo spento. Ogni minuto legge i messaggi di oggi
/// da ChatStream e, se l'app non è a schermo, mostra le notifiche dei nuovi messaggi e delle
/// Attività. Ad app aperta i popup restano a ChatNotifiche.
class ChatServizioBackground {
  ChatServizioBackground._();

  /// true se il servizio è partito in questa sessione dell'app.
  static bool attivo = false;

  static const _intervallo = Duration(seconds: 60);

  /// Avvia il servizio (al login o all'apertura con sessione valida). Se è già in esecuzione,
  /// per esempio dopo che l'app era stata chiusa, lo lascia andare.
  static Future<void> avvia() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'servizio_notifiche',
          channelName: 'Servizio Notifiche',
          channelDescription: 'Mantiene attiva la ricezione dei messaggi della Chat',
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(_intervallo.inMilliseconds),
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      // Come disableBatteryOptimizations() della vecchia app: senza, Android ferma il servizio.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      if (await FlutterForegroundTask.isRunningService) {
        attivo = true;
        return;
      }
      final esito = await FlutterForegroundTask.startService(
        serviceId: 7788,
        serviceTypes: [ForegroundServiceTypes.specialUse],
        notificationTitle: 'Servizio Notifiche Stokky',
        notificationText: 'Il Servizio in Background per ricevere Notifiche è Attivo',
        callback: avviaTaskChat,
      );
      attivo = esito is ServiceRequestSuccess;
    } catch (_) {
      // Senza servizio restano le notifiche ad app aperta o appena messa in background.
      attivo = false;
    }
  }

  /// Ferma il servizio (logout).
  static Future<void> ferma() async {
    attivo = false;
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }
}

/// Entry point del task (isolate separato del servizio).
@pragma('vm:entry-point')
void avviaTaskChat() {
  FlutterForegroundTask.setTaskHandler(_ChatTaskHandler());
}

class _ChatTaskHandler extends TaskHandler {
  final _notifiche = FlutterLocalNotificationsPlugin();

  /// Messaggi già visti: si notificano solo quelli arrivati dopo l'avvio del servizio.
  final _visti = <int>{};
  bool _primoGiro = true;
  bool _inCorso = false;

  /// Nomi di utenti e gruppi per i titoli delle notifiche.
  final _nomi = <String, String>{};

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _notifiche.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('ic_notifica')),
    );
    await _controlla();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _controlla();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  /// Legge la sessione salvata dall'app (token e utente) e i messaggi di oggi.
  Future<void> _controlla() async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final token = prefs.getString('authToken');
      final utente = _codiceUtente(prefs.getString('utenteLoggato'));
      if (token == null || utente == null) {
        // Logout fatto ad app chiusa o sessione persa: il servizio non serve più.
        await FlutterForegroundTask.stopService();
        return;
      }
      final notificheGruppi = prefs.getString('casagrandeGroupNotificationsActive') != 'false';

      if (_nomi.isEmpty) await _caricaNomi(token, utente);
      final messaggi = await _messaggiDiOggi(token);
      final inPrimoPiano = await FlutterForegroundTask.isAppOnForeground;

      for (final m in messaggi) {
        if (m.senderid == utente || m.letto || m.nascostoRicevuto == 't') continue;
        if (!_visti.add(m.id)) continue;
        // Primo giro: messaggi già presenti all'avvio. App a schermo: ci pensano i popup.
        if (_primoGiro || inPrimoPiano) continue;

        final daGruppo = m.receiverid != utente;
        if (daGruppo && !notificheGruppi) continue;

        final mittente = daGruppo ? m.receiverid : m.senderid;
        final nome = _nomi[mittente] ?? mittente;
        final autore = daGruppo ? '${_nomi[m.senderid] ?? m.senderid}: ' : '';
        final testo = m.isFoto
            ? '${_nomi[m.senderid] ?? m.senderid} ti ha inviato una Foto!'
            : ChatNotifiche.senzaTag(m.messaggio);

        if (ChatNotifiche.tipiAttivita.contains(m.tipoMessaggio)) {
          await ChatNotifiche.mostraAttivita(_notifiche, m.tipoMessaggio, _nomi[m.senderid] ?? m.senderid);
        }
        await ChatNotifiche.mostraMessaggio(_notifiche, mittente, nome, '$autore$testo');
      }
      _primoGiro = false;
    } on _SessioneScaduta {
      await FlutterForegroundTask.stopService();
    } catch (_) {
      // Rete assente o server giù: si riprova al giro successivo.
    } finally {
      _inCorso = false;
    }
  }

  static String? _codiceUtente(String? json) {
    if (json == null) return null;
    try {
      final codice = (jsonDecode(json) as Map)['codiceUtente']?.toString() ?? '';
      return codice.isEmpty ? null : codice;
    } catch (_) {
      return null;
    }
  }

  Future<void> _caricaNomi(String token, String utente) async {
    final utenti = await _post(token, 'getUsersList', {});
    if (utenti is List) {
      for (final u in utenti.whereType<Map>()) {
        final x = Utente.fromJson(Map<String, dynamic>.from(u));
        _nomi[x.codiceUtente] = x.nomeUtente;
      }
    }
    final gruppi = await _post(token, 'getElencoGruppiChat', {'utente': utente});
    if (gruppi is List) {
      for (final g in gruppi.whereType<Map>()) {
        final codice = (g['codice'] ?? '').toString();
        if (codice.isNotEmpty) _nomi[codice] = (g['nome'] ?? codice).toString();
      }
    }
  }

  /// POST JSON con Bearer: restituisce il campo `data` di ResultInfo.
  static Future<dynamic> _post(String token, String azione, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('${AppConfig.chatUrl}/$azione'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 401) throw _SessioneScaduta();
    if (res.statusCode != 200) return null;
    final json = jsonDecode(utf8.decode(res.bodyBytes));
    return json is Map ? json['data'] : json;
  }

  /// Primo evento di ChatStream (messaggi di oggi), poi chiude la connessione.
  static Future<List<ChatMessage>> _messaggiDiOggi(String token) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse('${AppConfig.chatUrl}/ChatStream'))
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Authorization'] = 'Bearer $token';
      final response = await client.send(request).timeout(const Duration(seconds: 30));
      if (response.statusCode == 401) throw _SessioneScaduta();
      if (response.statusCode != 200) return const [];

      var buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder).timeout(const Duration(seconds: 30))) {
        buffer += chunk;
        final fine = buffer.indexOf('\n\n');
        if (fine == -1) continue;
        final dati = buffer
            .substring(0, fine)
            .split('\n')
            .where((l) => l.startsWith('data:'))
            .map((l) => l.substring(5).trim())
            .join();
        final decoded = jsonDecode(dati);
        if (decoded is! List) return const [];
        return decoded
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } finally {
      client.close();
    }
  }
}

class _SessioneScaduta implements Exception {}
