import '../core/config.dart';
import 'utente.dart';

/// Modello messaggio chat — porting di www/scripts/Classi/Message.js.
class ChatMessage {
  int id;
  String messaggio;
  String senderid;
  String receiverid;
  int dataInvio; // YYYYMMDD
  int oraInvio; // HHmmss
  bool letto;
  int dataLettura;
  int oraLettura;
  String tipo; // 'inviato' | 'ricevuto'
  String tipoMessaggio; // 'normale' | 'testo' | 'foto'
  String nascostoRicevuto; // 't'|'f'
  String nascostoInviato; // 't'|'f'
  String urlFoto;
  String senderidGroup;

  ChatMessage({
    this.id = 0,
    this.messaggio = '',
    this.senderid = '',
    this.receiverid = '',
    this.dataInvio = 0,
    this.oraInvio = 0,
    this.letto = false,
    this.dataLettura = 0,
    this.oraLettura = 0,
    this.tipo = '',
    this.tipoMessaggio = '',
    this.nascostoRicevuto = 'f',
    this.nascostoInviato = 'f',
    this.urlFoto = '',
    this.senderidGroup = '',
  });

  bool get isFoto => tipoMessaggio == 'foto';

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    final s = (v ?? '').toString().toLowerCase();
    return s == 't' || s == 'true' || s == '1';
  }

  static String _str(dynamic v) => (v ?? '').toString();

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: _toInt(json['id']),
        messaggio: _str(json['messaggio']),
        senderid: _str(json['senderid']),
        receiverid: _str(json['receiverid']),
        dataInvio: _toInt(json['data_invio']),
        oraInvio: _toInt(json['ora_invio']),
        letto: _toBool(json['letto']),
        dataLettura: _toInt(json['data_lettura']),
        oraLettura: _toInt(json['ora_lettura']),
        tipo: _str(json['tipo']),
        tipoMessaggio: _str(json['tipo_messaggio']),
        nascostoRicevuto: _str(json['nascosto_ricevuto']).isEmpty
            ? 'f'
            : _str(json['nascosto_ricevuto']),
        nascostoInviato: _str(json['nascosto_inviato']).isEmpty
            ? 'f'
            : _str(json['nascosto_inviato']),
        urlFoto: _str(json['url_foto']),
        senderidGroup: _str(json['senderid_group']),
      );

  /// Serializzazione per writeMessage.php (come l'oggetto Message dell'originale).
  Map<String, dynamic> toJson() => {
        'id': id,
        'messaggio': messaggio,
        'senderid': senderid,
        'receiverid': receiverid,
        'data_invio': dataInvio,
        'ora_invio': oraInvio,
        'letto': letto,
        'data_lettura': dataLettura,
        'ora_lettura': oraLettura,
        'tipo': tipo,
        'tipo_messaggio': tipoMessaggio,
        'nascosto_ricevuto': nascostoRicevuto,
        'nascosto_inviato': nascostoInviato,
        'url_foto': urlFoto,
        'senderid_group': senderidGroup,
      };

  /// Chiave di ordinamento temporale (data+ora) per confronti.
  int get timestamp => dataInvio * 1000000 + oraInvio;

  /// URL completo della foto (se è un messaggio foto).
  String get fotoUrl {
    if (urlFoto.isEmpty) return '';
    if (urlFoto.startsWith('http')) return urlFoto;
    // upload_foto salva il file come <name>.jpg, mentre url_foto è senza estensione.
    final file = urlFoto.toLowerCase().endsWith('.jpg') ? urlFoto : '$urlFoto.jpg';
    return '${AppConfig.storageUrl}/chat_foto/$file';
  }
}

/// Conversazione con un utente o gruppo — porting di SavedMessagesPerUser.
class Conversazione {
  Utente utente;
  final List<ChatMessage> messaggi;

  Conversazione({Utente? utente, List<ChatMessage>? messaggi})
      : utente = utente ?? Utente(),
        messaggi = messaggi ?? [];

  ChatMessage? get ultimoMessaggio => messaggi.isEmpty ? null : messaggi.last;

  int get dataUltimoMessaggio => ultimoMessaggio?.dataInvio ?? 0;
  int get oraUltimoMessaggio => ultimoMessaggio?.oraInvio ?? 0;

  bool get isGruppo => utente.accountType == 'Group';

  /// Numero di messaggi ricevuti non letti.
  int get nonLetti =>
      messaggi.where((m) => m.tipo == 'ricevuto' && !m.letto).length;

  /// Anteprima testuale dell'ultimo messaggio (per la lista chat).
  String get anteprima {
    final m = ultimoMessaggio;
    if (m == null) return '';
    if (m.isFoto) return '📷 Foto';
    var t = m.messaggio;
    t = t.replaceAll(RegExp(r'</?b>'), '');
    if (t.length > 40) t = '${t.substring(0, 40)}…';
    return t;
  }

  /// URL immagine profilo/gruppo.
  String get immagineUrl {
    if (utente.immagine.isEmpty) return '';
    if (isGruppo || utente.immagine.startsWith('http')) return utente.immagine;
    return '${AppConfig.profileFotoPath}/${utente.immagine}.jpg';
  }
}
