// src/games/common/widgets/card_widget.dart
import 'package:flutter/material.dart';
import '../../caida/models/caida_card.dart';

class CardWidget extends StatelessWidget {
  final CaidaCard card;
  final VoidCallback? onTap;
  final bool disabled;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.disabled = false,
    this.width = 80,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black54)],
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            card.imageUrl,
            fit: BoxFit.cover,
            color: disabled ? Colors.black.withOpacity(0.45) : null,
            colorBlendMode: disabled ? BlendMode.darken : null,
          ),
        ),
      ),
    );
  }
}
