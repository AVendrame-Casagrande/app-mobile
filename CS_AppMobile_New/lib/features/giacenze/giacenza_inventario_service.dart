import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/giacenza_inventario.dart';

/// Service del modulo Giacenze → Giacenza Inventario (read-only).
/// Porting di Giacenze-Magazzino/Classi/Query.js (selectGiacenzeInventario).
class GiacenzaInventarioService {
  GiacenzaInventarioService(this._api);

  final ApiClient _api;

  /// Giacenze di un magazzino.
  /// POST /giacenze/selectGiacenzeInventario.php data: {magazzino}
  /// Le righe sono ordinate per articolo asc (come nell'originale).
  Future<List<GiacenzaInventario>> getGiacenze(String magazzino) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/selectGiacenzeInventario',
      data: {'magazzino': magazzino},
    );
    if (res is! List) return [];
    final lista = res
        .whereType<Map>()
        .map((e) => GiacenzaInventario.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    lista.sort(
        (a, b) => a.articolo.toUpperCase().compareTo(b.articolo.toUpperCase()));
    return lista;
  }

  /// Ultimo costo CATT dell'articolo (0 se non trovato).
  /// POST /giacenze/addInfoCostoGiacenzaInventario data: {articolo}
  Future<double> getCosto(String articolo) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/addInfoCostoGiacenzaInventario',
      data: {'articolo': articolo},
    );
    if (res is num) return res.toDouble();
    return double.tryParse((res ?? '').toString()) ?? 0;
  }
}
