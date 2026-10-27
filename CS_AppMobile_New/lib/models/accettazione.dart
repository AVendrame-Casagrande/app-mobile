import '../core/utils/date_format.dart';

// Modelli Accettazione — porting di
// www/scripts/Giacenze-Magazzino/Classi/Accettazione.js.

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();

String _fmtData(dynamic raw) => formatData(raw);

/// Riga di accettazione (selectAccettazioni.php → listaAccettazioni).
class Accettazione {
  final int id;
  final String articolo;
  final String descrizione;
  final String colore;
  final String fornitore;
  final String bolla;
  final String magazzino;
  final String ordine;
  final num qtaGiacenza;
  final num qtaMovimento;
  final String dataMovimento;
  final String um;
  final String trattamento;
  bool isMancante;
  num qtaCarico; // quantità scelta per la lista di carico
  bool selezionato;

  Accettazione({
    this.id = 0,
    this.articolo = '',
    this.descrizione = '',
    this.colore = '',
    this.fornitore = '',
    this.bolla = '',
    this.magazzino = '',
    this.ordine = '',
    this.qtaGiacenza = 0,
    this.qtaMovimento = 0,
    this.dataMovimento = '',
    this.um = '',
    this.trattamento = '',
    this.isMancante = false,
    num? qtaCarico,
    this.selezionato = false,
  }) : qtaCarico = qtaCarico ?? qtaGiacenza;

  factory Accettazione.fromJson(Map<String, dynamic> json) {
    var bolla = _str(json['bolla']);
    if (bolla.isEmpty) bolla = 'N.D.';
    var fornitore = _str(json['fornitore']);
    if (fornitore.isEmpty) fornitore = 'N.D.';
    final qta = _num(json['qtaGiacenza']);
    return Accettazione(
      id: _num(json['id']).toInt(),
      articolo: _str(json['articolo']),
      descrizione: _str(json['descrizione']),
      colore: _str(json['colore']),
      fornitore: fornitore,
      bolla: bolla,
      magazzino: _str(json['magazzino']),
      ordine: _str(json['ordine']),
      qtaGiacenza: qta,
      qtaMovimento: _num(json['qtaMovimento']),
      dataMovimento: _fmtData(json['dataMovimento']),
      um: _str(json['um']),
      trattamento: _str(json['trattamento']),
      qtaCarico: qta,
    );
  }
}

/// Risultato di selectAccettazioni.php.
class AccettazioniResult {
  final List<Accettazione> lista;

  AccettazioniResult({this.lista = const []});

  factory AccettazioniResult.fromJson(Map<String, dynamic> json) {
    final rawLista = json['listaAccettazioni'];
    final lista = (rawLista is List)
        ? rawLista
            .whereType<Map>()
            .map((e) => Accettazione.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Accettazione>[];

    // Calcolo isMancante incrociando con listaMancantiAccettazioni.
    final rawMancanti = json['listaMancantiAccettazioni'];
    if (rawMancanti is List) {
      for (final acc in lista) {
        for (final m in rawMancanti.whereType<Map>()) {
          if (acc.articolo == _str(m['articolo']) &&
              acc.magazzino == _str(m['magdispo'])) {
            acc.isMancante = true;
            break;
          }
        }
      }
    }

    // Ordino per articolo.
    lista.sort((a, b) => a.articolo.toUpperCase().compareTo(b.articolo.toUpperCase()));
    return AccettazioniResult(lista: lista);
  }

  /// Magazzino di destinazione di default in base al magazzino di origine.
  static String magazzinoDestDefault(String magazzinoOrigine) {
    switch (magazzinoOrigine) {
      case 'MIRC002':
        return 'MGAUT10';
      case 'MIRC001':
      default:
        return 'MGAUT00';
    }
  }
}
