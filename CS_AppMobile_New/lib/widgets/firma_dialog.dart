import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Esito del dialog firma: pulsante scelto e firma come data URL PNG.
class FirmaResult {
  final int button;
  final String dataUrl;
  const FirmaResult(this.button, this.dataUrl);
}

/// Dialog con un riquadro per la firma digitale (sostituisce SignaturePad).
/// Ritorna null se chiuso. Se si preme un pulsante senza aver firmato
/// [dataUrl] è vuoto.
Future<FirmaResult?> showFirmaDialog(
  BuildContext context, {
  required String title,
  required String message,
  required List<String> buttons,
}) {
  return showDialog<FirmaResult>(
    context: context,
    builder: (_) => _FirmaDialog(title: title, message: message, buttons: buttons),
  );
}

class _FirmaDialog extends StatefulWidget {
  const _FirmaDialog({required this.title, required this.message, required this.buttons});

  final String title;
  final String message;
  final List<String> buttons;

  @override
  State<_FirmaDialog> createState() => _FirmaDialogState();
}

class _FirmaDialogState extends State<_FirmaDialog> {
  final _key = GlobalKey();
  final List<List<Offset>> _tratti = [];

  Future<String> _esporta() async {
    if (_tratti.every((t) => t.isEmpty)) return '';
    final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return '';
    return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List())}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _key,
              child: Container(
                width: 300,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black54),
                ),
                child: GestureDetector(
                  onPanStart: (d) => setState(() => _tratti.add([d.localPosition])),
                  onPanUpdate: (d) => setState(() => _tratti.last.add(d.localPosition)),
                  child: CustomPaint(painter: _FirmaPainter(_tratti), size: Size.infinite),
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(_tratti.clear),
              child: const Text('Cancella firma'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Chiudi')),
        for (var i = 0; i < widget.buttons.length; i++)
          TextButton(
            onPressed: () async {
              final firma = await _esporta();
              if (context.mounted) Navigator.of(context).pop(FirmaResult(i, firma));
            },
            child: Text(widget.buttons[i]),
          ),
      ],
    );
  }
}

class _FirmaPainter extends CustomPainter {
  _FirmaPainter(this.tratti);
  final List<List<Offset>> tratti;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final t in tratti) {
      if (t.length == 1) {
        canvas.drawCircle(t.first, 1.2, p..style = PaintingStyle.fill);
        p.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(t.first.dx, t.first.dy);
      for (final o in t.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _FirmaPainter old) => true;
}
