import 'package:cs_appmobile/features/produzione/prestazioni.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> riga(String di, String oi, String dc, String oc) => {
      'data_inserimento': di,
      'ora_inserimento': oi,
      'data_completamento': dc,
      'ora_completamento': oc,
    };

void main() {
  test('stesso giorno, senza pausa pranzo', () {
    expect(calcolaPrestazioni0027([riga('20261028', '90000', '20261028', '103000')]), 90);
  });

  test('stesso giorno, attraversa la pausa pranzo (-60)', () {
    expect(calcolaPrestazioni0027([riga('20261028', '110000', '20261028', '150000')]), 180);
  });

  test('giorno dopo: 16 ore non lavorative', () {
    // mar 16:00 → mer 09:00 = 17h, -15h, pausa: ora_ins 160000 > 130000 → niente → 120 min
    expect(calcolaPrestazioni0027([riga('20261027', '160000', '20261028', '90000')]), 120);
  });

  test('venerdì → lunedì: weekend tolto', () {
    // ven 16:00 → lun 09:00 = 65h, -24 -24 -15 = 2h
    expect(calcolaPrestazioni0027([riga('20261030', '160000', '20261102', '90000')]), 120);
  });

  test('media arrotondata e lista vuota', () {
    expect(
        calcolaPrestazioni0027([
          riga('20261028', '90000', '20261028', '91000'),
          riga('20261028', '90000', '20261028', '91500'),
        ]),
        13);
    expect(calcolaPrestazioni0027([]), isNull);
  });

  test('testo del tempo', () {
    expect(testoTempoAttesa(45), '45 minuti');
    expect(testoTempoAttesa(125), '2 ore e 5 minuti');
    expect(testoTempoAttesa(61), '1 ora e 1 minuti');
  });
}
