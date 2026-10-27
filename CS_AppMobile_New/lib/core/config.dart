/// Configurazione globale dell'applicazione Casagrande.
///
/// I servizi sono le API C# di CG.MobileAPI (porting dei PHP di mobile/server):
/// ogni ex `.../<area>/<nome>.php` è ora `POST $apiBaseUrl/<area>/<nome>` con body
/// JSON, header `Authorization: Bearer` e risposta nella busta ResultInfo
/// `{code, message, data}` (vedi core/network/api_client.dart).
/// I file statici (foto, guida, APK) restano sul web server.
class AppConfig {
  AppConfig._();

  /// Root del web server: file statici (storage foto, guida, APK di aggiornamento).
  /// Cordova: `http://app.casagrandegroup.local/mobile/server`
  static const String serverRoot = 'http://app.casagrandegroup.local/mobile/server';

  /// Base delle API C# (CG.MobileAPI). Da impostare sull'host di produzione dell'API.
  static const String apiBaseUrl = 'http://10.10.32.22:5021/api';

  /// Login (codice utente + password Diapason → utente + token JWT).
  static const String authUrl = '$apiBaseUrl/auth';

  /// Servizi generali (ex query/*.php: versione, foto, situazione ODV, log).
  static const String generaleUrl = '$apiBaseUrl/generale';

  /// Modulo Giacenze-Magazzino (ex query/giacenze).
  static const String giacenzeUrl = '$apiBaseUrl/giacenze';

  /// Modulo Kanban (ex query/kanban).
  static const String kanbanUrl = '$apiBaseUrl/kanban';

  /// Modulo Chat (ex query/chat).
  static const String chatUrl = '$apiBaseUrl/chat';

  /// Modulo Produzione (ex query/produzione).
  static const String produzioneUrl = '$apiBaseUrl/produzione';

  /// Attività / Avvisi (ex query/avvisi).
  static const String avvisiUrl = '$apiBaseUrl/avvisi';

  /// Movimenti di magazzino verso Diapason (ex api/*.php).
  static const String movimentiUrl = '$apiBaseUrl/movimenti';

  /// Servizi condivisi col gestionale desktop (ex queryDesktop).
  static const String queryDesktopUrl = '$apiBaseUrl/queryDesktop';

  /// Vecchie query PHP ancora senza equivalente C# (Manutenzione / Accessori: i PHP
  /// non sono stati forniti). Le chiamate a questo indirizzo restano
  /// form-urlencoded, senza token né busta ResultInfo.
  static const String legacyQueryUrl = '$serverRoot/query';

  /// Path base dello storage (foto, PDF guida, ecc.).
  /// Cordova: `applicazione.storage_path`
  static const String storageUrl = '$serverRoot/storage';

  /// Path base dei PDF della Guida/Documenti.
  static const String guidaUrl = '$storageUrl/guida';

  /// Path base delle foto profilo utente.
  /// Cordova: `${storage_path}/foto_profilo/`
  static const String profileFotoPath = '$storageUrl/foto_profilo';

  /// Script condivisi web.
  static const String sharedScriptsUrl =
      'http://app.casagrandegroup.local/mobile/portale-web/apps/shared';

  /// Versione client (mostrata nel pulsante "Aggiorna").
  static const String webClientVersion = '2.0.16';

  /// URL dell'APK di aggiornamento (Cordova: update/casagrande.apk).
  static const String updateApkUrl = '$serverRoot/update/casagrande.apk';

  /// IP di default della stampante Zebra di rete.
  /// Cordova: `http://10.0.0.98/pstprnt` (Stampa.js).
  static const String zebraPrinterIpDefault = '10.0.0.98';

  /// Chiave LocalStorage per l'IP stampante personalizzato.
  static const String zebraPrinterIpKey = 'zebraPrinterIp';
}
