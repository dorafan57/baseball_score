import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../providers/game_provider.dart';

/// 打順の中から任意の打者へ移動するためのダイアログ。
void showJumpBatterDialog(
  BuildContext context, {
  required GameSessionState session,
  required ValueChanged<int> onJumpToBatter,
}) {
  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(
        '${session.isTop ? session.teamNameTop : session.teamNameBottom} 打者選択',
      ),
      children: session.currentBatters.asMap().entries.map((entry) {
        int idx = entry.key;
        Player b = entry.value;
        bool isSelected = idx == session.currentBatterIndex;
        final matchEvs = b.stats.appearances
            .where(
              (p) => p.inning == session.inning && p.isTop == session.isTop,
            )
            .toList();

        return SimpleDialogOption(
          onPressed: () {
            onJumpToBatter(idx);
            Navigator.pop(ctx);
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isSelected
                    ? Colors.amber.shade800
                    : Colors.green.shade700,
                foregroundColor: Colors.white,
                child: Text('${idx + 1}', style: const TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Text(
                b.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${b.position})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (matchEvs.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${matchEvs.length}打席',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check, color: Colors.green, size: 18),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
