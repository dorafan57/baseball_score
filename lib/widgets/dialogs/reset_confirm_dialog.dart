import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';

/// 試合スコアの全リセットを確認するダイアログ。
void showResetConfirmDialog(
  BuildContext context, {
  required GameNotifier notifier,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('リセットの確認'),
      content: const Text('現在のスコア、両チームの全打席結果、走者状況をすべて初期化しますか？'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
          },
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            // イベントを消せば、成績はすべて再生結果として初期化される。
            notifier.resetGame();
            Navigator.pop(ctx);
          },
          child: const Text('リセット実行', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
