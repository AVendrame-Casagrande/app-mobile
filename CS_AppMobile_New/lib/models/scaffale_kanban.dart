/// Modello Scaffale Kanban — porting di
/// www/scripts/Kanban/Classi/Scaffale.js.
class ScaffaleKanban {
  final String codice;
  final String descrizione;
  final String magazzino;
  final String societa;
  final String qtaCella;

  ScaffaleKanban({
    this.codice = '',
    this.descrizione = '',
    this.magazzino = '',
    this.societa = '',
    this.qtaCella = '',
  });

  factory ScaffaleKanban.fromJson(Map<String, dynamic> json) => ScaffaleKanban(
        codice: (json['codice'] ?? '').toString(),
        descrizione: (json['descrizione'] ?? '').toString(),
        magazzino: (json['magazzino'] ?? '').toString(),
        societa: (json['societa'] ?? '').toString(),
        qtaCella: (json['qtaCella'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'codice': codice,
        'descrizione': descrizione,
        'magazzino': magazzino,
        'societa': societa,
        'qtaCella': qtaCella,
        'listaArticoli': const [],
      };
}
