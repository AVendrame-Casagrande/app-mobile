import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pagina scanner barcode/QR riutilizzabile — rimpiazza il plugin Cordova
/// "barcodeScanner" / l'icona occhio dei campi di ricerca.
///
/// Uso:
/// ```dart
/// final code = await BarcodeScannerPage.scan(context);
/// if (code != null) { ... }
/// ```
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key, this.titolo = 'Inquadra il codice'});

  final String titolo;

  /// Apre lo scanner e ritorna il codice letto (o null se annullato).
  static Future<String?> scan(BuildContext context, {String? titolo}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(
          titolo: titolo ?? 'Inquadra il codice',
        ),
      ),
    );
  }

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
    ],
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.titolo),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography,
                          color: Colors.white70, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Fotocamera non disponibile\n${error.errorCode.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Mirino
          Container(
            width: 260,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
