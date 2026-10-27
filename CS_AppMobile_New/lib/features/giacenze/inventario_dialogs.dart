import 'package:flutter/material.dart';

// Dialog riutilizzati dall'Inventario — sostituiscono navigator.notification
// (alert/confirm/prompt) e il SelectorCordovaPlugin dell'app Cordova.

/// Alert con solo "OK" (applicazione.androidAlert).
Future<void> invAlert(BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message.trim()),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
      ],
    ),
  );
}

/// Dialog con più pulsanti: ritorna l'indice (0-based) del pulsante premuto,
/// o null se chiuso.
Future<int?> invChoice(
  BuildContext context,
  String title,
  String message,
  List<String> buttons,
) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message.trim()),
      actions: [
        for (var i = 0; i < buttons.length; i++)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(i),
            child: Text(buttons[i]),
          ),
      ],
    ),
  );
}

/// Esito di un prompt con più pulsanti.
class InvPromptResult {
  final int button; // indice 0-based
  final String text;
  const InvPromptResult(this.button, this.text);
}

/// Prompt testuale con più pulsanti (navigator.notification.prompt).
/// Ritorna null se annullato/chiuso.
Future<InvPromptResult?> invPrompt(
  BuildContext context,
  String title,
  String message,
  List<String> buttons, {
  String initial = '',
  bool numeric = false,
  bool uppercase = false,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<InvPromptResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.trim()),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: uppercase
                ? TextCapitalization.characters
                : TextCapitalization.none,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
          ),
        ],
      ),
      actions: [
        for (var i = 0; i < buttons.length; i++)
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(InvPromptResult(i, controller.text)),
            child: Text(buttons[i]),
          ),
      ],
    ),
  );
  // Il controller non viene disposto qui: il TextField lo usa ancora durante
  // l'animazione di chiusura del dialog.
}

/// Prompt numerico con "Conferma/Annulla". Ritorna null se annullato,
/// double.nan se il valore non è un numero valido.
Future<double?> invPromptNumber(
  BuildContext context,
  String title,
  String message, {
  num? initial,
  String confirmText = 'Conferma',
}) async {
  final r = await invPrompt(
    context,
    title,
    message,
    [confirmText, 'Annulla'],
    initial: initial == null ? '' : formatQta(initial),
    numeric: true,
  );
  if (r == null || r.button != 0) return null;
  return double.tryParse(r.text.trim().replaceAll(',', '.')) ?? double.nan;
}

/// Valore restituito da [invSelect] quando si preme [extraButton].
const String invSelectExtra = '__inv_select_extra__';

/// Selettore da elenco (sostituisce il wheel selector). [extraButton] è il
/// pulsante negativo ("Non trovo il Vano"): se premuto ritorna [invSelectExtra].
Future<String?> invSelect(
  BuildContext context,
  String title,
  List<String> items, {
  String? extraButton,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessun valore disponibile'),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(items[i].isEmpty ? '(vuoto)' : items[i]),
                  onTap: () => Navigator.of(ctx).pop(items[i]),
                ),
              ),
      ),
      actions: [
        if (extraButton != null)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(invSelectExtra),
            child: Text(extraButton),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Annulla'),
        ),
      ],
    ),
  );
}

void invToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String formatQta(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}
