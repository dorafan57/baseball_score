import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../providers/game_provider.dart';
import 'rule_warning.dart';

/// 三振の種別（通常の三振か振り逃げか）を選ぶダイアログ。
void showStrikeoutDialog(
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
    builder: (ctx) => AlertDialog(
      title: const Text('三振の種別を選択'),
      content: const Text('この三振は通常の三振（アウト）ですか？それとも振り逃げ（出塁）ですか？'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            notifier.recordOrUpdateAtBat(
              AtBatResult.strikeoutSafe,
              direction: '',
            );
          },
          child: const Text(
            '振り逃げ (出塁)',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            notifier.recordOrUpdateAtBat(AtBatResult.strikeout, direction: '');
          },
          child: const Text('通常の三振 (1アウト)'),
        ),
      ],
    ),
  );
}
