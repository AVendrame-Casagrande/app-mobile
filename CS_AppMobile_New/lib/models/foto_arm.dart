/// Modello FotoArm — porting di www/scripts/FotoArm/FotoArm.js.
/// Rappresenta un ordine ARM (numero, cliente, causale).
class FotoArm {
  final String numero;
  final String cliente;
  final String causale;

  FotoArm({this.numero = '', this.cliente = '', this.causale = ''});

  factory FotoArm.fromJson(Map<String, dynamic> json) {
    String norm(dynamic v) => (v ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return FotoArm(
      numero: (json['numero'] ?? '').toString(),
      cliente: norm(json['cliente']),
      causale: norm(json['causale']),
    );
  }
}
