// src/games/caida/widgets/table_board.dart
// Mesa central compatible con vuelo (usa GlobalKey desde la pantalla).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/card_widget.dart';
import '../../../providers/caida_provider.dart';

class TableBoard extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;

  const TableBoard({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CaidaProvider>();

    return Expanded(
      child: Container(
        key: key, // la GlobalKey la fija el padre (CaidaGameScreen)
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0xFF059669), Color(0xFF065F46)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.tealAccent),
          boxShadow: const [
            BoxShadow(blurRadius: 18, color: Colors.black54, spreadRadius: 2),
          ],
        ),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: prov.logic.tableCards
                .map(
                  (c) =>
                      CardWidget(card: c, width: cardWidth, height: cardHeight),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
