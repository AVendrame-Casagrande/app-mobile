import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Client minimale per Server-Sent Events (EventSource).
/// Emette i payload `data:` decodificati come Map, indipendentemente dal
/// nome evento (es. 'ping', 'message'). Usato per i movimenti magazzino
/// (api/movimenti/MovimentiMagazzinoSSE) e altri stream del backend.
class SseClient {
  http.Client? _client;

  Stream<Map<String, dynamic>> connect(String url) async* {
    _client?.close();
    final client = http.Client();
    _client = client;

    final request = http.Request('GET', Uri.parse(url));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    request.headers.addAll(AuthToken.headers);

    final response = await client.send(request);

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
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
        try {
          final decoded = jsonDecode(dataPayload);
          if (decoded is Map) {
            yield Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // ignora payload non JSON (commenti/keepalive)
        }
      }
    }
  }

  void close() {
    _client?.close();
    _client = null;
  }
}
