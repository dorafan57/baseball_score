import 'package:flutter/foundation.dart';

import '../models/at_bat_result.dart';
import '../models/base_runners.dart';

/// 打席結果から算出した、走者の進塁結果。
@immutable
class AdvanceState {
  /// 打席終了後の走者状況。
  final BaseRunners runners;

  /// この打席で入った得点。
  final int runs;

  /// 打者に記録される打点。
  final int rbi;

  /// 生還した走者の選手IDの一覧。
  final List<String> scoredPlayerIds;

  /// この打席で増えたアウト数。
  final int outsAdded;

  const AdvanceState({
    required this.runners,
    required this.runs,
    required this.rbi,
    required this.scoredPlayerIds,
    required this.outsAdded,
  });
}

/// 打席結果に対する **標準的な** 進塁を計算する。
///
/// 「単打なら走者は1つずつ進む」といった定型の進塁だけを扱う。
/// 追加進塁や走塁死をともなうケースは、UI 側のダイアログで走者ごとの
/// 行き先とアウト数を指定し、その結果を直接イベントに記録する。
///
/// ここで扱う標準進塁には走者アウトの選択肢がないため、アウト数は
/// [AtBatResult.guaranteedOuts]（結果ごとに必ず発生するアウト数）と一致する。
AdvanceState calculateDefaultAdvance({
  required AtBatResult result,
  required BaseRunners runners,
  required String batterId,
}) {
  final scored = <String>[];
  int runs = 0;
  int rbi = 0;

  /// 走者を生還させる。[withRbi] が false のときは得点のみで打点はつかない。
  void score(String? runnerId, {bool withRbi = true}) {
    if (runnerId == null) {
      return;
    }
    runs++;
    if (withRbi) {
      rbi++;
    }
    scored.add(runnerId);
  }

  BaseRunners next;

  switch (result) {
    case AtBatResult.singleHit:
      score(runners.runner3rd);
      next = BaseRunners(
        runner1st: batterId,
        runner2nd: runners.runner1st,
        runner3rd: runners.runner2nd,
      );
      break;

    case AtBatResult.doubleHit:
      score(runners.runner3rd);
      score(runners.runner2nd);
      next = BaseRunners(
        runner2nd: batterId,
        runner3rd: runners.runner1st,
      );
      break;

    case AtBatResult.tripleHit:
      score(runners.runner3rd);
      score(runners.runner2nd);
      score(runners.runner1st);
      next = BaseRunners(runner3rd: batterId);
      break;

    case AtBatResult.homeRun:
      score(runners.runner3rd);
      score(runners.runner2nd);
      score(runners.runner1st);
      score(batterId);
      next = BaseRunners.empty;
      break;

    case AtBatResult.walk:
    case AtBatResult.hitByPitch:
    case AtBatResult.strikeoutSafe:
      // 塁が詰まっている走者だけが押し出される。
      final has1st = runners.runner1st != null;
      final has2nd = runners.runner2nd != null;
      final has3rd = runners.runner3rd != null;

      String? next2nd = runners.runner2nd;
      String? next3rd = runners.runner3rd;

      if (has1st && has2nd && has3rd) {
        // 満塁からの押し出し。打点がつく。
        score(runners.runner3rd);
      }
      if (has1st && has2nd) {
        next3rd = runners.runner2nd;
      }
      if (has1st) {
        next2nd = runners.runner1st;
      }
      next = BaseRunners(
        runner1st: batterId,
        runner2nd: next2nd,
        runner3rd: next3rd,
      );
      break;

    case AtBatResult.error:
      // 失策による得点には打点をつけない。
      score(runners.runner3rd, withRbi: false);
      next = BaseRunners(
        runner1st: batterId,
        runner2nd: runners.runner1st,
        runner3rd: runners.runner2nd,
      );
      break;

    case AtBatResult.doublePlay:
      // 打者と1塁走者がアウト。他の走者はその場に残る。
      next = BaseRunners(
        runner2nd: runners.runner2nd,
        runner3rd: runners.runner3rd,
      );
      break;

    default:
      // 三振・ゴロ・フライなどの凡退、および走者の行き先を個別指定する
      // 結果（犠打・犠飛・進塁打）では走者は動かさない。
      next = runners;
      break;
  }

  return AdvanceState(
    runners: next,
    runs: runs,
    rbi: rbi,
    outsAdded: result.guaranteedOuts,
    scoredPlayerIds: scored,
  );
}
