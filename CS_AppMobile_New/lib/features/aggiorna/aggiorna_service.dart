import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/version_info.dart';

/// Service del modulo Aggiorna.
/// Porting di Query.js checkVersion (GET /checkVersion.php).
class AggiornaService {
  AggiornaService(this._api);

  final ApiClient _api;

  /// Scarica le info sull'ultima versione disponibile.
  Future<VersionInfo> checkVersion() async {
    final res = await _api.postJson('${AppConfig.generaleUrl}/checkVersion');
    if (res is Map) {
      return VersionInfo.fromJson(Map<String, dynamic>.from(res));
    }
    return VersionInfo();
  }

  /// Confronta la versione corrente con l'ultima disponibile.
  bool isUpdateAvailable(String currentVersion, VersionInfo info) =>
      info.code.isNotEmpty && info.code != currentVersion;

  /// URL dell'APK con cache-buster (come nell'originale: ?timestamp).
  String apkDownloadUrl() =>
      '${AppConfig.updateApkUrl}?${DateTime.now().millisecondsSinceEpoch}';
}
