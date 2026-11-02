import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../models/chat_message.dart';
import '../../models/utente.dart';
import 'chat_service.dart';

/// Controller della Chat (ChangeNotifier) — porting della logica di
/// www/scripts/Chat/Chat.js (checkChat, getAllChats, stream, invio).
class ChatController extends ChangeNotifier {
  ChatController({required ChatService service, required this.utenteLoggato})
      : _service = service;

  final ChatService _service;
  final Utente utenteLoggato;

  String get _me => utenteLoggato.codiceUtente;

  bool loading = false;
  String? error;

  /// Tutti gli utenti/gruppi contattabili.
  final List<Utente> utentiTotali = [];
  final Set<String> _groupIds = {};

  /// Conversazioni costruite dai messaggi.
  final List<Conversazione> conversazioni = [];

  StreamSubscription<List<ChatMessage>>? _streamSub;
  Timer? _riconnessione;
  bool _chiuso = false;

  /// true dopo il primo caricamento riuscito (il controller vive per tutta la sessione).
  bool caricato = false;

  /// Conversazione aperta a schermo: i suoi nuovi messaggi si segnano subito come letti.
  String? conversazioneAperta;

  /// Nuovi messaggi ricevuti e non letti arrivati dallo stream (per popup e notifiche).
  void Function(List<ChatMessage> nuovi)? onNuoviMessaggi;

  bool isGroup(String id) => _groupIds.contains(id);

  /// Nome da mostrare per un utente o gruppo.
  String nomeUtente(String id) => _utenteById(id).nomeUtente;

  // -------------------------------------------------------------------------
  // Caricamento iniziale: utenti + gruppi + tutte le chat.
  // -------------------------------------------------------------------------
  Future<void> caricaTutto() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // 1) Utenti (escludo me stesso)
      final users = await _service.getUsersList();
      utentiTotali
        ..clear()
        ..addAll(users.where((u) => u.codiceUtente != _me));

      // 2) Gruppi
      final gruppi = await _service.getElencoGruppiChat(_me);
      _groupIds.clear();
      for (final g in gruppi) {
        final codice = (g['codice'] ?? '').toString();
        if (codice.isEmpty) continue;
        _groupIds.add(codice);
        utentiTotali.add(Utente(
          codiceUtente: codice,
          nomeUtente: (g['nome'] ?? codice).toString(),
          nomePortale: (g['portale'] ?? '').toString(),
          accountType: 'Group',
        ));
      }

      // 3) Tutte le chat
      final tutti = await _service.getAllChats(_me);
      _costruisciConversazioni(tutti);

      loading = false;
      caricato = true;
      notifyListeners();

      // 4) Avvio lo stream realtime
      _avviaStream();
    } catch (e) {
      loading = false;
      error = 'Errore: impossibile contattare il server della Chat';
      notifyListeners();
      // Senza il primo caricamento non c'è stream: si riprova finché la sessione è aperta.
      _riconnessione?.cancel();
      _riconnessione = Timer(const Duration(seconds: 60), () {
        if (!_chiuso && !caricato) caricaTutto();
      });
    }
  }

  // -------------------------------------------------------------------------
  // Costruzione conversazioni da una lista di messaggi grezzi.
  // -------------------------------------------------------------------------
  void _costruisciConversazioni(List<ChatMessage> messaggi) {
    conversazioni.clear();
    final byOther = <String, List<ChatMessage>>{};

    for (final m in messaggi) {
      _normalizzaGruppo(m);
      final otherId = m.senderid != _me ? m.senderid : m.receiverid;
      // tipo relativo all'altro interlocutore
      m.tipo = m.receiverid == otherId ? 'inviato' : 'ricevuto';
      byOther.putIfAbsent(otherId, () => []).add(m);
    }

    byOther.forEach((otherId, msgs) {
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      conversazioni.add(Conversazione(
        utente: _utenteById(otherId),
        messaggi: msgs,
      ));
    });

    _ordinaConversazioni();
  }

  /// Applica lo swap dei messaggi di gruppo (come nell'originale).
  void _normalizzaGruppo(ChatMessage m) {
    if (isGroup(m.receiverid) && m.senderid != _me) {
      final receiver = m.receiverid;
      m.senderidGroup = m.senderid;
      m.senderid = receiver;
      m.receiverid = _me;
    }
  }

  Utente _utenteById(String id) {
    for (final u in utentiTotali) {
      if (u.codiceUtente == id) return u;
    }
    return Utente(codiceUtente: id, nomeUtente: id);
  }

  void _ordinaConversazioni() {
    conversazioni.sort((a, b) {
      if (b.dataUltimoMessaggio != a.dataUltimoMessaggio) {
        return b.dataUltimoMessaggio.compareTo(a.dataUltimoMessaggio);
      }
      return b.oraUltimoMessaggio.compareTo(a.oraUltimoMessaggio);
    });
  }

  int get totaleNonLetti =>
      conversazioni.fold(0, (sum, c) => sum + c.nonLetti);

  Conversazione? conversazioneCon(String codiceUtente) {
    for (final c in conversazioni) {
      if (c.utente.codiceUtente == codiceUtente) return c;
    }
    return null;
  }

  /// Restituisce (creandola se serve) la conversazione con un utente.
  Conversazione apriOCreaConversazione(Utente utente) {
    final esistente = conversazioneCon(utente.codiceUtente);
    if (esistente != null) return esistente;
    final nuova = Conversazione(utente: utente);
    conversazioni.add(nuova);
    _ordinaConversazioni();
    notifyListeners();
    return nuova;
  }

  // -------------------------------------------------------------------------
  // Stream realtime.
  // -------------------------------------------------------------------------
  void _avviaStream() {
    _streamSub?.cancel();
    _streamSub = _service.openStream(_me).listen(
      _gestisciNuoviMessaggi,
      onError: (_) {},
      // Il server chiude lo stream dopo 10 minuti (o su errore di rete):
      // ci si riconnette come faceva EventSource nell'originale.
      onDone: () {
        if (_chiuso) return;
        _riconnessione?.cancel();
        _riconnessione = Timer(const Duration(seconds: 5), () {
          if (!_chiuso) _avviaStream();
        });
      },
      cancelOnError: false,
    );
  }

  void _gestisciNuoviMessaggi(List<ChatMessage> nuovi) {
    var cambiato = false;
    final daNotificare = <ChatMessage>[];
    for (final m in nuovi) {
      final isIncoming = (m.receiverid == _me && m.nascostoRicevuto == 'f') ||
          (isGroup(m.receiverid) && m.senderid != _me);
      if (isIncoming) {
        _normalizzaGruppo(m);
        final otherId = m.senderid;
        var conv = conversazioneCon(otherId);
        if (conv == null) {
          conv = Conversazione(utente: _utenteById(otherId));
          conversazioni.add(conv);
        }
        // Evito duplicati per id
        if (m.id != 0 && conv.messaggi.any((x) => x.id == m.id)) continue;
        m.tipo = 'ricevuto';
        conv.messaggi.add(m);
        conv.messaggi.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        cambiato = true;
        if (!m.letto) daNotificare.add(m);
      } else if (m.senderid == _me && m.letto) {
        // Ricevuta di lettura di un mio messaggio.
        for (final c in conversazioni) {
          for (final x in c.messaggi) {
            if (x.id == m.id && !x.letto) {
              x.letto = true;
              cambiato = true;
            }
          }
        }
      }
    }
    if (cambiato) {
      _ordinaConversazioni();
      notifyListeners();
    }

    // Conversazione aperta: i messaggi si leggono subito, niente popup.
    final aperta = conversazioneAperta == null ? null : conversazioneCon(conversazioneAperta!);
    if (aperta != null && daNotificare.any((m) => m.senderid == aperta.utente.codiceUtente)) {
      segnaLetti(aperta);
      daNotificare.removeWhere((m) => m.senderid == aperta.utente.codiceUtente);
    }
    if (daNotificare.isNotEmpty) onNuoviMessaggi?.call(daNotificare);
  }

  // -------------------------------------------------------------------------
  // Invio messaggio.
  // -------------------------------------------------------------------------
  Future<void> inviaMessaggio(Conversazione conv, String testo) async {
    final t = testo.trim();
    if (t.isEmpty) return;

    final now = DateTime.now();
    final msg = ChatMessage(
      messaggio: t,
      senderid: _me,
      receiverid: conv.utente.codiceUtente,
      dataInvio: int.parse(DateFormat('yyyyMMdd').format(now)),
      oraInvio: int.parse(DateFormat('HHmmss').format(now)),
      tipo: 'inviato',
      tipoMessaggio: 'normale',
    );

    // Inserimento ottimistico.
    conv.messaggi.add(msg);
    _ordinaConversazioni();
    notifyListeners();

    try {
      final id = await _service.sendMessage(msg);
      msg.id = id;
    } catch (_) {
      // In caso di errore segnalo ma lascio il messaggio (come retry originale).
      error = 'Invio non riuscito';
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Invio foto: upload + messaggio di tipo 'foto'.
  // url_foto = YYYYMMDDHHmmss_<sender>_<receiver> (come l'originale).
  // -------------------------------------------------------------------------
  Future<bool> inviaFoto(Conversazione conv, Uint8List bytes) async {
    final receiver = conv.utente.codiceUtente;
    final ora = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final urlFoto = '${ora}_${_me}_$receiver';
    try {
      final ok = await _service.uploadFoto(urlFoto, bytes);
      if (!ok) return false;

      final now = DateTime.now();
      final msg = ChatMessage(
        messaggio: '',
        senderid: _me,
        receiverid: receiver,
        dataInvio: int.parse(DateFormat('yyyyMMdd').format(now)),
        oraInvio: int.parse(DateFormat('HHmmss').format(now)),
        tipo: 'inviato',
        tipoMessaggio: 'foto',
        urlFoto: urlFoto,
      );
      conv.messaggi.add(msg);
      _ordinaConversazioni();
      notifyListeners();

      final id = await _service.sendMessage(msg);
      msg.id = id;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Segna come letti i messaggi ricevuti di una conversazione.
  // -------------------------------------------------------------------------
  Future<void> segnaLetti(Conversazione conv) async {
    final privati = <int>[];
    final gruppo = <int>[];
    for (final m in conv.messaggi) {
      if (m.tipo == 'ricevuto' && !m.letto && m.id != 0) {
        m.letto = true;
        if (conv.isGruppo) {
          gruppo.add(m.id);
        } else {
          privati.add(m.id);
        }
      }
    }
    if (privati.isEmpty && gruppo.isEmpty) return;
    notifyListeners();
    try {
      await _service.updateMessagesRead(privati);
      await _service.updateMessagesReadGruppo(_me, gruppo);
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Elimina messaggio.
  // -------------------------------------------------------------------------
  Future<bool> eliminaMessaggio(Conversazione conv, ChatMessage m) async {
    try {
      final ok = await _service.deleteMessage(m.id);
      if (ok) {
        conv.messaggi.removeWhere((x) => x.id == m.id);
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _chiuso = true;
    _riconnessione?.cancel();
    _streamSub?.cancel();
    _service.closeStream();
    super.dispose();
  }
}
