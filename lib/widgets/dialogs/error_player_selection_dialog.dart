import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';

/// 追加進塁の原因となったエラーを犯した野手を選ぶダイアログ。
///
/// 選択後にそのまま打席結果を確定する。
void showErrorPlayerSelectionDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
  required AtBatResult result,
  required String direction,
  required BaseRunners customRunners,
  required int runs,
  required int rbi,
  required List<String> scoredIds,
}) {
  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('追加進塁エラーを起こした野手を選択'),
      children: session.defendingPlayers.map((p) {
        return SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            notifier.applyCustomHitResult(
              result,
              direction,
              customRunners,
              runs,
              rbi,
              scoredIds,
              outsAdded: result.guaranteedOuts,
              errorPlayerId: p.id,
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.position,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
