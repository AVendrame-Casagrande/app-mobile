/// Modello Utente — porting di www/scripts/Classi/Utente.js.
class Utente {
  String codiceUtente;
  String nomeUtente;
  String emailUtente;
  String nomePortale;

  String accountType;
  List<String> elencoGruppiChat;
  String language; // 'I' = Italiano, 'E' = English, '?' = sconosciuto
  String immagine;
  String homepageType;

  /// Società della sessione ('CSPRO' = Casagrande, 'IMM00' = IMM, 'CSUSA' per gli
  /// utenti in lingua inglese, assegnata dal server). È legata al token JWT: per
  /// cambiarla serve un nuovo login.
  String societa;

  /// Società disponibili al login: codice -> nome leggibile.
  static const societaDisponibili = {
    societaCasagrande: 'Casagrande',
    societaImm: 'IMM',
  };
  static const societaCasagrande = 'CSPRO';
  static const societaImm = 'IMM00';
  static const societaCsUsa = 'CSUSA';
  static const societaDefault = societaCasagrande;

  /// Nome leggibile di un codice società (es. 'IMM00' -> 'IMM').
  static String nomeSocieta(String codice) => codice == societaCsUsa
      ? 'Casagrande USA'
      : societaDisponibili[codice] ?? codice;

  Utente({
    this.codiceUtente = '',
    this.nomeUtente = 'Ospite',
    this.emailUtente = '',
    this.nomePortale = '',
    this.accountType = 'Sconosciuto',
    List<String>? elencoGruppiChat,
    this.language = '?',
    this.immagine = '',
    this.homepageType = 'Standard',
    this.societa = societaDefault,
  }) : elencoGruppiChat = elencoGruppiChat ?? [];

  bool get isOspite => accountType == 'Ospite';
  bool get isEnglish => language == 'E';

  /// Società da mandare nei body delle API: quella della sessione (il server la
  /// prende comunque dal token; per gli utenti in inglese è già CSUSA).
  String get societaApi => societa;

  /// Nome leggibile della società dell'utente (Casagrande / IMM).
  String get societaNome => nomeSocieta(societa);

  /// Crea un Utente "Ospite" di default (come nello StartApp.js).
  factory Utente.ospite() => Utente(
        codiceUtente: '',
        nomeUtente: 'Ospite',
        emailUtente: '',
        nomePortale: '',
        accountType: 'Ospite',
        language: 'I',
      );

  /// Parsing della risposta di login.php.
  factory Utente.fromJson(Map<String, dynamic> json) {
    List<String> gruppi = [];
    final raw = json['elencoGruppiChat'];
    if (raw is List) {
      gruppi = raw.map((e) => e.toString()).toList();
    }
    return Utente(
      codiceUtente: (json['codiceUtente'] ?? '').toString(),
      nomeUtente: (json['nomeUtente'] ?? '').toString(),
      emailUtente: (json['emailUtente'] ?? '').toString(),
      nomePortale: (json['nomePortale'] ?? '').toString(),
      accountType: (json['accountType'] ?? 'Sconosciuto').toString(),
      elencoGruppiChat: gruppi,
      language: (json['language'] ?? '?').toString(),
      immagine: (json['immagine'] ?? '').toString(),
      homepageType: (json['homepageType'] ?? 'Standard').toString(),
      // Default CSPRO per gli utenti salvati prima dell'introduzione del campo.
      societa: _societaDaJson(json['societa']),
    );
  }

  static String _societaDaJson(Object? raw) {
    final s = (raw ?? '').toString().trim().toUpperCase();
    return s.isEmpty ? societaDefault : s;
  }

  Map<String, dynamic> toJson() => {
        'codiceUtente': codiceUtente,
        'nomeUtente': nomeUtente,
        'emailUtente': emailUtente,
        'nomePortale': nomePortale,
        'accountType': accountType,
        'elencoGruppiChat': elencoGruppiChat,
        'language': language,
        'immagine': immagine,
        'homepageType': homepageType,
        'societa': societa,
      };

  /// Indica se la risposta JSON di login rappresenta un login immediato
  /// (campo `instantLogin` nel JSON dell'originale).
  static bool isInstantLogin(Map<String, dynamic> json) =>
      json['instantLogin'] == true || json['instantLogin'] == 1;
}
