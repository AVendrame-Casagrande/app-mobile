// Modello Rientro — porting di
// www/scripts/Giacenze-Magazzino/Classi/Rientri.js.

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

String _str(dynamic v) => (v ?? '').toString();

class Rientro {
  final String articolo;
  final String vano;
  final num qtaTotale;
  final num qtaImpegnata;
  final num qtaResa; // quantità "libera" da far rientrare
  final String descrizione;

  Rientro({
    this.articolo = '',
    this.vano = '',
    this.qtaTotale = 0,
    this.qtaImpegnata = 0,
    this.qtaResa = 0,
    this.descrizione = '',
  });

  /// Quantità libera arrotondata a 3 decimali (come nell'originale).
  num get qtaLibera => (qtaResa * 1000).round() / 1000;

  factory Rientro.fromJson(Map<String, dynamic> json) => Rientro(
        articolo: _str(json['articolo']),
        vano: _str(json['vano']),
        qtaTotale: _num(json['qta_totale']),
        qtaImpegnata: _num(json['qta_impegnata']),
        qtaResa: _num(json['qta_resa']),
        descrizione: _str(json['descrizione']),
      );
}
