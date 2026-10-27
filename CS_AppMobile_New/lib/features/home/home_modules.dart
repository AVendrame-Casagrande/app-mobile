/// Identificatori dei moduli/pulsanti della Pagina Principale.
/// Corrispondono ai `data-text` usati in PaginaPrincipale.js.
enum AppModule {
  kanban('kanban', 'Kanban', 'assets/img/kanbanicon.png'),
  cerca('cerca', 'Articoli', 'assets/img/search.png'),
  magazzino('magazzino', 'Magazzino', 'assets/img/db1.png'),
  produzione('produzione', 'Produzione', 'assets/img/produzione_icon.png'),
  situazioneOdv('situazione_odv', 'Sit. Odv', 'assets/img/situazione_odv.png'),
  chat('chat', 'Chat', 'assets/img/chat.png'),
  attivita('attivita', 'Attività', 'assets/img/missioni.png'),
  aggiorna('aggiorna', 'Update', 'assets/img/refresh.png'),
  guida('guida', 'Documenti', 'assets/img/pdficon.png'),
  profilo('profilo', 'Profilo', 'assets/img/account2.png'),
  fotoarm('foto arm', 'Foto Arm', 'assets/img/camera4.png'),
  stampa('stampa', 'Etichette', 'assets/img/stampante.png');

  const AppModule(this.dataText, this.label, this.iconAsset);

  final String dataText;
  final String label;
  final String iconAsset;
}

/// Restituisce la lista ordinata dei moduli da mostrare in home in base
/// al tipo di account e alla lingua — porting di drawMainPage()
/// (www/scripts/PaginaPrincipale/PaginaPrincipale.js).
List<AppModule> modulesForUser({
  required String accountType,
  required String language,
}) {
  // Caso USA / lingua inglese (gestito a parte nell'originale).
  if (language == 'E' && accountType == 'Ospite') {
    return const [AppModule.profilo, AppModule.cerca, AppModule.aggiorna];
  }
  if (language == 'E') {
    return const [
      AppModule.profilo,
      AppModule.cerca,
      AppModule.magazzino,
      AppModule.aggiorna,
    ];
  }

  switch (accountType) {
    case 'Ospite':
      return const [
        AppModule.kanban,
        AppModule.cerca,
        AppModule.magazzino,
        AppModule.produzione,
        AppModule.aggiorna,
        AppModule.guida,
        AppModule.profilo,
      ];

    case 'Utente Standard':
      return const [
        AppModule.kanban,
        AppModule.cerca,
        AppModule.magazzino,
        AppModule.produzione,
        AppModule.situazioneOdv,
        AppModule.chat,
        AppModule.attivita,
        AppModule.aggiorna,
        AppModule.guida,
        AppModule.profilo,
      ];

    case 'Utente Magazzino':
    case 'Utente Produzione':
    case 'Utente Avanzato':
    case 'Utente Qualità':
      return const [
        AppModule.kanban,
        AppModule.cerca,
        AppModule.magazzino,
        AppModule.produzione,
        AppModule.situazioneOdv,
        AppModule.stampa,
        AppModule.attivita,
        AppModule.aggiorna,
        AppModule.chat,
        AppModule.profilo,
        AppModule.guida,
        AppModule.fotoarm,
      ];

    default:
      // Account sconosciuto: vista minima.
      return const [AppModule.profilo, AppModule.cerca, AppModule.aggiorna];
  }
}
