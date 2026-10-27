import 'package:flutter/material.dart';

/// Pulsante a blocco della home — replica `.blockButtonMini` dei CSS:
/// blocco con gradiente nero (dal basso) + ombra, icona centrata e
/// testo bianco con ombreggiatura sotto.
class BlockButton extends StatelessWidget {
  const BlockButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  /// Testo opzionale mostrato al posto/insieme dell'etichetta (es. versione, n. attività).
  final Widget? badge;

  static const List<Shadow> _textShadow = [
    Shadow(blurRadius: 4, color: Colors.black),
    Shadow(blurRadius: 4, color: Colors.black),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF000000),
                      Color(0x33000000),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(2, -1),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(iconAsset, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 4),
          badge ??
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  shadows: _textShadow,
                ),
              ),
        ],
      ),
    );
  }
}
