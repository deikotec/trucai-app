// src/games/caida/screens/room/components/player_hand.dart
// Este widget muestra las cartas en la mano del jugador y maneja la interacción
// de tocar una carta para jugarla.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/card_widget.dart';
import '../../../../common/fx/fx_controller.dart';
import '../../../models/caida_card.dart';
import '../../../providers/caida_provider.dart';
import '../../../../../core/services/firebase_service.dart';

class PlayerHand extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final GlobalKey centerStackKey;
  final GlobalKey tableKey;
  final FxController fxController;

  const PlayerHand({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.centerStackKey,
    required this.tableKey,
    required this.fxController,
  });

  @override
  Widget build(BuildContext context) {
    // Escucha tanto al CaidaProvider como al FirebaseService.
    final provider = context.watch<CaidaProvider>();
    final firebaseService = context.read<FirebaseService>();
    final canPlay =
        provider.logic.isPlayerTurn && provider.logic.gameInProgress;
    final cards = provider.logic.playerHand;

    return SizedBox(
      height: cardHeight + 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final count = cards.length;
          // Calcula el espaciado entre cartas para que se superpongan de forma atractiva.
          final spacing = count > 1
              ? (totalWidth - cardWidth - 32) /
                    (count - 1) // 32 es un padding extra
              : 0.0;
          final clampedSpacing = spacing.clamp(18.0, cardWidth * 0.7);

          return Stack(
            alignment: Alignment.center,
            children: List.generate(cards.length, (i) {
              final card = cards[i];
              // Calcula la posición horizontal de cada carta.
              final leftPosition =
                  (totalWidth / 2) -
                  (cardWidth / 2) +
                  (i - (count - 1) / 2) * clampedSpacing;

              return _AnimatedHandCard(
                key: ValueKey(card.id),
                left: leftPosition,
                angleDeg: (i - (count - 1) / 2) * 3.5,
                child: _TapMeasureCard(
                  card: card,
                  width: cardWidth,
                  height: cardHeight,
                  disabled: !canPlay,
                  onMeasuredTap: (rect) {
                    if (!canPlay) return;
                    _launchFlight(rect, card);
                    // Llama al método correcto en el provider.
                    provider.playerPlayCard(card, firebaseService);
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // Lanza la animación de "vuelo" de la carta.
  void _launchFlight(Rect cardGlobalRect, CaidaCard card) {
    final stackCtx = centerStackKey.currentContext;
    final tableCtx = tableKey.currentContext;
    if (stackCtx == null || tableCtx == null) return;

    final stackBox = stackCtx.findRenderObject() as RenderBox;
    final tableBox = tableCtx.findRenderObject() as RenderBox;

    final startCenter = stackBox.globalToLocal(cardGlobalRect.center);
    final tableCenterLocal = tableBox.size.center(Offset.zero);
    final tableCenterGlobal = tableBox.localToGlobal(tableCenterLocal);
    final endCenter = stackBox.globalToLocal(tableCenterGlobal);

    fxController.flyCard(
      CardFlight(
        imageUrl: card.imageUrl,
        from: startCenter,
        to: endCenter,
        size: Size(cardWidth, cardHeight),
      ),
    );
  }
}

// Widget para animar la posición y rotación de la carta.
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

// Widget que mide su propia posición global al ser tocado.
class _TapMeasureCard extends StatelessWidget {
  final CaidaCard card;
  final double width;
  final double height;
  final bool disabled;
  final void Function(Rect globalRect) onMeasuredTap;

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
