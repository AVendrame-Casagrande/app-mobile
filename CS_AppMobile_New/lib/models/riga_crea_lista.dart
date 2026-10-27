// Modello riga di Crea Lista (lista libera inventario CSUSA) — porting di
// www/scripts/Giacenze-Magazzino/Pagine/CreaLista.

class RigaCreaLista {
  final String articolo;
  final String descrizione;
  String qta;
  String note;
  String image;
  final String user;
  final String data;
  final String ora;

  RigaCreaLista({
    this.articolo = '',
    this.descrizione = '',
    this.qta = '',
    this.note = '',
    this.image = '',
    this.user = '',
    this.data = '',
    this.ora = '',
  });

  Map<String, dynamic> toJson() => {
        'articolo': articolo,
        'descrizione': descrizione,
        'qta': qta,
        'note': note,
        'image': image,
        'user': user,
        'data': data,
        'ora': ora,
      };

  factory RigaCreaLista.fromJson(Map<String, dynamic> json) => RigaCreaLista(
        articolo: (json['articolo'] ?? '').toString(),
        descrizione: (json['descrizione'] ?? '').toString(),
        qta: (json['qta'] ?? '').toString(),
        note: (json['note'] ?? '').toString(),
        image: (json['image'] ?? '').toString(),
        user: (json['user'] ?? '').toString(),
        data: (json['data'] ?? '').toString(),
        ora: (json['ora'] ?? '').toString(),
      );

  /// Riga nel formato atteso dall'excel CSUSA (write_inventory_excel.php).
  Map<String, dynamic> toExcelRow() => {
        'articolo': articolo,
        'descrizione': descrizione.toLowerCase(),
        'qta': qta,
        'note': note,
        'image': image,
        'user': user,
        'data': data,
        'ora': ora,
      };
}
