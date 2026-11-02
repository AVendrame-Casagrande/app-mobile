import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/i18n/translator.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/chat_notifiche.dart';
import 'features/chat/chat_servizio_background.dart';
import 'features/home/home_page.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientamento bloccato in verticale (config.xml: Orientation = portrait).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await LocalStorage.init();

  // Lingua di sistema (es. 'it', 'en').
  Translator.systemLanguage =
      ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();

  final appState = AppState();
  final navigatorKey = GlobalKey<NavigatorState>();

  // Popup e notifiche dei nuovi messaggi chat (lo stream parte con la sessione).
  final notifiche = ChatNotifiche(appState, navigatorKey);
  appState.onNuoviMessaggiChat = notifiche.gestisci;
  await appState.loadFromStorage();

  runApp(CasagrandeApp(appState: appState, navigatorKey: navigatorKey));

  // Prima il permesso notifiche (serve anche alla notifica fissa del servizio), poi il servizio.
  await notifiche.init();
  if (appState.isLogged) await ChatServizioBackground.avvia();
}

class CasagrandeApp extends StatelessWidget {
  const CasagrandeApp({super.key, required this.appState, required this.navigatorKey});

  final AppState appState;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Stokky',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Da Android 15 l'app è disegnata "edge-to-edge": senza questo margine la
        // barra di navigazione del telefono (indietro / home / app recenti) copre
        // la parte bassa delle pagine. La barra di stato resta gestita dalle AppBar.
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(top: false, child: child ?? const SizedBox.shrink()),
        ),
        home: const HomePage(),
      ),
    );
  }
}
