import 'package:intl/intl.dart';

/// Modello Giacenza Inventario — porting di
/// www/scripts/Giacenze-Magazzino/Classi/GiacenzaInventario.js.
/// Rappresenta una riga di giacenza per magazzino/vano.

DateFormat _ymd = DateFormat('yyyy-MM-dd');
DateFormat _dmy = DateFormat('d/M/yy');

/// Le date arrivano dall'API come numero yyyyMMdd (MASAINV.MRLD / MILD),
/// eventualmente come double ("20240512.0"); 0 = nessuna data → '-'.
/// Formato in uscita come in Cordova: moment(...).format('D/M/YY').
String _fmtDate(dynamic raw) {
  var s = (raw ?? '').toString().trim();
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  if (s.isEmpty || s == '0') return '-';
  final soloCifre = RegExp(r'^\d{8}$');
  if (soloCifre.hasMatch(s)) {
    final d = DateTime.tryParse(
        '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}');
    if (d != null) return _dmy.format(d);
  }
  try {
    return _dmy.format(_ymd.parse(s));
  } catch (_) {
    return s;
  }
}

String _str(dynamic v) {
  if (v == null) return '';
  // I double interi (es. 12.0) vengono mostrati senza decimali, come in JS.
  if (v is double && v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}

/// Converte una quantità testuale in numero (0 se non valida).
double _toNum(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

/// Formatta una quantità calcolata eliminando il rumore dei float.
String formatQtaGiacenza(num v) {
  final r = (v * 1000).roundToDouble() / 1000;
  if (r == r.roundToDouble()) return r.toInt().toString();
  return r.toString();
}

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

  /// Quantità impegnata sugli altri magazzini, calcolata come in Cordova
  /// (GiacenzaInventario/EventHandlers.js):
  /// giacente_tot + in_ordine_acq + in_ordine_prd - disponibile - impegnato.
  double get impegnataAltriMagazzini =>
      _toNum(giacenteTot) +
      _toNum(inOrdineAcq) +
      _toNum(inOrdinePrd) -
      _toNum(disponibile) -
      _toNum(impegnato);
}
