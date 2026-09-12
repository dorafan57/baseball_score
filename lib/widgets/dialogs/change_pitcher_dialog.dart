import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';

/// 投手交代（継投）の相手を選ぶダイアログ。
void showChangePitcherDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  final teamPlayers = session.defendingPlayers;
  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(
        '${session.isTop ? session.teamNameBottom : session.teamNameTop} 投手交代（継投）',
      ),
      children: teamPlayers.map((p) {
        bool isCurrent = p.id == session.activePitcher.id;
        return SimpleDialogOption(
          onPressed: () {
            notifier.changePitcher(p.id);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('投手を [${p.name}] に交代しました。')));
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isCurrent
                    ? Colors.amber.shade800
                    : Colors.green.shade700,
                foregroundColor: Colors.white,
                child: const Text('投', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 10),
              Text(
                p.name,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${p.position})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              if (isCurrent)
                const Text(
                  '登板中',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
