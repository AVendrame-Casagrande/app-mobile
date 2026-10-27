import 'package:intl/intl.dart';

import '../core/utils/date_format.dart';

// Modelli Inventario — porting di
// www/scripts/Giacenze-Magazzino/Classi/Inventario.js.

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
}

int _int(dynamic v) => _num(v).toInt();
String _str(dynamic v) => (v ?? '').toString();

/// Testata di una lista di inventario (getElencoListe.php).
class InventarioTestata {
  final int id;
  final int stato; // 0 = aperta, >0 = chiusa/confermata
  final String nomeLista;
  final String tipoLista; // 'magazzino', 'vano_preciso' o 'vano_radice'
  final String dataCreazione; // formattata dd/MM/yyyy
  final String oraCreazione; // formattata HH:mm
  final String utenteCreazione;
  final String utenteChiusura;

  InventarioTestata({
    this.id = 0,
    this.stato = 0,
    this.nomeLista = '',
    this.tipoLista = '',
    this.dataCreazione = '',
    this.oraCreazione = '',
    this.utenteCreazione = '',
    this.utenteChiusura = '',
  });

  bool get aperta => stato == 0;

  /// Abbreviazione del tipo lista (getTipoListaAbbreviata).
  String get tipoAbbreviato => tipoListaAbbreviato(tipoLista);

  factory InventarioTestata.fromJson(Map<String, dynamic> json) {
    String data = formatData(json['data_creazione']);
    String ora = _str(json['ora_creazione']);
    try {
      ora = DateFormat('HH:mm').format(DateFormat('HH:mm:ss').parse(ora));
    } catch (_) {}
    return InventarioTestata(
      id: _int(json['id']),
      stato: _int(json['stato']),
      nomeLista: _str(json['nome_lista']),
      tipoLista: _str(json['tipo_lista']),
      dataCreazione: data,
      oraCreazione: ora,
      utenteCreazione: _str(json['utente_creazione']),
      utenteChiusura: _str(json['utente_chiusura']),
    );
  }
}

/// Riga di una lista di inventario (getInventarioFullQuery.php → listaRighe)
/// o giacenza rimasta da confermare. Mutabile come l'oggetto JS originale:
/// stato, quantità, foto e nota vengono modificati localmente prima della
/// conferma (writeRigaLista.php).
class InventarioRiga {
  int id;
  int idListaTestata;
  String articolo;
  String descrizione;
  String magazzino;
  String vanoOriginale;
  String vanoModificato;
  num qtaOriginale;
  num qtaModificata;
  String urlFoto;
  int stato; // 1 = Conforme, 2 = Ricondizionare, 3 = Rottamare, >3 = Analizzato
  String utenteInserimento;
  int dataInserimento;
  int oraInserimento;
  int rigaAggiuntaManualmente;
  String nota;
  String um;

  InventarioRiga({
    this.id = 0,
    this.idListaTestata = 0,
    this.articolo = '',
    this.descrizione = '',
    this.magazzino = '',
    this.vanoOriginale = '',
    this.vanoModificato = '',
    this.qtaOriginale = 0,
    this.qtaModificata = 0,
    this.urlFoto = '',
    this.stato = 0,
    this.utenteInserimento = '',
    this.dataInserimento = 0,
    this.oraInserimento = 0,
    this.rigaAggiuntaManualmente = 0,
    this.nota = '',
    this.um = '',
  });

  bool get aggiuntaManualmente => rigaAggiuntaManualmente == 1;
  bool get haFoto => urlFoto.isNotEmpty;
  bool get analizzato => stato > 3;

  factory InventarioRiga.fromJson(Map<String, dynamic> json) => InventarioRiga(
        id: _int(json['id']),
        idListaTestata: _int(json['id_lista_testata']),
        articolo: _str(json['articolo']),
        descrizione: _str(json['descrizione']),
        magazzino: _str(json['magazzino']),
        vanoOriginale: _str(json['vano_originale']),
        vanoModificato: _str(json['vano_modificato']),
        qtaOriginale: _num(json['qta_originale']),
        qtaModificata: _num(json['qta_modificata']),
        urlFoto: _str(json['url_foto']),
        stato: _int(json['stato']),
        utenteInserimento: _str(json['utente_inserimento']),
        dataInserimento: _int(json['data_inserimento']),
        oraInserimento: _int(json['ora_inserimento']),
        rigaAggiuntaManualmente: _int(json['riga_aggiunta_manualmente']),
        nota: _str(json['nota']),
        um: _str(json['um']),
      );

  /// Riga creata dalle giacenze rimaste (listaGiacenze).
  factory InventarioRiga.fromGiacenza(Map<String, dynamic> json, int idLista) =>
      InventarioRiga(
        id: 0,
        idListaTestata: idLista,
        articolo: _str(json['articolo']),
        descrizione: _str(json['descrizione']),
        magazzino: _str(json['magazzino']),
        vanoOriginale: _str(json['vano']),
        vanoModificato: _str(json['vano']),
        qtaOriginale: _num(json['qta_giacente']),
        qtaModificata: _num(json['qta_giacente']),
        urlFoto: _str(json['url_foto']),
        stato: 1,
        um: _str(json['um']),
      );

  /// Copia profonda (come JSON.parse(JSON.stringify(riga)) nell'originale).
  InventarioRiga copy() => InventarioRiga.fromJson(toJson());

  /// Serializzazione per writeRigaLista.php (stessi nomi della classe JS).
  Map<String, dynamic> toJson() => {
        'id': id,
        'id_lista_testata': idListaTestata,
        'articolo': articolo,
        'descrizione': descrizione,
        'magazzino': magazzino,
        'vano_originale': vanoOriginale,
        'vano_modificato': vanoModificato,
        'qta_originale': qtaOriginale,
        'qta_modificata': qtaModificata,
        'url_foto': urlFoto,
        'stato': stato,
        'utente_inserimento': utenteInserimento,
        'data_inserimento': dataInserimento,
        'ora_inserimento': oraInserimento,
        'riga_aggiunta_manualmente': rigaAggiuntaManualmente,
        'nota': nota,
        'um': um,
        'isUploaded': true,
      };
}

/// Porting di getTipoListaAbbreviata() (Inventario.js).
String tipoListaAbbreviato(String tipoLista) {
  switch (tipoLista) {
    case 'magazzino':
      return 'M';
    case 'vano_preciso':
      return 'VP';
    case 'vano_radice':
      return 'VR';
  }
  return tipoLista;
}

/// Contenuto completo di una lista (righe salvate + giacenze rimaste).
class InventarioContenuto {
  final List<InventarioRiga> righe;
  final List<InventarioRiga> giacenzeRimaste;

  InventarioContenuto({this.righe = const [], this.giacenzeRimaste = const []});
}
