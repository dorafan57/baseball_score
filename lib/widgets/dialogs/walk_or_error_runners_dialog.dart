import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'rule_warning.dart';
import 'runner_advance_section.dart';

/// 四球・死球・敵失など「打者が1塁に出る」結果での走者の進塁先を確認するダイアログ。
///
/// この画面には走者がアウトになる選択肢がないため、追加アウトは発生しない。
void showWalkOrErrorRunnersDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
  required AtBatResult result,
  String? errorPlayerId,
  String direction = '',
}) {
  final runners = session.runners;

  if (session.outs >= 3 && session.activeEvent == null) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。');
    return;
  }

  String batterId = session.currentBatters[session.currentBatterIndex].id;

  if (runners.isEmpty) {
    notifier.recordOrUpdateAtBat(
      result,
      direction: direction,
      errorPlayerId: errorPlayerId,
    );
    return;
  }

  int r3Choice = 1;
  int r2Choice = 2;
  int r1Choice = 1;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDState) => AlertDialog(
        title: Text('${result.label}時の走者・打者の進塁確認'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '打者 [${session.currentBatters[session.currentBatterIndex].name}] の${result.label}です。各走者および打者の進塁先を選んでください：',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              RunnerAdvanceSection(
                runners: runners,
                findPlayer: session.findPlayer,
                options3rd: const ['本塁生還 (得点 ※打点なし)', '3塁そのまま'],
                selected3rd: r3Choice,
                onSelected3rd: (val) {
                  setDState(() {
                    r3Choice = val;
                  });
                },
                options2nd: const ['3塁へ進塁', '本塁生還 (得点 ※打点なし)', '2塁そのまま'],
                selected2nd: r2Choice,
                onSelected2nd: (val) {
                  setDState(() {
                    r2Choice = val;
                  });
                },
                options1st: const ['2塁へ進塁', '1塁そのまま'],
                selected1st: r1Choice,
                onSelected1st: (val) {
                  setDState(() {
                    r1Choice = val;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);

              int calcRuns = 0;
              List<String> scoredIds = [];
              String? final3rd;
              String? final2nd;
              String? final1st = batterId;

              if (runners.runner1st != null) {
                if (r1Choice == 0) {
                  final2nd = runners.runner1st;
                } else {
                  final1st = runners.runner1st;
                }
              }

              if (runners.runner2nd != null) {
                if (r2Choice == 0) {
                  final3rd = runners.runner2nd;
                } else if (r2Choice == 1) {
                  calcRuns++;
                  scoredIds.add(runners.runner2nd!);
                } else {
                  if (final2nd == null) {
                    final2nd = runners.runner2nd;
                  } else {
                    final3rd = runners.runner2nd;
                  }
                }
              }

              if (runners.runner3rd != null) {
                if (r3Choice == 0) {
                  calcRuns++;
                  scoredIds.add(runners.runner3rd!);
                } else {
                  if (final3rd == null) {
                    final3rd = runners.runner3rd;
                  } else if (final2nd == null) {
                    final2nd = final3rd;
                    final3rd = runners.runner3rd;
                  } else {
                    final1st = final2nd;
                    final2nd = final3rd;
                    final3rd = runners.runner3rd;
                  }
                }
              }

              BaseRunners customRunners = BaseRunners(
                runner1st: final1st,
                runner2nd: final2nd,
                runner3rd: final3rd,
              );
              notifier.applyCustomHitResult(
                result,
                direction,
                customRunners,
                calcRuns,
                0,
                scoredIds,
                // この画面では走者がアウトになる選択肢がないため、
                // 結果ごとの必須アウト数（四球・敵失はいずれも0）のみで確定する。
                outsAdded: result.guaranteedOuts,
                errorPlayerId: errorPlayerId,
              );
            },
            child: const Text('確定'),
          ),
        ],
      ),
    ),
  );
}
