import 'dart:typed_data';

import '../../core/config.dart';
import '../../core/network/api_client.dart';

String _str(dynamic v) => (v ?? '').toString();
int _int(dynamic v) => int.tryParse(_str(v)) ?? 0;
bool _bool(dynamic v) => v == true || v == 't' || v == '1' || v == 1 || v == 'true';

/// Operatore della manutenzione accessori (classe ManutenzioneOperatore).
class OperatoreManutenzione {
  final String username;
  String nome;
  String cognome;
  final String azienda;
  final String tipoUtente; // 'ospite', 'azienda', ...
  final int passwordDataScadenza;

  OperatoreManutenzione({
    required this.username,
    this.nome = '',
    this.cognome = '',
    this.azienda = '',
    required this.tipoUtente,
    this.passwordDataScadenza = 0,
  });

  factory OperatoreManutenzione.ospite() =>
      OperatoreManutenzione(username: 'ospite', nome: 'Ospite', tipoUtente: 'ospite');

  factory OperatoreManutenzione.fromJson(Map<String, dynamic> j) => OperatoreManutenzione(
        username: _str(j['username']),
        nome: _str(j['nome']),
        cognome: _str(j['cognome']),
        azienda: _str(j['azienda']),
        tipoUtente: _str(j['tipo_utente']),
        passwordDataScadenza: _int(j['password_data_scadenza']),
      );

  bool get isOspite => tipoUtente == 'ospite';
  bool get abilitato => nome.isNotEmpty && cognome.isNotEmpty;

  /// Nome con cui vengono registrate le verifiche.
  String get nomeCompleto => '$nome $cognome';
}

/// Scheda di un accessorio (getManutenzioneArticolo.php). I campi restano
/// nella mappa originale; qui i getter di quelli usati dalla logica.
class AccessorioManutenzione {
  final Map<String, dynamic> raw;
  AccessorioManutenzione(this.raw);

  String operator [](String k) => _str(raw[k]);

  String get id => this['id'];
  String get attrezzatura => this['attrezzatura'];
  String get ubicazione => this['ubicazione'];
  String get ubicazioneDettaglio => this['ubicazione_dettaglio'];
  bool get inServizio => this['in_servizio'] == '1';
  bool get verificato => _int(raw['data_controllo']) > 0;
  int get dataControllo => _int(raw['data_controllo']);
  int get oraControllo => _int(raw['ora_controllo']);
  String get statoControllo => this['stato_controllo'];
  String get utenteControllo => this['utente_controllo'];
  String get aziendaUtente => this['azienda_utente'];
  String get idControllo => this['id_controllo'];
  String get note => this['note'];
  String get fotoUrl => this['foto_url'];
  bool get fotoAggiornata => _bool(raw['foto_aggiornata']);
  int get fotoData => _int(raw['foto_data']);
  int get fotoOra => _int(raw['foto_ora']);
}

/// Riga dell'elenco accessori (getListaManutenzioneAccessori.php).
class RigaAccessorio {
  final String id;
  final String attrezzatura;
  final String ubicazione;
  final String ubicazioneDettaglio;
  final bool inServizio;
  final bool verificato;
  final String statoControllo;
  final String utenteControllo;

  RigaAccessorio.fromJson(Map<String, dynamic> j)
      : id = _str(j['id']),
        attrezzatura = _str(j['attrezzatura']),
        ubicazione = _str(j['ubicazione']),
        ubicazioneDettaglio = _str(j['ubicazione_dettaglio']),
        inServizio = _str(j['in_servizio']) == '1',
        verificato = _bool(j['verificato']),
        statoControllo = _str(j['stato_controllo']),
        utenteControllo = _str(j['utente_controllo']);
}

/// Ubicazione con le sue ubicazioni di dettaglio.
class UbicazioneManutenzione {
  final String ubicazione;
  final List<String> dettagli;
  const UbicazioneManutenzione(this.ubicazione, this.dettagli);

  factory UbicazioneManutenzione.fromJson(Map<String, dynamic> j) {
    final d = j['ubicazioni_dettaglio'];
    return UbicazioneManutenzione(
        _str(j['ubicazione']), d is List ? d.map(_str).toList() : const []);
  }
}

/// Service di Produzione → Manutenzione / Accessori.
/// Porting di Pagine/Manutenzione (login operatore, ricerca accessori e
/// ubicazioni, verifiche, foto, PDF delle verifiche firmate).
class ManutenzioneService {
  ManutenzioneService(this._api);

  final ApiClient _api;

  String get _p => '${AppConfig.legacyQueryUrl}/produzione';

  Map<String, dynamic>? _map(dynamic res) =>
      res is Map ? Map<String, dynamic>.from(res) : null;

  List<Map<String, dynamic>> _maps(dynamic res) => res is List
      ? res.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];

  /// true se l'operatore esiste — POST manutenzioneCheckUser.php {username}
  Future<bool> checkUser(String username) async =>
      _map(await _api.postJson('$_p/manutenzioneCheckUser.php', data: {'username': username})) !=
      null;

  /// Operatore se la password è giusta — POST manutenzioneCheckPassword.php
  Future<OperatoreManutenzione?> checkPassword(String username, String password) async {
    final j = _map(await _api.postJson('$_p/manutenzioneCheckPassword.php',
        data: {'username': username, 'password': password}));
    return j == null ? null : OperatoreManutenzione.fromJson(j);
  }

  /// POST manutenzioneChangePassword.php → 'changed'
  Future<bool> changePassword(String username, String password) async =>
      (await _api.postText('$_p/manutenzioneChangePassword.php',
              data: {'username': username, 'password': password}))
          .trim() ==
      'changed';

  /// Scheda accessorio; null se il codice non è un accessorio (campo errore).
  /// POST getManutenzioneArticolo.php {articolo}
  Future<AccessorioManutenzione?> getAccessorio(String codice) async {
    final j = _map(await _api.postJson('$_p/getManutenzioneArticolo.php', data: {'articolo': codice}));
    if (j == null || _str(j['errore']) != 'nessuno') return null;
    return AccessorioManutenzione(j);
  }

  /// Accessori di un'ubicazione di dettaglio.
  /// POST getManutenzioneArticoliFromUbicazione.php {ubicazione_dettaglio}
  Future<List<RigaAccessorio>> getAccessoriUbicazione(String ubicazioneDettaglio) async =>
      _maps(await _api.postJson('$_p/getManutenzioneArticoliFromUbicazione.php',
              data: {'ubicazione_dettaglio': ubicazioneDettaglio}))
          .map(RigaAccessorio.fromJson)
          .toList();

  /// Ubicazioni con accessori da verificare.
  /// POST getManutenzioneUbicazioni.php {query: 'accessori_da_verificare'}
  Future<List<UbicazioneManutenzione>> getUbicazioniDaVerificare() async {
    final res = await _api.postJson('$_p/getManutenzioneUbicazioni.php',
        data: {'query': 'accessori_da_verificare'});
    if (res is! List) return [];
    return [
      for (final e in res)
        if (e is Map)
          UbicazioneManutenzione.fromJson(Map<String, dynamic>.from(e))
        else
          UbicazioneManutenzione(_str(e), [_str(e)])
    ];
  }

  /// Elenco completo accessori + ubicazioni.
  /// GET getListaManutenzioneAccessori.php
  Future<(List<RigaAccessorio>, List<UbicazioneManutenzione>)> getLista() async {
    final j = _map(await _api.getJson('$_p/getListaManutenzioneAccessori.php')) ?? {};
    return (
      _maps(j['listaAccessori']).map(RigaAccessorio.fromJson).toList(),
      _maps(j['listaUbicazioni']).map(UbicazioneManutenzione.fromJson).toList(),
    );
  }

  /// POST insertManutenzioneVerifica.php → 'inserted' (altrimenti il messaggio d'errore)
  Future<String> inserisciVerifica({
    required String accessorio,
    required String verifica,
    required String utenteControllo,
    required String azienda,
    required int data,
  }) async =>
      (await _api.postText('$_p/insertManutenzioneVerifica.php', data: {
        'accessorio': accessorio,
        'verifica': verifica,
        'utente_controllo': utenteControllo,
        'azienda_utente': azienda,
        'data': data,
      }))
          .trim();

  /// POST deleteVerificaManutenzione.php {id_controllo} → 'deleted'
  Future<String> eliminaVerifica(String idControllo) async =>
      (await _api.postText('$_p/deleteVerificaManutenzione.php',
              data: {'id_controllo': idControllo}))
          .trim();

  /// POST uploadManutenzioneFoto.php (file, name = id accessorio) → 'uploaded'
  Future<bool> uploadFoto(String id, Uint8List bytes) async =>
      (await _api.uploadFile('$_p/uploadManutenzioneFoto.php', bytes: bytes, name: id)).trim() ==
      'uploaded';

  static String urlFoto(String nome) =>
      '${AppConfig.storageUrl}/manutenzione/accessori/$nome.jpg?${DateTime.now().millisecondsSinceEpoch}';

  /// Verifiche dell'operatore ('oggi' o 'tutte') + URL della firma salvata.
  /// POST getManutenzioneArticoliVerificati.php
  Future<(String, List<Map<String, dynamic>>)> getVerificate({
    required String utenteControllo,
    required String firmaDataUrl,
    required String dataQuery,
  }) async {
    final j = _map(await _api.postJson('$_p/getManutenzioneArticoliVerificati.php', data: {
          'utente_controllo': utenteControllo,
          // Il nome del campo è quello atteso dal server (refuso dell'originale).
          'firma_figitale': firmaDataUrl,
          'data_query': dataQuery,
        })) ??
        {};
    return (_str(j['urlFirma']), _maps(j['listaAccessoriVerificati']));
  }

  /// PDF delle verifiche. Ritorna (url, system_url).
  /// POST queryDesktop/modifiche_tecniche/createPDF.php
  Future<(String, String)> creaPdf(String html, String filename) async {
    final j = _map(await _api.postJson(
          '${AppConfig.serverRoot}/queryDesktop/modifiche_tecniche/createPDF.php',
          data: {
            'html': html,
            'css': 'invoice_letter.css',
            'filename': filename,
            'different_destination': 'manutenzione',
          },
        )) ??
        {};
    return (_str(j['url']), _str(j['system_url']));
  }

  /// POST sendManutenzioneVerificaEmail.php {utente, azienda, file}
  Future<void> inviaEmailVerifiche(String utente, String azienda, String file) async {
    await _api.postText('$_p/sendManutenzioneVerificaEmail.php',
        data: {'utente': utente, 'azienda': azienda, 'file': file});
  }
}
