import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/i18n/translator.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../features/chat/chat_controller.dart';
import '../features/chat/chat_service.dart';
import '../features/chat/chat_servizio_background.dart';
import '../models/chat_message.dart';
import '../models/utente.dart';

/// Esito di un tentativo di login.
enum LoginResult { success, wrongCredentials, networkError }

/// Stato globale dell'applicazione — porting dell'oggetto `applicazione`
/// (www/scripts/Applicazione.js) per la parte di sessione utente e impostazioni.
class AppState extends ChangeNotifier {
  AppState({ApiClient? api}) : _api = api ?? ApiClient() {
    // Sessione scaduta o token non valido: si torna ospite (come un logout).
    _api.onUnauthorized = () {
      if (isLogged) logout();
    };
  }

  final ApiClient _api;
  ApiClient get api => _api;

  Utente _utenteLoggato = Utente.ospite();
  Utente get utenteLoggato => _utenteLoggato;

  bool get isLogged => !_utenteLoggato.isOspite && _utenteLoggato.codiceUtente.isNotEmpty;

  // Impostazioni utente (replicano i flag salvati in localStorage).
  bool ricercaVocaleActive = false;
  bool highlightActive = false;
  bool casagrandeGroupNotificationsActive = true;

  String get webClientVersion => AppConfig.webClientVersion;

  // -------------------------------------------------------------------------
  // Chat: resta collegata per tutta la sessione (come lo stream di Chat.js
  // aperto all'avvio), per il contatore in home, i popup e le notifiche.
  // -------------------------------------------------------------------------
  ChatController? _chat;
  ChatController? get chat => _chat;

  /// Nuovi messaggi non letti arrivati dallo stream (lo imposta main.dart).
  void Function(List<ChatMessage> nuovi)? onNuoviMessaggiChat;

  void _avviaChat() {
    _fermaChat();
    if (!isLogged) return;
    _chat = ChatController(service: ChatService(_api), utenteLoggato: _utenteLoggato)
      ..onNuoviMessaggi = (nuovi) {
        onNuoviMessaggiChat?.call(nuovi);
      }
      ..caricaTutto();
  }

  void _fermaChat() {
    _chat?.dispose();
    _chat = null;
  }

  // -------------------------------------------------------------------------
  // Avvio: carica lo stato da storage (porting di StartApp.js).
  // -------------------------------------------------------------------------
  Future<void> loadFromStorage() async {
    final ls = LocalStorage.instance;

    final savedUser = ls.getJson('utenteLoggato');
    final savedToken = ls.getString(_tokenKey);
    if (savedUser is Map && savedToken != null && !_tokenScaduto(savedToken)) {
      AuthToken.value = savedToken;
      _utenteLoggato = Utente.fromJson(Map<String, dynamic>.from(savedUser));
      AuthToken.societa = _utenteLoggato.societa;
    } else {
      _utenteLoggato = Utente.ospite();
      if (Translator.systemLanguage == 'en') {
        _utenteLoggato.language = 'E';
      }
    }

    ricercaVocaleActive = ls.getBool('ricercaVocaleActive') ?? false;
    highlightActive = ls.getBool('highlightActive') ?? false;
    casagrandeGroupNotificationsActive =
        ls.getBool('casagrandeGroupNotificationsActive') ?? true;

    Translator.userLanguage = _utenteLoggato.language;
    _avviaChat();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Login: codice utente + password Diapason (api/auth/login).
  // Il server verifica la password e restituisce l'utente (ex login.php) e il
  // token JWT da mandare in tutte le altre chiamate.
  // -------------------------------------------------------------------------
  Future<LoginResult> login(
    String codiceUtente,
    String password, {
    String societa = Utente.societaDefault,
  }) async {
    try {
      await setUltimaSocieta(societa);
      final res = await _api.postJson(
        '${AppConfig.authUrl}/login',
        data: {
          'codiceUtente': codiceUtente.trim().toUpperCase(),
          'password': password,
          'societa': societa,
        },
      );
      if (res is! Map || res['utente'] is! Map || res['token'] is! String) {
        return LoginResult.networkError;
      }
      final token = res['token'] as String;
      AuthToken.value = token;
      await LocalStorage.instance.setString(_tokenKey, token);
      final json = Map<String, dynamic>.from(res['utente'] as Map);
      final utente = Utente.fromJson(json);
      // Il server riporta la società del token; in sua assenza vale quella scelta.
      if ((json['societa'] ?? '').toString().trim().isEmpty) utente.societa = societa;
      await _saveLoggedUser(utente);
      return LoginResult.success;
    } on ApiException catch (e) {
      return e.statusCode == 401 || e.statusCode == 400
          ? LoginResult.wrongCredentials
          : LoginResult.networkError;
    } catch (_) {
      return LoginResult.networkError;
    }
  }

  static const _tokenKey = 'authToken';
  static const _ultimaSocietaKey = 'ultimaSocieta';

  /// Ultima società scelta al login (proposta come predefinita).
  String get ultimaSocieta {
    final s = LocalStorage.instance.getString(_ultimaSocietaKey);
    return s != null && Utente.societaDisponibili.containsKey(s)
        ? s
        : Utente.societaDefault;
  }

  Future<void> setUltimaSocieta(String societa) =>
      LocalStorage.instance.setString(_ultimaSocietaKey, societa);

  /// true se il token JWT è scaduto (claim `exp`) o illeggibile.
  static bool _tokenScaduto(String token) {
    try {
      final parts = token.split('.');
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = (payload as Map)['exp'] as num;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
    } catch (_) {
      return true;
    }
  }

  Future<void> _saveLoggedUser(Utente utente) async {
    // Reset stampa/template lato USA (come in credenzialiCorrette()).
    if (utente.language == 'E') {
      await LocalStorage.instance.setBool('stampaMovimento', false);
    }
    _utenteLoggato = utente;
    AuthToken.societa = utente.societa;
    Translator.userLanguage = utente.language;
    await LocalStorage.instance.setJson('utenteLoggato', utente.toJson());
    _avviaChat();
    // Servizio notifiche ad app chiusa (all'avvio con sessione salvata lo fa main.dart).
    ChatServizioBackground.avvia();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Logout.
  // -------------------------------------------------------------------------
  Future<void> logout() async {
    await LocalStorage.instance.remove('utenteLoggato');
    await LocalStorage.instance.remove(_tokenKey);
    AuthToken.value = null;
    AuthToken.societa = Utente.societaDefault;
    _utenteLoggato = Utente.ospite();
    if (Translator.systemLanguage == 'en') _utenteLoggato.language = 'E';
    Translator.userLanguage = _utenteLoggato.language;
    _fermaChat();
    ChatServizioBackground.ferma();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Impostazioni.
  // -------------------------------------------------------------------------
  Future<void> setRicercaVocale(bool value) async {
    ricercaVocaleActive = value;
    await LocalStorage.instance.setBool('ricercaVocaleActive', value);
    notifyListeners();
  }

  Future<void> setHighlight(bool value) async {
    highlightActive = value;
    await LocalStorage.instance.setBool('highlightActive', value);
    notifyListeners();
  }

  Future<void> setGroupNotifications(bool value) async {
    casagrandeGroupNotificationsActive = value;
    await LocalStorage.instance.setBool('casagrandeGroupNotificationsActive', value);
    notifyListeners();
  }

  @override
  void dispose() {
    _fermaChat();
    _api.dispose();
    super.dispose();
  }
}
