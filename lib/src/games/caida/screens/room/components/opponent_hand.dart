// src/games/caida/widgets/opponent_hand.dart
// Mano del oponente con animación y GlobalKey para medir punto inicial del vuelo.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/caida_provider.dart';

class OpponentHand extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final GlobalKey areaKey; // clave del contenedor para medir centro

  const OpponentHand({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.areaKey,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CaidaProvider>();
    final count = prov.logic.opponentHand.length;

    return SizedBox(
      key: areaKey,
      height: cardHeight + 32,
      child: LayoutBuilder(
        builder: (context, c) {
          final totalW = c.maxWidth;
          final spacing = count > 0
              ? (totalW - cardWidth) / (count == 1 ? 1 : (count - 1))
              : 0;
          final clampedSpacing = spacing.clamp(18.0, cardWidth * 0.7);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (int i = 0; i < count; i++)
                _OpponentBackCard(
                  key: ValueKey('op$i-${prov.logic.handNumber}'),
                  left: (i * clampedSpacing).toDouble(),
                  width: cardWidth,
                  height: cardHeight,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OpponentBackCard extends StatelessWidget {
  final double left;
  final double width;
  final double height;
  const _OpponentBackCard({
    super.key,
    required this.left,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      left: left,
      top: 8,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: 1,
        child: Container(
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4338CA), Color(0xFF3730A3)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.tealAccent, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      ),
    );
  }
}
