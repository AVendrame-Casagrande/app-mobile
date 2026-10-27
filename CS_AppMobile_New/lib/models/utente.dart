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
  }) : elencoGruppiChat = elencoGruppiChat ?? [];

  bool get isOspite => accountType == 'Ospite';
  bool get isEnglish => language == 'E';

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
    );
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
      };

  /// Indica se la risposta JSON di login rappresenta un login immediato
  /// (campo `instantLogin` nel JSON dell'originale).
  static bool isInstantLogin(Map<String, dynamic> json) =>
      json['instantLogin'] == true || json['instantLogin'] == 1;
}
