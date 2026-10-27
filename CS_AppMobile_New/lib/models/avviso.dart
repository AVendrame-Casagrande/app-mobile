import 'package:intl/intl.dart';

/// Modello Avviso/Attività — porting di www/scripts/Classi/Avvisi.js.
class Avviso {
  String timest; // formattato DD/MM/YY HH:mm
  String avviso; // testo
  String utente; // creatore (nomePortale, lowercase)
  String attivo;
  String urgente; // '1' = urgente
  String dest; // destinatario (codiceUtente)
  String scadenza; // formattato DD/MM/YY ('' se senza scadenza)

  int scadenzaInteger;
  int timestInteger;

  Avviso({
    this.timest = '',
    this.avviso = '',
    this.utente = '',
    this.attivo = '1',
    this.urgente = '0',
    this.dest = '',
    this.scadenza = '',
    this.scadenzaInteger = 0,
    this.timestInteger = 0,
  });

  bool get isUrgente => urgente == '1';

  /// Soglia convenzionale "senza scadenza" (>= 31/12/2070), come nell'originale.
  static const int noScadenzaThreshold = 20701231;

  static final DateFormat _timestIn = DateFormat('yyyyMMddHHmmss');
  static final DateFormat _timestOut = DateFormat('dd/MM/yy HH:mm');
  static final DateFormat _dateIn = DateFormat('yyyyMMdd');
  static final DateFormat _dateOut = DateFormat('dd/MM/yy');

  /// Parsing della riga restituita da selectAllAvvisi.php.
  factory Avviso.fromJson(Map<String, dynamic> json) {
    final timestRaw = (json['timest'] ?? '').toString();
    final scadenzaRaw = (json['scadenza'] ?? '').toString();

    String timestFmt = timestRaw;
    try {
      timestFmt = _timestOut.format(_timestIn.parse(timestRaw));
    } catch (_) {}

    final scadenzaInt = int.tryParse(scadenzaRaw) ?? 0;
    String scadenzaFmt = '';
    if (scadenzaInt < noScadenzaThreshold) {
      try {
        scadenzaFmt = _dateOut.format(_dateIn.parse(scadenzaRaw));
      } catch (_) {}
    }

    return Avviso(
      timest: timestFmt,
      avviso: (json['avviso'] ?? '').toString(),
      utente: (json['utente'] ?? '').toString().toLowerCase(),
      attivo: (json['attivo'] ?? '1').toString(),
      urgente: (json['urgente'] ?? '0').toString(),
      dest: (json['dest'] ?? '').toString(),
      scadenza: scadenzaFmt,
      scadenzaInteger: scadenzaInt,
      timestInteger: int.tryParse(timestRaw) ?? 0,
    );
  }

  /// True se l'avviso è ancora valido oggi (scadenza >= oggi oppure senza scadenza).
  bool isVisibileOggi(int dateNowYmd) {
    if (scadenzaInteger >= noScadenzaThreshold) return true;
    return scadenzaInteger < noScadenzaThreshold && scadenzaInteger >= dateNowYmd;
  }
}
