/// Traduttore IT -> EN — porting di www/scripts/Classi/Translator.js.
///
/// Nell'originale è un grande switch che traduce solo quando la lingua
/// dell'utente è 'E' (oppure '?' con lingua di sistema 'en'). Qui usiamo
/// una mappa estendibile con lo stesso comportamento di fallback
/// (se la chiave non esiste, ritorna il testo originale).
class Translator {
  Translator._();

  /// Lingua dell'utente loggato ('I', 'E', '?'). Aggiornata da AppState.
  static String userLanguage = 'I';

  /// Lingua di sistema rilevata (es. 'it', 'en').
  static String systemLanguage = 'it';

  static bool get _useEnglish =>
      userLanguage == 'E' || (userLanguage == '?' && systemLanguage == 'en');

  static String translate(String text) {
    if (!_useEnglish) return text;
    return _itToEn[text] ?? text;
  }

  /// Mappa IT -> EN. Estendere man mano che si convertono i moduli.
  static const Map<String, String> _itToEn = {
    'ID Utente': 'User ID',
    'TIPO ACCOUNT': 'ACCOUNT TYPE',
    'Società': 'Company',
    'Per cambiare società effettua il Logout e un nuovo Login':
        'To change company, log out and log in again',
    'Utente Standard': 'Standard User',
    'Utente Produzione': 'Production User',
    'Utente Magazzino': 'Warehouse User',
    'Utente Avanzato': 'Advanced User',
    'NOME ACCOUNT': 'ACCOUNT NAME',
    'Nome': 'Name',
    'Immagine': 'Image',
    'INFO ACCOUNT': 'ACCOUNT INFO',
    'Logout effettuato con Successo. Non sei più loggato come':
        'Logout Successful. You are no longer logged as',
    'Vuoi effettuare il Logout da questo Account?':
        'Do you want to Logout from this Account?',
    'Inserisci il tuo Codice Utente per effettuare il Login':
        'Insert your User ID to Login',
    'Inserisci la tua Password': 'Insert your Password',
    'Conferma': 'Confirm',
    'Visualizza': 'Show',
    'Nascondi': 'Hide',
    'Password': 'Password',
    'Password Errata': 'Wrong Password',
    'ID Utente Errato': 'Wrong User ID',
    'ID Utente o Password Errati': 'Wrong User ID or Password',
    'Gli utenti in lingua inglese lavorano sempre su Casagrande USA':
        'English-language users always work on Casagrande USA',
    'Credenziali Corrette': 'Correct Credentials',
    'Credenziali Errate': 'Wrong Credentials',
    'Chiudi': 'Close',
    'Login Effettuato con Successo! Ciao': 'Login Successful! Hi',
    "L'applicaziona verrà ora Riavviata": 'The application will now Restart',
    'Errore di Connessione o Server Irraggiungibile':
        'Connection Error or Server Unreachable',
    'Errore di Connessione': 'Connection Error',
    'Errore di Rete durante il Login': 'Network Error during Login',
    'Profilo': 'Profile',
    'Articoli': 'Items',
    'Magazzino': 'Warehouse',
    'Update': 'Update',
    'Login': 'Login',
    'Logout': 'Logout',
  };
}
