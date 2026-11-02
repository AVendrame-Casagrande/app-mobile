import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../models/inventario.dart';

/// Articolo minimo restituito da selectSingoloArticolo (needCompleteInfo:false).
class ArticoloInventario {
  final String codice;
  final String descrizione;
  final String um;
  const ArticoloInventario(this.codice, this.descrizione, this.um);
}

/// PDF di un articolo (getPdfList.php).
class PdfArticolo {
  final String url;
  final String shortUrl;
  const PdfArticolo(this.url, this.shortUrl);
}

/// Service del modulo Giacenze → Inventario.
/// Porting di Query.js (getElencoListe, writeLista, getInventarioFullQuery,
/// ajaxWriteRigaLista, writeCustomRigaLista) e delle chiamate dirette di
/// Pagine/Inventario/EventHandlers.js (cambiaStatoLista, updateRigaInventario,
/// eliminaRiga, checkVanoExists, checkMagazzinoExists, getPdfList) e
/// GestioneDispositivo.js (uploadFotoInventario).
class InventarioService {
  InventarioService(this._api);

  final ApiClient _api;

  static const String _queryDesktopGiacenze =
      '${AppConfig.queryDesktopUrl}/giacenze';

  /// Elenco delle liste di inventario, nell'ordine del server.
  /// GET /giacenze/getElencoListe.php
  Future<List<InventarioTestata>> getElencoListe() async {
    final res = await _api.postJson('${AppConfig.giacenzeUrl}/getElencoListe');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => InventarioTestata.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Crea una nuova lista.
  /// POST /giacenze/writeLista.php {nome_lista, tipo_lista, utente}
  /// Ritorna la risposta grezza: 'error', 'lista_already_exists',
  /// 'magazzino_not_found', 'vano_preciso_not_found', 'vano_radice_not_found'
  /// oppure altro in caso di successo.
  Future<String> writeLista(
      String nomeLista, String tipoLista, String utente) async {
    final res = await _api.postText(
      '${AppConfig.giacenzeUrl}/writeLista',
      data: {'nome_lista': nomeLista, 'tipo_lista': tipoLista, 'utente': utente},
    );
    return res.trim();
  }

  /// Cambia lo stato di una lista: 0 = riapri, 1 = archivia, 9 = elimina.
  /// POST /giacenze/cambiaStatoLista.php {id, utente, stato} → 'updated'
  Future<bool> cambiaStatoLista(int id, String utente, int stato) async {
    final res = await _api.postText(
      '${AppConfig.giacenzeUrl}/cambiaStatoLista',
      data: {'id': id, 'utente': utente, 'stato': stato},
    );
    return res.trim() == 'updated';
  }

  /// Contenuto completo di una lista (righe salvate + giacenze rimaste).
  /// POST /giacenze/getInventarioFullQuery.php {id, nome_lista, tipo_lista}
  Future<InventarioContenuto> getContenuto(InventarioTestata t) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/getInventarioFullQuery',
      data: {
        'id': t.id,
        'nome_lista': t.nomeLista,
        'tipo_lista': t.tipoLista,
      },
    );
    if (res is! Map) return InventarioContenuto();

    final righe = <InventarioRiga>[];
    final rawRighe = res['listaRighe'];
    if (rawRighe is List) {
      for (final r in rawRighe.whereType<Map>()) {
        righe.add(InventarioRiga.fromJson(Map<String, dynamic>.from(r)));
      }
    }

    final giacenze = <InventarioRiga>[];
    final rawGiac = res['listaGiacenze'];
    if (rawGiac is List) {
      for (final g in rawGiac.whereType<Map>()) {
        giacenze
            .add(InventarioRiga.fromGiacenza(Map<String, dynamic>.from(g), t.id));
      }
    }

    return InventarioContenuto(righe: righe, giacenzeRimaste: giacenze);
  }

  /// Conferma (salva) una riga.
  /// POST /giacenze/writeRigaLista.php {rigaLista: JSON, utente}
  /// Ritorna l'id della nuova riga, oppure un codice: 'lista_archiviata',
  /// 'lista_eliminata', 'error', o il codice utente che l'ha già confermata.
  Future<String> writeRigaLista(InventarioRiga riga, String utente) async {
    final res = await _api.postText(
      '${AppConfig.giacenzeUrl}/writeRigaLista',
      data: {'rigaLista': (riga.toJson()), 'utente': utente},
    );
    return res.trim();
  }

  /// Aggiorna un campo di una riga già confermata.
  /// POST /giacenze/updateRigaInventario.php → 'updated'
  /// [tipoModifica]: 'qta', 'stato', 'stato_nota', 'url_foto'.
  Future<bool> updateRiga(
    int id, {
    required String tipoModifica,
    int? stato,
    num? qtaModificata,
    String? urlFoto,
    String? nota,
  }) async {
    final data = <String, dynamic>{
      'id': id,
      'stato': stato,
      'qta_modificata': qtaModificata,
      'qta_originale': null,
      'vano_modificato': null,
      'url_foto': urlFoto,
      'decisione': null,
      'stato_movimento_decisione': null,
      'tipo_modifica': tipoModifica,
    };
    if (tipoModifica == 'stato' || tipoModifica == 'stato_nota') {
      data['nota'] = nota;
    }
    final res = await _api.postText(
      '${AppConfig.giacenzeUrl}/updateRigaInventario',
      data: data,
    );
    return res.trim() == 'updated';
  }

  /// Elimina una riga confermata.
  /// POST /giacenze/eliminaRiga.php {id} → 'deleted'
  Future<bool> eliminaRiga(int id) async {
    final res = await _api.postText(
      '${AppConfig.giacenzeUrl}/eliminaRiga',
      data: {'id': id},
    );
    return res.trim() == 'deleted';
  }

  /// Articolo per la riga manuale (null se non esiste: HTTP 404).
  /// Gli errori di rete vengono propagati (gestione offline nella pagina).
  /// POST /giacenze/selectSingoloArticolo.php {codiceArticolo, societa, needCompleteInfo:false}
  Future<ArticoloInventario?> getArticolo(String codice) async {
    try {
      final res = await _api.postJson(
        '${AppConfig.giacenzeUrl}/selectSingoloArticolo',
        data: {
          'codiceArticolo': codice,
          'societa': AuthToken.societa,
          'needCompleteInfo': false,
        },
      );
      if (res is Map && res['codice'] != null) {
        return ArticoloInventario(
          res['codice'].toString(),
          (res['descrizione'] ?? '').toString(),
          (res['unitaMisura'] ?? '').toString(),
        );
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST queryDesktop/giacenze/checkVanoExists.php {vano} → true/false
  Future<bool> checkVanoExists(String vano) async {
    final res = await _api.postJson('$_queryDesktopGiacenze/checkVanoExists',
        data: {'vano': vano});
    return res == true || res == 1 || res == '1';
  }

  /// POST queryDesktop/giacenze/checkMagazzinoExists.php {magazzino} → true/false
  Future<bool> checkMagazzinoExists(String magazzino) async {
    final res = await _api.postJson(
        '$_queryDesktopGiacenze/checkMagazzinoExists',
        data: {'magazzino': magazzino});
    return res == true || res == 1 || res == '1';
  }

  /// Elenco dei PDF (disegni) di un articolo.
  /// POST /giacenze/getPdfList.php {codiceArticolo, codiceDisegno:'', codiceDisegnoIsPreciso:false}
  Future<List<PdfArticolo>> getPdfList(String articolo) async {
    final res = await _api.postJson(
      '${AppConfig.giacenzeUrl}/getPdfList',
      data: {
        'codiceArticolo': articolo,
        'codiceDisegno': '',
        'codiceDisegnoIsPreciso': false,
      },
    );
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) {
          final url = (e['url'] ?? '').toString();
          // Il PDF AO non ha short_url: uso l'url senza estensione.
          final shortUrl = (e['short_url'] ?? '').toString();
          return PdfArticolo(
              url,
              shortUrl.isNotEmpty || url.length < 4
                  ? shortUrl
                  : url.substring(0, url.length - 4));
        })
        .toList();
  }

  /// Nome del file foto, come in GestioneDispositivo.openCamera('inventario'):
  /// `yyyyMMdd_HHmmss_{utente}_ID{idLista}_{articolo}_S{stato}_{mag}_{vano_orig}`
  static String nomeFoto(InventarioRiga riga, String utente) {
    final now = DateTime.now();
    final nome = '${DateFormat('yyyyMMdd').format(now)}_'
        '${DateFormat('HHmmss').format(now)}_$utente'
        '_ID${riga.idListaTestata}_${riga.articolo}_S${riga.stato}'
        '_${riga.magazzino}_${riga.vanoOriginale}';
    return nome.replaceAll('*', '-').replaceAll('/', '-');
  }

  /// URL pubblico della foto di una riga.
  static String urlFoto(String nome) =>
      '${AppConfig.storageUrl}/inventario_foto/$nome.jpg';

  /// Carica la foto di una riga. Se la riga è Conforme la foto viene
  /// aggiunta anche all'anagrafica articolo (uploadFoto.php), come l'originale.
  /// POST /giacenze/uploadFotoInventario.php (file + name) → 'uploaded'
  Future<bool> uploadFoto(
      InventarioRiga riga, String nome, Uint8List bytes) async {
    final res = await _api.uploadFile(
      '${AppConfig.giacenzeUrl}/uploadFotoInventario',
      bytes: bytes,
      name: nome,
    );
    if (riga.stato == 1) {
      // Fire-and-forget come nell'originale.
      _api
          .uploadFile('${AppConfig.generaleUrl}/uploadFoto',
              bytes: bytes, name: riga.articolo)
          .ignore();
    }
    return res.trim() == 'uploaded';
  }
}
