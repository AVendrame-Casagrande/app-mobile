import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/riga_crea_lista.dart';

/// Service del modulo Giacenze → Crea Lista (lista libera inventario CSUSA).
/// Porting di Pagine/CreaLista (selectSingoloArticolo, csusa/write_inventory_excel,
/// csusa/send_inventory_email).
class CreaListaService {
  CreaListaService(this._api);

  final ApiClient _api;

  /// Descrizione di un articolo (null se non esiste).
  /// POST /giacenze/selectSingoloArticolo.php {codiceArticolo, societa, needCompleteInfo:false}
  Future<String?> getDescrizioneArticolo(String codice, String societa) async {
    final dynamic res;
    try {
      res = await _api.postJson(
        '${AppConfig.giacenzeUrl}/selectSingoloArticolo',
        data: {
          'codiceArticolo': codice,
          'societa': societa,
          'needCompleteInfo': false,
        },
      );
    } on ApiException catch (e) {
      // HTTP 404 = articolo inesistente.
      if (e.statusCode == 404) return null;
      rethrow;
    }
    if (res is Map && res['codice'] != null) {
      return (res['descrizione'] ?? '').toString();
    }
    return null;
  }

  /// Scrive il file Excel sul server. Ritorna il filename, o null se errore.
  /// POST /giacenze/csusa/write_inventory_excel.php {csv, filename}
  Future<String?> writeExcel(List<RigaCreaLista> righe, String filename) async {
    // Header come nell'originale: riga vuota + intestazioni + dati.
    final empty = {
      'articolo': ' ',
      'descrizione': ' ',
      'qta': ' ',
      'note': ' ',
      'image': ' ',
      'user': ' ',
      'data': ' ',
      'ora': ' ',
    };
    final header = {
      'articolo': 'Article',
      'descrizione': 'Description',
      'qta': 'Quantity',
      'note': 'Notes',
      'image': 'Image URL',
      'user': 'User',
      'data': 'Date',
      'ora': 'Time',
    };
    final excelArray = <Map<String, dynamic>>[
      empty,
      header,
      ...righe.map((r) => r.toExcelRow()),
    ];

    final res = await _api.postText(
      '${AppConfig.giacenzeUrl}/csusa/write_inventory_excel',
      data: {'csv': (excelArray), 'filename': filename},
    );
    final out = res.trim();
    if (out.isEmpty || out == 'error') return null;
    return out;
  }

  /// Invia il file via e-mail. Ritorna il numero di email inviate.
  /// POST /giacenze/csusa/send_inventory_email.php {emailTarget, filename}
  Future<int> sendEmail(String filename, String email) async {
    final res = await _api.postText(
      '${AppConfig.giacenzeUrl}/csusa/send_inventory_email',
      data: {'emailTarget': email, 'filename': filename},
    );
    return int.tryParse(res.trim()) ?? 0;
  }
}
