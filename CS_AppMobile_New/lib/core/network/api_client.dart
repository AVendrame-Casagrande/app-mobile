import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/utente.dart';
import '../config.dart';

/// Eccezione di rete/server. [message] è il messaggio della busta ResultInfo
/// quando il server lo fornisce (es. parametri non validi).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Token JWT della sessione, condiviso da [ApiClient] e dai client SSE.
class AuthToken {
  AuthToken._();

  /// Token corrente (null se non loggato).
  static String? value;

  /// Società della sessione (contenuta nel token). Il server la legge dal
  /// token; qui serve solo a mandare nei body un valore coerente.
  static String societa = Utente.societaDefault;

  /// Header di autorizzazione da aggiungere alle richieste.
  static Map<String, String> get headers =>
      value == null || value!.isEmpty ? {} : {'Authorization': 'Bearer $value'};
}

/// Client HTTP delle API C# (CG.MobileAPI).
///
/// - Le richieste mandano un body JSON e l'header `Authorization: Bearer`.
/// - Le risposte arrivano nella busta `{code, message, data}`: i metodi restituiscono
///   solo `data`, quindi i servizi ricevono gli stessi dati dei vecchi PHP.
/// - Un 401 (token scaduto o assente) chiama [onUnauthorized] per tornare al login.
///
/// Le chiamate ai vecchi PHP ancora senza equivalente C# (Manutenzione, vedi
/// [AppConfig.legacyQueryUrl]) restano form-urlencoded, senza token né busta.
class ApiClient {
  ApiClient({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 20);

  final http.Client _client;
  final Duration _timeout;

  /// Chiamato quando il server risponde 401 (sessione scaduta).
  void Function()? onUnauthorized;

  /// POST con risposta JSON (il `data` della busta).
  Future<dynamic> postJson(String url, {Map<String, dynamic>? data}) async {
    final res = await _post(url, data);
    return _isLegacy(url) ? _decodeJson(res.body) : _unwrap(res);
  }

  /// POST con risposta testuale (il `data` della busta come stringa).
  Future<String> postText(String url, {Map<String, dynamic>? data}) async {
    final res = await _post(url, data);
    return _isLegacy(url) ? res.body : _asText(_unwrap(res));
  }

  /// GET con risposta JSON (usato solo per le query legacy e gli endpoint GET).
  Future<dynamic> getJson(String url, {Map<String, String>? query}) async {
    final res = await _get(url, query);
    return _isLegacy(url) ? _decodeJson(res.body) : _unwrap(res);
  }

  /// GET con risposta testuale.
  Future<String> getText(String url, {Map<String, String>? query}) async {
    final res = await _get(url, query);
    return _isLegacy(url) ? res.body : _asText(_unwrap(res));
  }

  /// Upload multipart di un file (campo `file` + campi testuali).
  /// Ritorna la risposta testuale (tipicamente 'uploaded').
  Future<String> uploadFile(
    String url, {
    required List<int> bytes,
    required String name,
    String fieldName = 'file',
    String? filename,
    Map<String, String>? extraFields,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse(url));
    if (!_isLegacy(url)) req.headers.addAll(AuthToken.headers);
    req.fields['name'] = name;
    if (extraFields != null) req.fields.addAll(extraFields);
    req.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename ?? '$name.jpg',
    ));
    final streamed = await _client.send(req).timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res);
    return _isLegacy(url) ? res.body : _asText(_unwrap(res));
  }

  /// Le chiamate fuori da [AppConfig.apiBaseUrl] vanno ancora ai vecchi PHP.
  bool _isLegacy(String url) => !url.startsWith(AppConfig.apiBaseUrl);

  Future<http.Response> _post(String url, Map<String, dynamic>? data) async {
    final http.Response res;
    if (_isLegacy(url)) {
      res = await _client
          .post(Uri.parse(url), body: _encodeForm(data), headers: const {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
          })
          .timeout(_timeout);
    } else {
      res = await _client
          .post(Uri.parse(url),
              body: jsonEncode(data ?? const {}),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                ...AuthToken.headers,
              })
          .timeout(_timeout);
    }
    _ensureOk(res);
    return res;
  }

  Future<http.Response> _get(String url, Map<String, String>? query) async {
    final uri = Uri.parse(url).replace(
      queryParameters: query != null && query.isNotEmpty ? query : null,
    );
    final res = await _client
        .get(uri, headers: _isLegacy(url) ? null : AuthToken.headers)
        .timeout(_timeout);
    _ensureOk(res);
    return res;
  }

  Map<String, String> _encodeForm(Map<String, dynamic>? data) {
    if (data == null) return {};
    return data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    if (res.statusCode == 401) onUnauthorized?.call();
    var message = 'HTTP ${res.statusCode}';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] is String) message = body['message'] as String;
    } catch (_) {}
    throw ApiException(message, statusCode: res.statusCode);
  }

  /// Estrae `data` dalla busta ResultInfo.
  dynamic _unwrap(http.Response res) {
    final body = _decodeJson(res.body);
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// `data` come testo: le stringhe restano tali, il resto torna JSON come lo stampava PHP.
  String _asText(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is num || data is bool) return data.toString();
    return jsonEncode(data);
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (e) {
      throw ApiException('Risposta JSON non valida: $e');
    }
  }

  void dispose() => _client.close();
}
