import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/chat_message.dart';
import '../../models/utente.dart';

/// Service del modulo Chat — porting di www/scripts/Chat/Chat.js.
/// Gestisce elenco utenti/gruppi, scarico chat, invio/lettura/eliminazione
/// e lo stream realtime (Server-Sent Events di ChatStream.php).
class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  http.Client? _streamClient;

  String get _base => AppConfig.chatUrl;

  // -------------------------------------------------------------------------
  // Elenco utenti totali (GET getUsersList.php).
  // -------------------------------------------------------------------------
  Future<List<Utente>> getUsersList() async {
    final res = await _api.postJson('$_base/getUsersList');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => Utente.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Elenco gruppi dell'utente (POST getElencoGruppiChat.php).
  // Ritorna gli oggetti grezzi {codice, nome, portale}.
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getElencoGruppiChat(
      String codiceUtente) async {
    final res = await _api.postJson(
      '$_base/getElencoGruppiChat',
      data: {'utente': codiceUtente},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Tutti i messaggi che coinvolgono l'utente (POST getAllChats.php).
  // -------------------------------------------------------------------------
  Future<List<ChatMessage>> getAllChats(String codiceUtente) async {
    final res = await _api.postJson(
      '$_base/getAllChats',
      data: {'codiceUtente': codiceUtente},
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Invio messaggio (POST writeMessage.php). Ritorna l'id inserito.
  // -------------------------------------------------------------------------
  Future<int> sendMessage(ChatMessage message) async {
    // Sanifica gli apici come nell'originale.
    message.messaggio = message.messaggio.replaceAll("'", '`');
    final body = await _api.postText(
      '$_base/writeMessage',
      data: {'message': (message.toJson())},
    );
    return int.tryParse(body.trim()) ?? 0;
  }

  // -------------------------------------------------------------------------
  // Messaggio automatico (es. Attività creata/modificata) + promemoria email —
  // porting di chatPageFunctions.sendMessage() + setEmailChatReminder().
  // Ritorna l'id del messaggio (0 se non inviato).
  // -------------------------------------------------------------------------
  Future<int> sendMessaggioAutomatico({
    required String testo,
    required String sender,
    required String receiver,
    required String tipoMessaggio,
  }) async {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final message = ChatMessage(
      messaggio: testo,
      senderid: sender,
      receiverid: receiver,
      dataInvio: int.parse('${now.year}${two(now.month)}${two(now.day)}'),
      oraInvio: int.parse('${now.hour}${two(now.minute)}${two(now.second)}'),
      tipo: 'inviato',
      tipoMessaggio: tipoMessaggio,
    );
    final id = await sendMessage(message);
    message.id = id;
    try {
      await _api.postText('$_base/setEmailChatReminder', data: {
        'message': (message.toJson()),
        'id_inserted': id,
      });
    } catch (_) {
      // Best-effort come nell'originale.
    }
    return id;
  }

  // -------------------------------------------------------------------------
  // Upload foto chat (POST chat/upload_foto.php). Ritorna true se 'uploaded'.
  // -------------------------------------------------------------------------
  Future<bool> uploadFoto(String urlFoto, Uint8List bytes) async {
    final res = await _api.uploadFile(
      '$_base/upload_foto',
      bytes: bytes,
      name: urlFoto,
    );
    return res.trim() == 'uploaded';
  }

  // -------------------------------------------------------------------------
  // Segna messaggi privati come letti (POST updateMessagesRead.php).
  // -------------------------------------------------------------------------
  Future<void> updateMessagesRead(List<int> idMessaggiLetti) async {
    if (idMessaggiLetti.isEmpty) return;
    await _api.postJson(
      '$_base/updateMessagesRead',
      data: {'idMessaggiLetti': (idMessaggiLetti)},
    );
  }

  // -------------------------------------------------------------------------
  // Segna messaggi di gruppo come letti (POST updateMessagesReadGruppo.php).
  // -------------------------------------------------------------------------
  Future<void> updateMessagesReadGruppo(
      String codiceUtente, List<int> idMessaggiLetti) async {
    if (idMessaggiLetti.isEmpty) return;
    await _api.postJson(
      '$_base/updateMessagesReadGruppo',
      data: {
        'codiceUtente': codiceUtente,
        'idMessaggiLetti': (idMessaggiLetti),
      },
    );
  }

  // -------------------------------------------------------------------------
  // Elimina messaggio (POST deleteMessage.php). true se 'deleted'.
  // -------------------------------------------------------------------------
  Future<bool> deleteMessage(int id) async {
    final res = await _api.postText('$_base/deleteMessage', data: {'id': id});
    return res.trim() == 'deleted';
  }

  // -------------------------------------------------------------------------
  // Nasconde messaggio (POST hideMessage.php). true se 'hided'.
  // -------------------------------------------------------------------------
  Future<bool> hideMessage(int id, String tipo) async {
    final res = await _api.postText(
      '$_base/hideMessage',
      data: {'id': id, 'tipo': tipo},
    );
    return res.trim() == 'hided';
  }

  // -------------------------------------------------------------------------
  // Stream realtime (SSE) dei nuovi messaggi (GET ChatStream?utente=...).
  // Emette liste di ChatMessage a ogni evento.
  // -------------------------------------------------------------------------
  Stream<List<ChatMessage>> openStream(String codiceUtente) async* {
    _streamClient?.close();
    final client = http.Client();
    _streamClient = client;

    final uri = Uri.parse('$_base/ChatStream');
    final request = http.Request('GET', uri);
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    request.headers.addAll(AuthToken.headers);

    final response = await client.send(request);

    var buffer = '';
    await for (final chunk
        in response.stream.transform(utf8.decoder)) {
      buffer += chunk;

      // Gli eventi SSE sono separati da una riga vuota (\n\n).
      var sep = buffer.indexOf('\n\n');
      while (sep != -1) {
        final rawEvent = buffer.substring(0, sep);
        buffer = buffer.substring(sep + 2);
        sep = buffer.indexOf('\n\n');

        final dataPayload = rawEvent
            .split('\n')
            .where((l) => l.startsWith('data:'))
            .map((l) => l.substring(5).trimLeft())
            .join('\n')
            .trim();

        if (dataPayload.isEmpty) continue;
        dynamic decoded;
        try {
          decoded = jsonDecode(dataPayload);
        } catch (_) {
          continue;
        }
        if (decoded is List) {
          yield decoded
              .whereType<Map>()
              .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    }
  }

  /// Chiude lo stream SSE.
  void closeStream() {
    _streamClient?.close();
    _streamClient = null;
  }
}
