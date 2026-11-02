import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../state/app_state.dart';
import '../giacenze/inventario_dialogs.dart';

/// Prestazioni (Velocità 0027) — porting di ajaxMagazziniForPrestazioni()
/// (www/scripts/Produzione-Odl/Pagine/PaginaPrincipale/EventHandlers.js) e di
/// queryProduzione.queryPrestazioniMagazzino(magazzino, 'prestazioni').
///
/// Sceglie un magazzino tra quelli con inserimenti fase 0027 nell'ultimo mese
/// e mostra il tempo di attesa medio dall'impegno al completamento.
Future<void> apriPrestazioni(BuildContext context) async {
  final api = context.read<AppState>().api;

  List<String> magazzini;
  try {
    magazzini = await PrestazioniService(api).getMagazzini();
  } catch (_) {
    if (context.mounted) _errore(context);
    return;
  }
  if (!context.mounted) return;
  if (magazzini.isEmpty) {
    await invAlert(context, 'Nessun Magazzino Disponibile',
        'Non ci sono ancora Magazzini disponibili per il calcolo delle Prestazioni');
    return;
  }

  final magazzino = await invSelect(
      context, 'Tempo di Attesa medio ( calcolato sugli ultimi 30 gg )', magazzini);
  if (magazzino == null || !context.mounted) return;

  await mostraTempoAttesa(context, magazzino);
}

/// Alert con il tempo di attesa medio del magazzino (sezione 'impegno' di
/// queryPrestazioniMagazzino, usata anche dopo un impegno ODL in fase 0027).
Future<void> mostraTempoAttesa(BuildContext context, String magazzino) async {
  int? minuti;
  try {
    minuti = await PrestazioniService(context.read<AppState>().api).getMinutiMedi(magazzino);
  } catch (_) {
    if (context.mounted) _errore(context);
    return;
  }
  if (!context.mounted) return;

  if (minuti == null) {
    await invAlert(context, '$magazzino non disponibile',
        'Il tempo di Attesa medio per il magazzino $magazzino NON è ancora disponibile');
    return;
  }
  await invAlert(context, 'Attesa media di $magazzino',
      'Il tempo di Attesa medio per il magazzino $magazzino è di:\n\n${testoTempoAttesa(minuti)}');
}

void _errore(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Errore del Server')));
}

/// "45 minuti" oppure "2 ore e 5 minuti" (oltre l'ora).
String testoTempoAttesa(int minuti) {
  if (minuti <= 60) return '$minuti minuti';
  final ore = minuti ~/ 60;
  final resto = minuti - ore * 60;
  return '$ore ${ore > 1 ? 'ore' : 'ora'} e $resto minuti';
}

class PrestazioniService {
  PrestazioniService(this._api);

  final ApiClient _api;

  /// POST produzione/getMagazziniPrestazioniSelect → ["MG...", ...]
  Future<List<String>> getMagazzini() async {
    final res = await _api.postJson('${AppConfig.produzioneUrl}/getMagazziniPrestazioniSelect');
    if (res is! List) return const [];
    return [
      for (final m in res)
        if (m != null && m.toString().trim().isNotEmpty) m.toString().trim()
    ];
  }

  /// POST produzione/getPrestazioniMagazzino {magazzino} → minuti medi
  /// (null se non ci sono dati).
  Future<int?> getMinutiMedi(String magazzino) async {
    final res = await _api.postJson('${AppConfig.produzioneUrl}/getPrestazioniMagazzino',
        data: {'magazzino': magazzino});
    if (res is! List) return null;
    return calcolaPrestazioni0027([for (final r in res) if (r is Map) r]);
  }
}

// ---------------------------------------------------------------------------
// calcolaPrestazioni0027 — porting 1:1 di
// portale-web/apps/shared/calcolaPrestazioni0027.js (condiviso col PortaleWeb).
// ---------------------------------------------------------------------------

/// Minuti medi tra inserimento e completamento delle righe
/// {data_inserimento, ora_inserimento, data_completamento, ora_completamento}
/// (date yyyyMMdd, ore HHmmss), escludendo notti, weekend e pausa pranzo.
/// Restituisce null se non ci sono righe valide (NaN nel JS).
int? calcolaPrestazioni0027(List<Map> listaPrestazioni) {
  var minutiTotali = 0;
  var righe = 0;

  for (final p in listaPrestazioni) {
    final oraInserimento = int.tryParse('${p['ora_inserimento']}'.trim());
    final oraCompletamento = int.tryParse('${p['ora_completamento']}'.trim());
    final inserimento = _dataOra(p['data_inserimento'], oraInserimento);
    var completamento = _dataOra(p['data_completamento'], oraCompletamento);
    if (inserimento == null || completamento == null) continue;

    // Giorni di calendario tra le due date: per ogni giorno passato si tolgono
    // le ore non lavorative (16 = 24 - 8 lavorative, 24 nel weekend).
    final giorniDifferenza = DateTime.utc(completamento.year, completamento.month, completamento.day)
        .difference(DateTime.utc(inserimento.year, inserimento.month, inserimento.day))
        .inDays;

    if (giorniDifferenza > 0) {
      var giorno = inserimento;
      for (var i = 0; i < giorniDifferenza; i++) {
        giorno = DateTime(giorno.year, giorno.month, giorno.day + 1, giorno.hour, giorno.minute, giorno.second);

        if (giorno.weekday == DateTime.saturday || giorno.weekday == DateTime.sunday) {
          completamento = completamento!.subtract(const Duration(hours: 24));
          continue;
        }

        if (i + 1 == giorniDifferenza) {
          // L'ora di pausa pranzo dell'ultimo giorno la toglie _pausaPranzo: qui 15 ore invece di 16.
          completamento = _pausaPranzo(oraInserimento!, oraCompletamento!, completamento!)
              .subtract(const Duration(hours: 15));
        } else {
          completamento = completamento!.subtract(const Duration(hours: 16));
        }
      }
    } else {
      completamento = _pausaPranzo(oraInserimento!, oraCompletamento!, completamento);
    }

    var differenza = completamento!.difference(inserimento).inMinutes;
    if (differenza < 0) differenza = 0;

    minutiTotali += differenza;
    righe++;
  }

  if (righe == 0) return null;
  return (minutiTotali / righe).round();
}

/// Data yyyyMMdd + ora HHmmss (intera, senza zeri iniziali) → DateTime locale.
DateTime? _dataOra(dynamic data, int? ora) {
  final d = '${data ?? ''}'.trim();
  if (ora == null || ora < 0 || d.length != 8) return null;
  final anno = int.tryParse(d.substring(0, 4));
  final mese = int.tryParse(d.substring(4, 6));
  final giorno = int.tryParse(d.substring(6, 8));
  if (anno == null || mese == null || giorno == null) return null;
  return DateTime(anno, mese, giorno, ora ~/ 10000, ora ~/ 100 % 100, ora % 100);
}

/// timeDifferencePausaPranzo: se l'intervallo attraversa la pausa pranzo
/// (inserimento entro le 13:00, completamento dopo le 12:00) toglie fino a 1 ora.
DateTime _pausaPranzo(int oraInserimento, int oraCompletamento, DateTime completamento) {
  if (oraInserimento <= 130000 && oraCompletamento >= 120000) {
    final secondiInserimento =
        oraInserimento ~/ 10000 * 3600 + oraInserimento ~/ 100 % 100 * 60 + oraInserimento % 100;
    var minuti = (13 * 3600 - secondiInserimento) ~/ 60;
    if (minuti > 60) minuti = 60;
    if (minuti < 0 && minuti >= -60) minuti = -minuti;
    return completamento.subtract(Duration(minutes: minuti));
  }
  return completamento;
}
