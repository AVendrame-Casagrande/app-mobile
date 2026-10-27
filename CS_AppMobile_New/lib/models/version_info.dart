/// Esito di checkVersion.php — porting di Query.js checkVersion.
class VersionInfo {
  final String code; // ultima versione disponibile
  final bool updateTablet;
  final bool mandatoryUpdate;
  final List<String> changeLog;

  VersionInfo({
    this.code = '',
    this.updateTablet = false,
    this.mandatoryUpdate = false,
    this.changeLog = const [],
  });

  String get changeLogText => changeLog.join('\n');

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    final logRaw = json['changeLog'];
    final log = <String>[];
    if (logRaw is List) {
      for (final l in logRaw) {
        log.add(l.toString());
      }
    }
    return VersionInfo(
      code: (json['code'] ?? '').toString(),
      updateTablet: _asBool(json['updateTablet']),
      mandatoryUpdate: _asBool(json['mandatoryUpdate']),
      changeLog: log,
    );
  }
}
