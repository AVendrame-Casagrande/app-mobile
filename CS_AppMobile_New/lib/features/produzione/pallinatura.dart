import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../state/app_state.dart';
import '../giacenze/inventario_dialogs.dart';
import '../media/photo_picker.dart';

/// Pallinatura — porting di popupScattaFotoPallinatura()
/// (www/scripts/Produzione-Odl/Pagine/PaginaPrincipale/EventHandlers.js).
///
/// - Fotocamera: scatta una foto e la salva nella galleria del telefono, per
///   poterla poi modificare con Google Foto o Annotium.
/// - Upload: sceglie una foto dalla galleria e la carica su
///   storage/pallinatura/{nomePortale} (uploadFotoPallinatura.php).
/// - Galleria: apre Google Foto o Annotium.
Future<void> apriPallinatura(BuildContext context) async {
  final app = context.read<AppState>();
  final nomePortale = app.utenteLoggato.nomePortale;

  final r = await invPrompt(
    context,
    'Foto Pallinatura',
    'Vuoi scattare una Foto dalla Fotocamera o selezionare una Foto dalla Galleria?\n\n'
        "Puoi anche fare l'Upload di una Foto su /pallinatura/$nomePortale "
        '(puoi digitare un Nome opzionale)',
    ['Galleria', 'Fotocamera', 'Upload'],
  );
  if (r == null || !context.mounted) return;

  switch (r.button) {
    case 0:
      await _apriGalleria(context);
    case 1:
      await _scattaESalva(context);
    case 2:
      await _upload(context, r.text, nomePortale);
  }
}

/// Nome file: yyyy-MM-dd-HH-mm-ss-{nome} (caratteri non validi sostituiti).
String _nomeFile(String nome) {
  final f = '${DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now())}-$nome'
      .replaceAll(RegExp(r'[/\\?%*:|"<>]'), '-');
  return f.length > 250 ? f.substring(0, 250) : f;
}

Future<void> _scattaESalva(BuildContext context) async {
  final picker = ImagePicker();
  final XFile? foto;
  try {
    foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 60);
  } catch (_) {
    if (context.mounted) await invAlert(context, 'Errore', 'Impossibile aprire la fotocamera');
    return;
  }
  if (foto == null || !context.mounted) return;
  try {
    if (!await Gal.hasAccess()) await Gal.requestAccess();
    await Gal.putImage(foto.path, album: 'Pallinatura');
  } catch (_) {
    if (context.mounted) {
      await invAlert(context, 'Errore', 'Impossibile salvare la foto nella Galleria');
    }
    return;
  }
  if (!context.mounted) return;
  final s = await invChoice(
    context,
    'Foto Scattata',
    'Hai scattato una Foto con successo\n\nOra puoi editare questa foto utilizzando '
        'Google Foto o Annotium',
    ['Chiudi', 'Google Foto', 'Annotium'],
  );
  if (!context.mounted || s == null || s == 0) return;
  await _apri(context, s == 1 ? _googleFoto : _annotium);
}

const _googleFoto = 'com.google.android.apps.photos';
const _annotium = 'app.ngockhanh.annotium';

Future<void> _apriGalleria(BuildContext context) async {
  final s = await invChoice(context, 'Galleria',
      'Vuoi aprire la Galleria di Google Foto o di Annotium?', ['Google Foto', 'Annotium']);
  if (s == null || !context.mounted) return;
  await _apri(context, s == 0 ? _googleFoto : _annotium);
}

/// Apre l'app indicata (android-app:// come nell'originale); se non riesce,
/// la scheda dell'app sul Play Store.
Future<void> _apri(BuildContext context, String package) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse('android-app://$package'),
        mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (ok) return;
  try {
    ok = await launchUrl(Uri.parse('market://details?id=$package'),
        mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) {
    await invAlert(context, 'App non disponibile', "Impossibile aprire l'app ($package)");
  }
}

Future<void> _upload(BuildContext context, String nome, String nomePortale) async {
  final bytes = await PhotoPicker.pickFrom(ImageSource.gallery);
  if (bytes == null || !context.mounted) return;
  final filename = _nomeFile(nome.trim());
  final api = context.read<AppState>().api;
  String risposta;
  try {
    risposta = (await api.uploadFile(
      '${AppConfig.produzioneUrl}/uploadFotoPallinatura',
      bytes: bytes,
      name: filename,
      extraFields: {'nome_utente': nomePortale},
    ))
        .trim();
  } catch (_) {
    if (context.mounted) {
      await invAlert(context, 'Errore di Rete o del Server', 'Foto non caricata. Riprova');
    }
    return;
  }
  if (!context.mounted) return;
  if (risposta == 'uploaded') {
    invToast(context, 'Foto Inviata!');
  } else {
    await invAlert(
      context,
      'Accesso Negato',
      "Il tuo Utente non ha l'abilitazione per scrivere nella cartella pallinatura/$nomePortale "
          '(la cartella $nomePortale non esiste)',
    );
  }
}
