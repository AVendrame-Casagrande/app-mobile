import 'dart:typed_data';

import '../../core/config.dart';
import '../../core/network/api_client.dart';

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();
bool _bool(dynamic v) => v == true || v == 't' || v == '1' || v == 1 || v == 'true';

String _data(dynamic v) {
  final s = _str(v);
  if (s.length != 8) return s;
  return '${s.substring(6, 8)}/${s.substring(4, 6)}/${s.substring(0, 4)}';
}

/// Codice R ricondizionato da controllare (getQualita.php).
class RigaQualita {
  final String articolo;
  final String descrizione;
  final String um;
  final String bolla;
  final String ordine;
  final String fornitore;
  final String magazzino;
  final String vano;
  final String trattamento;
  final String colore;
  final String tipoMovimento;
  final String movimento;
  final String qtaMovimento;
  final String qtaGiacenza;
  final String dataMovimento;
  String urlFoto;
  bool confermato;
  String id;

  RigaQualita._(
    this.articolo,
    this.descrizione,
    this.um,
    this.bolla,
    this.ordine,
    this.fornitore,
    this.magazzino,
    this.vano,
    this.trattamento,
    this.colore,
    this.tipoMovimento,
    this.movimento,
    this.qtaMovimento,
    this.qtaGiacenza,
    this.dataMovimento,
    this.urlFoto,
    this.confermato,
    this.id,
  );

  factory RigaQualita.fromJson(Map<String, dynamic> j) => RigaQualita._(
        _str(j['articolo']),
        _str(j['descrizione']),
        _str(j['um']),
        _str(j['bolla']),
        _str(j['ordine']),
        _str(j['fornitore']),
        _str(j['magazzino']),
        _str(j['vano']),
        _str(j['trattamento']),
        _str(j['colore']),
        _str(j['tipoMovimento']),
        _str(j['movimento']),
        _str(j['qtaMovimento']),
        _str(j['qtaGiacenza']),
        _data(j['dataMovimentoInteger']),
        _str(j['url_foto']),
        _bool(j['confermato']),
        _str(j['id']),
      );

  /// Nome del file foto: articolo_bolla (con * e / sostituiti da _).
  String get nomeFoto => '${articolo}_$bolla'.replaceAll('*', '_').replaceAll('/', '_');
}

/// Arrivo di merce (getQualitaArrivi.php).
class ArrivoQualita {
  final String articolo;
  final String descrizione;
  final String bolla;
  final String ordine;
  final String ragioneSociale;
  final num qta;
  final String um;
  final String dataArrivo;

  ArrivoQualita._(this.articolo, this.descrizione, this.bolla, this.ordine,
      this.ragioneSociale, this.qta, this.um, this.dataArrivo);

  factory ArrivoQualita.fromJson(Map<String, dynamic> j) => ArrivoQualita._(
        _str(j['articolo']),
        _str(j['descrizione']),
        _str(j['bolla']),
        _str(j['ordine']),
        _str(j['ragioneSociale']),
        _num(j['qta']),
        _str(j['um']),
        _data(j['dataArrivo']),
      );
}

/// Service di Produzione → Qualità.
/// Porting di Produzione-Odl/Pagine/Qualita (getQualita, confirmDeleteQualita,
/// getQualitaArrivi) e dell'upload foto 'qualita' di GestioneDispositivo.js.
class QualitaService {
  QualitaService(this._api);

  final ApiClient _api;

  String get _p => AppConfig.produzioneUrl;

  /// GET produzione/getQualita.php
  Future<List<RigaQualita>> getRicondizionati() async {
    final res = await _api.postJson('$_p/getQualita');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => RigaQualita.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Conferma ('confirm', ritorna l'id) o annulla la conferma ('delete').
  /// POST produzione/confirmDeleteQualita.php
  Future<String> confermaOAnnulla(RigaQualita q, String utente, String action) async =>
      (await _api.postText('$_p/confirmDeleteQualita', data: {
        'articolo': q.articolo,
        'bolla': q.bolla,
        'url_foto': q.urlFoto,
        'utente_conferma': utente,
        'action': action,
      }))
          .trim();

  /// Arrivi filtrati per articolo, fornitore e data (yyyyMMdd).
  /// POST produzione/getQualitaArrivi.php {societa, art, ragSoc, dataArr}
  Future<List<ArrivoQualita>> getArrivi({
    required String societa,
    required String articolo,
    required String ragioneSociale,
    required String data,
  }) async {
    final res = await _api.postJson('$_p/getQualitaArrivi', data: {
      'societa': societa,
      'art': articolo,
      'ragSoc': ragioneSociale,
      'dataArr': data,
    });
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => ArrivoQualita.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Carica la foto del codice R e la aggiunge all'anagrafica articolo.
  /// POST produzione/uploadFotoQualita.php + uploadFoto.php → 'uploaded'
  Future<bool> uploadFoto(RigaQualita q, Uint8List bytes) async {
    final res = await _api.uploadFile('$_p/uploadFotoQualita', bytes: bytes, name: q.nomeFoto);
    _api
        .uploadFile('${AppConfig.generaleUrl}/uploadFoto', bytes: bytes, name: q.articolo)
        .ignore();
    return res.trim() == 'uploaded';
  }

  static String urlFoto(String nome) => '${AppConfig.storageUrl}/qualita_foto/$nome.jpg';
}
