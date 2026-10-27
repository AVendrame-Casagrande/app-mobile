import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/i18n/translator.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
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
  // Avvio: carica lo stato da storage (porting di StartApp.js).
  // -------------------------------------------------------------------------
  Future<void> loadFromStorage() async {
    final ls = LocalStorage.instance;

    final savedUser = ls.getJson('utenteLoggato');
    final savedToken = ls.getString(_tokenKey);
    if (savedUser is Map && savedToken != null && !_tokenScaduto(savedToken)) {
      AuthToken.value = savedToken;
      _utenteLoggato = Utente.fromJson(Map<String, dynamic>.from(savedUser));
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
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Login: codice utente + password Diapason (api/auth/login).
  // Il server verifica la password e restituisce l'utente (ex login.php) e il
  // token JWT da mandare in tutte le altre chiamate.
  // -------------------------------------------------------------------------
  Future<LoginResult> login(String codiceUtente, String password) async {
    try {
      final res = await _api.postJson(
        '${AppConfig.authUrl}/login',
        data: {
          'codiceUtente': codiceUtente.trim().toUpperCase(),
          'password': password,
          'ambiente': 'P',
        },
      );
      if (res is! Map || res['utente'] is! Map || res['token'] is! String) {
        return LoginResult.networkError;
      }
      final token = res['token'] as String;
      AuthToken.value = token;
      await LocalStorage.instance.setString(_tokenKey, token);
      await _saveLoggedUser(Utente.fromJson(Map<String, dynamic>.from(res['utente'] as Map)));
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
    Translator.userLanguage = utente.language;
    await LocalStorage.instance.setJson('utenteLoggato', utente.toJson());
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Logout.
  // -------------------------------------------------------------------------
  Future<void> logout() async {
    await LocalStorage.instance.remove('utenteLoggato');
    await LocalStorage.instance.remove(_tokenKey);
    AuthToken.value = null;
    _utenteLoggato = Utente.ospite();
    if (Translator.systemLanguage == 'en') _utenteLoggato.language = 'E';
    Translator.userLanguage = _utenteLoggato.language;
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
    _api.dispose();
    super.dispose();
  }
}
