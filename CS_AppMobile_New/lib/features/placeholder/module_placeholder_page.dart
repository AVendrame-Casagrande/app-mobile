import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Pagina segnaposto per i moduli non ancora convertiti dall'app Cordova.
/// Verrà sostituita dall'implementazione reale modulo per modulo.
class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({
    super.key,
    required this.title,
    required this.iconAsset,
  });

  final String title;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.6,
              child: Image.asset(iconAsset, width: 96, height: 96),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.casagrandeDark,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Modulo in fase di conversione da Cordova a Flutter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
