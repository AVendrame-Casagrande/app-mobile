// Modello riga lista magazzino automatico (MGAUT) — porting di
// www/scripts/Giacenze-Magazzino/Classi/Mgaut.js (Automha_Ordine).

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();

class AutomhaOrdine {
  final String tipoprel;
  final String rifprel;
  final String subrifprel;
  final String seqprel;
  final String seq;
  final String articolo;
  final String descArticolo;
  final String magfrom;
  final String magto;
  final num qta;
  final String umis;
  final String vanoto;
  final String nota;
  final String scaffale;
  final String commessa;
  final String inviato; // '0' / '1' (solo MGAUT02)
  bool selezionato;

  AutomhaOrdine({
    this.tipoprel = '',
    this.rifprel = '',
    this.subrifprel = '',
    this.seqprel = '',
    this.seq = '',
    this.articolo = '',
    this.descArticolo = '',
    this.magfrom = '',
    this.magto = '',
    this.qta = 0,
    this.umis = '',
    this.vanoto = '',
    this.nota = '',
    this.scaffale = '',
    this.commessa = '',
    this.inviato = '',
    this.selezionato = false,
  });

  bool get isKan => tipoprel == 'KAN';

  /// Identificativo della lista di prelievo: rifprel_subrifprel_seqprel.
  String get nomeLista => '${rifprel}_${subrifprel}_$seqprel';

  /// Destinazione mostrata (per KAN si usa lo scaffale).
  String get destinazione => isKan && scaffale.isNotEmpty ? scaffale : magto;

  bool get inviatoOk => inviato == '1';

  factory AutomhaOrdine.fromJson(Map<String, dynamic> json) => AutomhaOrdine(
        tipoprel: _str(json['tipoprel']),
        rifprel: _str(json['rifprel']),
        subrifprel: _str(json['subrifprel']),
        seqprel: _str(json['seqprel']),
        seq: _str(json['seq']),
        articolo: _str(json['articolo']),
        descArticolo: _str(json['descarticolo']),
        magfrom: _str(json['magfrom']),
        magto: _str(json['magto']),
        qta: _num(json['qta']),
        umis: _str(json['umis']),
        vanoto: _str(json['vanoto']),
        nota: _str(json['nota']),
        scaffale: _str(json['scaffale']),
        commessa: _str(json['commessa']),
        inviato: _str(json['inviato']),
      );
}
