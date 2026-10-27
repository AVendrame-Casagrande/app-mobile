import 'dart:typed_data';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/foto_arm.dart';

/// Service del modulo Foto ARM (read-only).
/// Porting di www/scripts/FotoArm/FotoArm.js (DBGetARMListMobile.php).
/// Nota: il DB ARM potrebbe essere offline ("ARM Offline" nell'originale).
class FotoArmService {
  FotoArmService(this._api);

  final ApiClient _api;

  /// Elenco degli ARM.
  /// GET /api/DBGetARMListMobile.php
  /// Ordinati per le ultime 2 cifre del numero, decrescente (come l'originale).
  Future<List<FotoArm>> getListaArm() async {
    final res = await _api.postJson('${AppConfig.movimentiUrl}/DBGetARMListMobile');
    if (res is! List) return [];
    final lista = res
        .whereType<Map>()
        .map((e) => FotoArm.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    lista.sort((a, b) => _ultime2(b.numero).compareTo(_ultime2(a.numero)));
    return lista;
  }

  int _ultime2(String numero) {
    if (numero.length < 2) return int.tryParse(numero) ?? 0;
    return int.tryParse(numero.substring(numero.length - 2)) ?? 0;
  }

  /// Carica una foto per un ARM.
  /// POST /uploadFotoArm.php (FormData: file, name=numero). true se 'uploaded'.
  Future<bool> uploadFoto(String numeroArm, Uint8List bytes) async {
    final res = await _api.uploadFile(
      '${AppConfig.generaleUrl}/uploadFotoArm',
      bytes: bytes,
      name: numeroArm,
    );
    return res.trim() == 'uploaded';
  }
}
