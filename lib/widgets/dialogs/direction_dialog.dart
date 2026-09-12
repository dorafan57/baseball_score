import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../providers/game_provider.dart';
import 'double_play_route_dialog.dart';
import 'hit_with_runners_dialog.dart';
import 'rule_warning.dart';
import 'walk_or_error_runners_dialog.dart';

/// 打席結果の入力をディスパッチし、必要に応じて打球方向を選ばせてから記録する。
///
/// 結果の種類によって、併殺経路ダイアログ・走者の進塁確認ダイアログへ
/// 振り分けたり、方向の選択を省略したりする。
void promptDirectionAndRecord(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
  required AtBatResult result,
  String? errorPlayerId,
}) {
  final runners = session.runners;

  if (session.outs >= 3 && session.activeEvent == null) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。これ以上アウトになる打席は入力できません。');
    return;
  }

  if (result == AtBatResult.doublePlay) {
    if (session.outs >= 2) {
      showRuleWarning(context, '⚠️ 2アウトの場面で併殺打（ダブルプレイ）は選択できません。');
      return;
    }
    showDoublePlayRouteDialog(
      context,
      notifier: notifier,
      errorPlayerId: errorPlayerId,
    );
    return;
  }

  if (result == AtBatResult.walk || result == AtBatResult.hitByPitch) {
    notifier.recordOrUpdateAtBat(result, direction: '');
    return;
  }

  if (result == AtBatResult.error) {
    if (runners.isNotEmpty) {
      showWalkOrErrorRunnersDialog(
        context,
        session: session,
        notifier: notifier,
        result: result,
        errorPlayerId: errorPlayerId,
        direction: errorPlayerId != null
            ? session.defendingPlayers
                  .firstWhere((p) => p.id == errorPlayerId)
                  .position
            : '',
      );
      return;
    }
  }

  bool needsDirection = [
    AtBatResult.singleHit,
    AtBatResult.doubleHit,
    AtBatResult.tripleHit,
    AtBatResult.homeRun,
    AtBatResult.groundOut,
    AtBatResult.flyOut,
    AtBatResult.foulFlyOut,
  ].contains(result);

  if (!needsDirection) {
    String defaultDir = '';
    notifier.recordOrUpdateAtBat(
      result,
      direction: defaultDir,
      errorPlayerId: errorPlayerId,
    );
    return;
  }

  List<String> directions = [];
  String titleText = '';

  if (result == AtBatResult.singleHit ||
      result == AtBatResult.doubleHit ||
      result == AtBatResult.tripleHit) {
    directions = ['左', '中', '右', '投', '捕', '一', '二', '三', '遊'];
    titleText = '打球方向（外野／内野安打）を選択';
  } else if (result == AtBatResult.homeRun) {
    directions = ['左', '左中間', '中', '右中間', '右'];
    titleText = '本塁打の方向を選択';
  } else if (result == AtBatResult.groundOut) {
    directions = ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'];
    titleText = 'ゴロの方向を選択';
  } else if (result == AtBatResult.flyOut || result == AtBatResult.foulFlyOut) {
    directions = ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'];
    titleText = result == AtBatResult.foulFlyOut
        ? 'ファウルフライ（邪飛）の捕球位置'
        : 'フライ・ライナーの捕球位置';
  }

  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(titleText, style: const TextStyle(fontSize: 16)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: directions.map((dir) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade900,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if ((result == AtBatResult.singleHit ||
                          result == AtBatResult.doubleHit ||
                          result == AtBatResult.tripleHit ||
                          result == AtBatResult.homeRun) &&
                      runners.isNotEmpty) {
                    showHitWithRunnersDialog(
                      context,
                      session: session,
                      notifier: notifier,
                      result: result,
                      direction: dir,
                    );
                  } else {
                    notifier.recordOrUpdateAtBat(
                      result,
                      direction: dir,
                      errorPlayerId: errorPlayerId,
                    );
                  }
                },
                child: Text(
                  dir,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ),
  );
}
