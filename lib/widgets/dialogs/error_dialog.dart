import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../providers/game_provider.dart';
import 'direction_dialog.dart';
import 'rule_warning.dart';

/// エラー（敵失）を犯した守備選手を選ぶダイアログ。
void showErrorDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  if (session.outs >= 3 && session.activeEvent == null) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。');
    return;
  }
  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('エラー（敵失）した守備選手を選択'),
      children: [
        ...session.defendingPlayers.map((b) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              promptDirectionAndRecord(
                context,
                session: session,
                notifier: notifier,
                result: AtBatResult.error,
                errorPlayerId: b.id,
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    b.position,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  b.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            promptDirectionAndRecord(
              context,
              session: session,
              notifier: notifier,
              result: AtBatResult.error,
            );
          },
          child: const Text('選手を指定せずに記録', style: TextStyle(color: Colors.grey)),
        ),
      ],
    ),
  );
}
