import '../core/network/api_client.dart';
// Righe delle liste di prelievo verso il magazzino automatico — porting delle
// classi Automha_Ordine (liste MGAUT00/MGAUT10) e RigaPrelievo24_34
// (liste da Attività fase 0027/0034) di
// www/scripts/Giacenze-Magazzino/Classi/Mgaut.js.

/// Riga di una lista MGAUT00 / MGAUT10 compilata sul dispositivo e inviata
/// con WriteListaMagazzinoAutomatico.php (tipo_interfaccia PRELMAN/PRELODL/PRELODV).
class RigaListaAut {
  String tipoprel; // 'MAN', 'ODL', 'ODV'
  String rifprel; // ODL / ODV
  String subrifprel; // fase
  String usrcrea; // nomePortale
  String articolo;
  String descarticolo;
  num qta;
  String umis;
  String vanoto;
  num qtaconf;
  String magfrom; // MGAUT00 / MGAUT10
  String magto;
  String fase;
  String descfase;
  String artpadre;
  String descartpadre;
  String cliente;
  String nomecliente;
  int pos;
  int seq;
  bool vanoRequired;

  RigaListaAut({
    required this.tipoprel,
    this.rifprel = '',
    this.subrifprel = '',
    this.usrcrea = '',
    required this.articolo,
    this.descarticolo = '',
    this.qta = 0,
    this.umis = '',
    this.vanoto = '',
    this.qtaconf = 0,
    required this.magfrom,
    this.magto = '',
    this.fase = '',
    this.descfase = '',
    this.artpadre = '',
    this.descartpadre = '',
    this.cliente = '',
    this.nomecliente = '',
    this.pos = 0,
    this.seq = 0,
    this.vanoRequired = false,
  });

  RigaListaAut copyWith({String? magfrom}) => RigaListaAut(
        tipoprel: tipoprel,
        rifprel: rifprel,
        subrifprel: subrifprel,
        usrcrea: usrcrea,
        articolo: articolo,
        descarticolo: descarticolo,
        qta: qta,
        umis: umis,
        vanoto: vanoto,
        qtaconf: qtaconf,
        magfrom: magfrom ?? this.magfrom,
        magto: magto,
        fase: fase,
        descfase: descfase,
        artpadre: artpadre,
        descartpadre: descartpadre,
        cliente: cliente,
        nomecliente: nomecliente,
        pos: pos,
        seq: seq,
        vanoRequired: vanoRequired,
      );

  /// Stessi nomi delle proprietà della classe JS (letti dal PHP).
  Map<String, dynamic> toJson() => {
        'societa': AuthToken.societa,
        'tipoprel': tipoprel,
        'rifprel': rifprel,
        'subrifprel': subrifprel,
        'usrcrea': usrcrea,
        'articolo': articolo,
        'descarticolo': descarticolo,
        'qta': qta,
        'umis': umis,
        'vanoto': vanoto,
        'qtaconf': qtaconf,
        'magfrom': magfrom,
        'magto': magto,
        'fase': fase,
        'descfase': descfase,
        'artpadre': artpadre,
        'descartpadre': descartpadre,
        'cliente': cliente,
        'nomecliente': nomecliente,
        'mancanteOrigine': null,
        'pos': pos,
        'seq': seq,
        'vano_required': vanoRequired,
      };
}

/// Riga di prelievo fase 0027/0034 ricavata da un'Attività.
class RigaPrelievo0027 {
  final String odl;
  final String magazzinoimpegno;
  String? magdispo; // MGAUT00 / MGAUT10, null = MISK (non automatica)
  final String articolo;
  String descarticolo = '';
  String umis = '';
  final String fase;
  final num qta;
  num? giacenteReparto;
  num? impegnatoReparto;
  final int dataCreazioneAttivita;
  bool articoloDaVisualizzare = true;
  bool selezionato = false;

  RigaPrelievo0027({
    required this.odl,
    required this.magazzinoimpegno,
    required this.articolo,
    required this.fase,
    required this.qta,
    required this.dataCreazioneAttivita,
  });

  bool get isMisk => magdispo == null;

  /// Giallo nell'originale: l'impegno in reparto è coperto dalla giacenza.
  bool get impegnoCoperto =>
      giacenteReparto != null &&
      impegnatoReparto != null &&
      giacenteReparto! >= impegnatoReparto!;

  Map<String, dynamic> toJson() => {
        'odl': odl,
        'magazzinoimpegno': magazzinoimpegno,
        'magdispo': magdispo,
        'articolo': articolo,
        'descarticolo': descarticolo,
        'umis': umis,
        'fase': fase,
        'qta_0027_or_0034': qta,
        'qta': qta,
        'lista_altre_fasi_qta': const [],
        'giacente_reparto': giacenteReparto,
        'impegnato_reparto': impegnatoReparto,
        'isVisible_giacenza_impegnato': true,
        'vanoto': '',
        'giacdispo': qta,
        'selezionato': selezionato,
        'fromAttivita': true,
        'dataCreazioneAttivita': dataCreazioneAttivita,
        'articoloDaVisualizzare': articoloDaVisualizzare,
      };
}

/// String.substring di JavaScript: indici limitati a [0, length] e scambiati
/// se start > end (serve per replicare il parsing dei testi delle Attività).
String jsSubstring(String s, int start, [int? end]) {
  var a = start.clamp(0, s.length);
  var b = (end ?? s.length).clamp(0, s.length);
  if (a > b) {
    final t = a;
    a = b;
    b = t;
  }
  return s.substring(a, b);
}

/// Dati di un'Attività di prelievo, nel formato
/// "F.0027 || Art: X | Odl: Y | A: MAG | Q.ta: N" — porting delle estrazioni
/// fatte in drawInnerPage0027 e completaAttivita0027.
class AvvisoPrelievo {
  final String fase;
  final String articolo;
  final String odl;
  final String magDest;
  final String qta;
  const AvvisoPrelievo(this.fase, this.articolo, this.odl, this.magDest, this.qta);

  static bool isPrelievo(String s) =>
      s.contains('F.') &&
      s.contains('||') &&
      s.contains('Art:') &&
      s.contains('Odl:') &&
      s.contains('A:') &&
      s.contains('Q.ta:');

  factory AvvisoPrelievo.parse(String s) {
    String tra(String fine, String inizio, int salta) => jsSubstring(
            jsSubstring(jsSubstring(s, 0, s.indexOf(fine)), s.indexOf(inizio), s.length),
            salta)
        .trim();
    return AvvisoPrelievo(
      jsSubstring(s, 2, 6),
      tra('| Odl', 'Art:', 5),
      tra('| A:', 'Odl:', 5),
      tra('| Q.ta:', 'A:', 3),
      jsSubstring(jsSubstring(s, s.length, s.indexOf('| Q.ta:')), 8).trim(),
    );
  }
}
