import 'package:intl/intl.dart';

/// Modello Giacenza Inventario — porting di
/// www/scripts/Giacenze-Magazzino/Classi/GiacenzaInventario.js.
/// Rappresenta una riga di giacenza per magazzino/vano.

DateFormat _ymd = DateFormat('yyyy-MM-dd');
DateFormat _dmy = DateFormat('d/M/yy');

String _fmtDate(dynamic raw) {
  final s = (raw ?? '').toString();
  if (s.isEmpty || s == '0') return '-';
  try {
    return _dmy.format(_ymd.parse(s));
  } catch (_) {
    return s;
  }
}

String _str(dynamic v) => (v ?? '').toString();

class GiacenzaInventario {
  final String articolo;
  final String descrizione;
  final String qtaGiacente;
  final String impegnato;
  final String disponibile;
  final String giacenteTot;
  final String inOrdinePrd;
  final String inOrdineAcq;
  final String ultimoVersamento;
  final String ultimoConsumo;
  final String magazzino;
  final String vano;

  GiacenzaInventario({
    this.articolo = '',
    this.descrizione = '',
    this.qtaGiacente = '',
    this.impegnato = '',
    this.disponibile = '',
    this.giacenteTot = '',
    this.inOrdinePrd = '',
    this.inOrdineAcq = '',
    this.ultimoVersamento = '',
    this.ultimoConsumo = '',
    this.magazzino = '',
    this.vano = '',
  });

  factory GiacenzaInventario.fromJson(Map<String, dynamic> json) =>
      GiacenzaInventario(
        articolo: _str(json['articolo']),
        descrizione: _str(json['descrizione']).toLowerCase(),
        qtaGiacente: _str(json['qta_giacente']),
        impegnato: _str(json['impegnato']),
        disponibile: _str(json['disponibile']),
        giacenteTot: _str(json['giacente_tot']),
        inOrdinePrd: _str(json['in_ordine_prd']),
        inOrdineAcq: _str(json['in_ordine_acq']),
        ultimoVersamento: _fmtDate(json['ultimoVersamento']),
        ultimoConsumo: _fmtDate(json['ultimoConsumo']),
        magazzino: _str(json['magazzino']),
        vano: _str(json['vano']),
      );
}
