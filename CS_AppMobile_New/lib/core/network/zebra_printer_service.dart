import 'package:http/http.dart' as http;

import '../config.dart';
import '../storage/local_storage.dart';

/// Service per la stampante Zebra di rete.
///
/// Replica il meccanismo dell'app Cordova (Stampa.js): l'etichetta in
/// linguaggio ZPL viene inviata via HTTP POST all'endpoint `pstprnt`
/// del print-server integrato della stampante (`http://<ip>/pstprnt`).
/// Non serve alcun plugin Bluetooth: è una stampa di rete.
class ZebraPrinterService {
  ZebraPrinterService({Duration? timeout})
      : _timeout = timeout ?? const Duration(seconds: 10);

  final Duration _timeout;

  /// IP corrente della stampante (da LocalStorage o default).
  static String get printerIp {
    final saved = LocalStorage.instance.getString(AppConfig.zebraPrinterIpKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return AppConfig.zebraPrinterIpDefault;
  }

  static Future<void> setPrinterIp(String ip) =>
      LocalStorage.instance.setString(AppConfig.zebraPrinterIpKey, ip.trim());

  /// Invia una singola etichetta ZPL alla stampante. Lancia in caso di errore.
  Future<void> printZpl(String zpl, {String? ip}) async {
    final address = (ip ?? printerIp).trim();
    final uri = Uri.parse('http://$address/pstprnt');
    final res = await http
        .post(uri, body: zpl)
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Stampante: HTTP ${res.statusCode}');
    }
  }

  /// Stampa [copie] etichette in sequenza (come nell'originale, con
  /// piccola pausa tra una stampa e l'altra).
  Future<void> printCopies(String zpl, int copie, {String? ip}) async {
    final n = copie < 1 ? 1 : copie;
    for (var i = 0; i < n; i++) {
      await printZpl(zpl, ip: ip);
      if (i < n - 1) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }
}
