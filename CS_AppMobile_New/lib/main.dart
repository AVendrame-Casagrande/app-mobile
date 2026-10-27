import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/i18n/translator.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
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
  await appState.loadFromStorage();

  runApp(CasagrandeApp(appState: appState));
}

class CasagrandeApp extends StatelessWidget {
  const CasagrandeApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Casagrande',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomePage(),
      ),
    );
  }
}
