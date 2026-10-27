import 'package:flutter_test/flutter_test.dart';

import 'package:cs_appmobile/models/utente.dart';

void main() {
  test('Utente.ospite ha accountType Ospite', () {
    final u = Utente.ospite();
    expect(u.isOspite, isTrue);
    expect(u.accountType, 'Ospite');
  });

  test('Utente.fromJson parse corretto', () {
    final u = Utente.fromJson({
      'codiceUtente': 'ABC',
      'nomeUtente': 'Mario',
      'accountType': 'Utente Standard',
      'language': 'I',
    });
    expect(u.codiceUtente, 'ABC');
    expect(u.nomeUtente, 'Mario');
    expect(u.accountType, 'Utente Standard');
    expect(u.isOspite, isFalse);
  });
}
