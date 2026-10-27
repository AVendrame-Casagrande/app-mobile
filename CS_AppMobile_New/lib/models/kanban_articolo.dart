// Modelli articoli Kanban — porting di
// www/scripts/Kanban/Classi/Articolo.js e Scaffale.js.

String _str(dynamic v) => (v ?? '').toString();

/// Articolo presente in uno scaffale (selectArticoliScaffale.php).
class ArticoloScaffale {
  final String codice;
  final String descrizione;
  final String qtaConfezione;
  final String tipo;
  final String fornitore;

  ArticoloScaffale({
    this.codice = '',
    this.descrizione = '',
    this.qtaConfezione = '',
    this.tipo = '',
    this.fornitore = '',
  });

  factory ArticoloScaffale.fromJson(Map<String, dynamic> json) => ArticoloScaffale(
        codice: _str(json['codice']),
        descrizione: _str(json['descrizione']),
        qtaConfezione: _str(json['qtaConfezione']),
        tipo: _str(json['tipo']),
        fornitore: _str(json['fornitore']),
      );
}

/// Scaffale in cui è presente un articolo (dentro ArticoloKanban).
class ScaffaloArticolo {
  final String codice;
  final String descrizione;
  final String magazzino;

  ScaffaloArticolo({this.codice = '', this.descrizione = '', this.magazzino = ''});

  factory ScaffaloArticolo.fromJson(Map<String, dynamic> json) => ScaffaloArticolo(
        codice: _str(json['codiceScaffale']),
        descrizione: _str(json['descrizioneScaffale']),
        magazzino: _str(json['magazzinoScaffale']),
      );
}

/// Articolo Kanban (selectSingoloArticolo.php con addScaffaliPhp).
class ArticoloKanban {
  final String codice;
  final String descrizione;
  final String unitaMisura;
  final String societa;
  final String fornitore;
  final String fornitoreDescrizione;
  final String qtaConfezione;
  final String immagine;
  final String tipo;
  final String trattamento;
  final String colore;
  final String scortaMinima;
  final List<ScaffaloArticolo> listaScaffali;

  ArticoloKanban({
    this.codice = '',
    this.descrizione = '',
    this.unitaMisura = '',
    this.societa = '',
    this.fornitore = '',
    this.fornitoreDescrizione = '',
    this.qtaConfezione = '',
    this.immagine = '',
    this.tipo = '',
    this.trattamento = '',
    this.colore = '',
    this.scortaMinima = '',
    this.listaScaffali = const [],
  });

  bool get trovato => codice.isNotEmpty;

  /// Tipo 'N' = articolo Kanban (richiesto per il rifornimento).
  bool get isKanban => tipo == 'N';

  factory ArticoloKanban.fromJson(Map<String, dynamic> json) {
    final scaffali = <ScaffaloArticolo>[];
    final raw = json['listaScaffali'];
    if (raw is List) {
      for (final s in raw.whereType<Map>()) {
        scaffali.add(ScaffaloArticolo.fromJson(Map<String, dynamic>.from(s)));
      }
    }
    return ArticoloKanban(
      codice: _str(json['codice']),
      descrizione: _str(json['descrizione']),
      unitaMisura: _str(json['unitaMisura']),
      societa: _str(json['societa']),
      fornitore: _str(json['fornitore']),
      fornitoreDescrizione: _str(json['fornitoreDescrizione']),
      qtaConfezione: _str(json['qtaConfezione']),
      immagine: _str(json['immagine']),
      tipo: _str(json['tipo']),
      trattamento: _str(json['trattamento']),
      colore: _str(json['colore']),
      scortaMinima: _str(json['scorta_minima']),
      listaScaffali: scaffali,
    );
  }

  Map<String, dynamic> toJson() => {
        'codice': codice,
        'descrizione': descrizione,
        'unitaMisura': unitaMisura,
        'societa': societa,
        'fornitore': fornitore,
        'fornitoreDescrizione': fornitoreDescrizione,
        'qtaConfezione': qtaConfezione,
        'immagine': immagine,
        'tipo': tipo,
        'trattamento': trattamento,
        'colore': colore,
        'scorta_minima': scortaMinima,
        'listaScaffali': const [],
        'listaGiacenzeMgaut': const [],
      };
}
