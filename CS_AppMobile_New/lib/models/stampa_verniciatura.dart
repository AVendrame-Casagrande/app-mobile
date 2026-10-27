import 'package:intl/intl.dart';

/// Modello etichetta di verniciatura — porting di
/// www/scripts/Giacenze-Magazzino/Classi/StampaVerniciatura.js,
/// con il generatore ZPL preso da Stampa.js (stampaEtichettaVerniciatura).
class StampaVerniciatura {
  String magazzinoDestinazione;
  String odlSelected;
  String faseSelected;
  String padre;
  String descrizionePadre;
  String colore;
  String note;
  int qtaEtichetteDaStampare;
  String dataStampa;
  String dataRichiesta;
  bool etichettaIsLibera;

  StampaVerniciatura({
    this.magazzinoDestinazione = '',
    this.odlSelected = '',
    this.faseSelected = '',
    this.padre = '',
    this.descrizionePadre = '',
    this.colore = '',
    this.note = '',
    this.qtaEtichetteDaStampare = 1,
    String? dataStampa,
    this.dataRichiesta = '',
    this.etichettaIsLibera = false,
  }) : dataStampa = dataStampa ?? DateFormat('dd/MM/yy').format(DateTime.now());

  /// Genera l'etichetta in linguaggio ZPL (identica al template Cordova).
  String toZpl({required String codiceUtente}) {
    return '''
    ^XA^LT0^MMT^MNW^MTT^LH0,10^PR5,5~SD30^CI9^JUS^XZ
    ^XA

    ^FX dati padre
    ^FT020,040^A0N,20,20^FDASS:^FS
    ^FT065,040^A0N,30,25^FD$padre^FS
    ^FT220,040^A0N,20,20^FDDES:^FS
    ^FT270,040^A0N,25,20^FD$descrizionePadre^FS

    ^FT020,090^A0N,20,20^FDORD:^FS
    ^FT065,090^A0N,30,25^FD$odlSelected^FS
    ^BY2,2,45^FT220,0100^BCN,,N,N^FD$odlSelected^FS
    ^FT540,090^A0N,20,20^FDFASE:^FS
    ^FT595,090^A0N,30,25^FD$faseSelected^FS
    ^FT670,090^A0N,20,20^FDM.P:^FS
    ^FT715,090^A0N,30,25^FD$magazzinoDestinazione^FS

    ^FT020,0140^A0N,20,20^FDCOL:^FS
    ^FT080,140^A0N,30,25^FD$colore^FS

    ^FX barra separatrice padre / figlio
    ^FO010,0165^GB550,0,2^FS

    ^FT020,215^A0N,20,20^FDNOTA:^FS
    ^FT085,272^A0N,25,25^TBN,510,75^FD$note^FS

    ^FT620,185^A0N,20,20^FDUTENTE:^FS
    ^FT720,185^A0N,25,25^FD$codiceUtente^FS

    ^FT620,225^A0N,20,20^FDD.RICHIES:^FS
    ^FT720,225^A0N,25,25^FD$dataRichiesta^FS

    ^FT620,265^A0N,20,20^FDD.STAMPA:^FS
    ^FT720,265^A0N,25,25^FD$dataStampa^FS

    ^PQ1,0,1,Y
    ^XZ''';
  }
}

/// Voce ODL per la lista (getOdlListFromMagDest.php → {odl, padre, des_padre}).
class OdlStampa {
  final String odl;
  final String padre;
  final String desPadre;

  OdlStampa({this.odl = '', this.padre = '', this.desPadre = ''});

  factory OdlStampa.fromJson(Map<String, dynamic> json) => OdlStampa(
        odl: (json['odl'] ?? '').toString(),
        padre: (json['padre'] ?? '').toString(),
        desPadre: (json['des_padre'] ?? '').toString(),
      );
}

/// Info ODL per l'etichetta (addInfoOdlStampaVern.php).
class InfoOdlStampa {
  final List<String> listaFasi;
  final String padre;
  final String descrizionePadre;
  final String colore;

  InfoOdlStampa({
    this.listaFasi = const [],
    this.padre = '',
    this.descrizionePadre = '',
    this.colore = '',
  });

  factory InfoOdlStampa.fromJson(Map<String, dynamic> json) {
    final fasi = <String>[];
    final raw = json['listaFasi'];
    if (raw is List) {
      // Il server restituisce righe {fase, descrizionefase}: serve il codice fase.
      fasi.addAll(raw.map((e) => e is Map ? (e['fase'] ?? '').toString() : e.toString()));
    }
    return InfoOdlStampa(
      listaFasi: fasi,
      padre: (json['padre'] ?? '').toString(),
      descrizionePadre: (json['descrizionePadre'] ?? '').toString(),
      colore: (json['colore'] ?? '').toString(),
    );
  }
}
