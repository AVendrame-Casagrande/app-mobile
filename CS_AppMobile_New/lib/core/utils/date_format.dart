import 'package:intl/intl.dart';

/// Helper condivisi per la formattazione delle date provenienti dal backend.
/// Il backend Diapason restituisce le date a volte come "yyyy-MM-dd" e a volte
/// come "yyyyMMdd" (senza separatori): questi helper gestiscono entrambi i casi
/// e producono sempre il formato italiano "dd/MM/yyyy".

final DateFormat _yyyyMMdd = DateFormat('yyyyMMdd');

/// Formatta una data in "dd/MM/yyyy". Gestisce sia "yyyy-MM-dd" sia "yyyyMMdd"
/// (e timestamp più lunghi) tramite slicing manuale delle cifre. '' se vuota/0.
String formatData(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty || s == '0') return '';
  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 8) {
    final y = digits.substring(0, 4);
    final m = digits.substring(4, 6);
    final d = digits.substring(6, 8);
    final mi = int.tryParse(m) ?? 0;
    final di = int.tryParse(d) ?? 0;
    if (mi >= 1 && mi <= 12 && di >= 1 && di <= 31) {
      return '$d/$m/$y';
    }
  }
  return s;
}

/// Numero intero yyyyMMdd da una data grezza (per confronti con "oggi").
int dataInt(dynamic raw) {
  final digits = (raw ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 8) return int.tryParse(digits.substring(0, 8)) ?? 0;
  return int.tryParse(digits) ?? 0;
}

/// yyyyMMdd intero di oggi.
int oggiInt() => dataInt(_yyyyMMdd.format(DateTime.now()));

/// Formatta un orario "HHmmss" in "HH:mm".
String formatOra(dynamic raw) {
  final s = (raw ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
  if (s.length >= 4) return '${s.substring(0, 2)}:${s.substring(2, 4)}';
  return (raw ?? '').toString();
}
