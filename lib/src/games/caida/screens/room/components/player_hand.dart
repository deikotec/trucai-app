// src/games/caida/widgets/player_hand.dart
// Mano del jugador con ANIMACIÓN de "vuelo" al centro de la mesa.
// Calcula el rect de la carta tocada y dispara un CardFlight en FxController.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/card_widget.dart';
import '../../../../common/fx/fx_controller.dart';
import '../../../models/caida_card.dart';
import '../../../providers/caida_provider.dart';

class PlayerHand extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final GlobalKey
  centerStackKey; // Stack que contiene la mesa (para convertir coords)
  final GlobalKey tableKey; // Contenedor de la mesa (destino visual)
  final FxController fx;

  const PlayerHand({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.centerStackKey,
    required this.tableKey,
    required this.fx,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CaidaProvider>();
    final canPlay = prov.logic.isPlayerTurn;
    final cards = prov.logic.playerHand;

    return SizedBox(
      height: cardHeight + 48,
      child: LayoutBuilder(
        builder: (context, c) {
          final totalW = c.maxWidth;
          final count = cards.length;
          final spacing = count > 0
              ? (totalW - cardWidth) / (count == 1 ? 1 : (count - 1))
              : 0;
          final clampedSpacing = spacing.clamp(18.0, cardWidth * 0.7);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (int i = 0; i < count; i++)
                _AnimatedHandCard(
                  key: ValueKey(cards[i].id),
                  left: (i * clampedSpacing).toDouble(),
                  angleDeg: (i - (count - 1) / 2) * 3.5,
                  child: _TapMeasureCard(
                    card: cards[i],
                    width: cardWidth,
                    height: cardHeight,
                    disabled: !canPlay,
                    onMeasuredTap: (rect) {
                      if (!canPlay) return;
                      _launchFlight(rect, cards[i]);
                      // Ejecutar jugada tras disparar el vuelo
                      prov.playerTapCard(cards[i]);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _launchFlight(Rect cardGlobalRect, CaidaCard card) {
    final stackCtx = centerStackKey.currentContext;
    final tableCtx = tableKey.currentContext;
    if (stackCtx == null || tableCtx == null) return;

    // Convertir posiciones globales a locales del Stack central
    final stackBox = stackCtx.findRenderObject() as RenderBox;
    final tableBox = tableCtx.findRenderObject() as RenderBox;

    final startCenter = stackBox.globalToLocal(cardGlobalRect.center);
    final tableCenter = tableBox.size.center(Offset.zero);
    final tableCenterGlobal = tableBox.localToGlobal(tableCenter);
    final endCenter = stackBox.globalToLocal(tableCenterGlobal);

    fx.flyCard(
      CardFlight(
        imageUrl: card.imageUrl,
        from: startCenter,
        to: endCenter,
        size: Size(cardWidth, cardHeight),
      ),
    );
  }
}

class _AnimatedHandCard extends StatelessWidget {
  final double left;
  final double angleDeg;
  final Widget child;

  const _AnimatedHandCard({
    super.key,
    required this.left,
    required this.angleDeg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      left: left,
      top: 8,
      child: AnimatedRotation(
        turns: angleDeg / 360,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

typedef MeasuredTap = void Function(Rect globalRect);

class _TapMeasureCard extends StatelessWidget {
  final CaidaCard card;
  final double width;
  final double height;
  final bool disabled;
  final MeasuredTap onMeasuredTap;

  const _TapMeasureCard({
    required this.card,
    required this.width,
    required this.height,
    required this.disabled,
    required this.onMeasuredTap,
  });

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              final ctx = key.currentContext;
              if (ctx != null) {
                final box = ctx.findRenderObject() as RenderBox;
                final pos = box.localToGlobal(Offset.zero);
                final rect = pos & box.size;
                onMeasuredTap(rect);
              }
            },
      child: KeyedSubtree(
        key: key,
        child: CardWidget(
          card: card,
          width: width,
          height: height,
          disabled: disabled,
        ),
      ),
    );
  }
}
