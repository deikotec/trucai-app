// src/games/caida/widgets/log_panel.dart
// Panel de registro de jugadas.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/caida_provider.dart';

class LogPanel extends StatelessWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CaidaProvider>();
    return Container(
      width: 260,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text(
              'Registro de jugadas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              reverse: true,
              itemCount: p.logs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(p.logs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
