import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'rule_warning.dart';
import 'runner_advance_section.dart';

/// 犠打（送りバント）時の走者の進塁・走塁死を指定するダイアログ。
void showSacrificeHitDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  final runners = session.runners;

  if (session.outs >= 3 && session.activeEvent == null) {
    showRuleWarning(context, 'すでに3アウトです。');
    return;
  }
  if (runners.isEmpty) {
    showRuleWarning(context, '⚠️ 走者がいない場面での犠打（送りバント）は記録できません。');
    return;
  }

  String? new1st;
  String? new2nd = runners.runner1st;
  String? new3rd = runners.runner2nd;
  int runs = (runners.runner3rd != null) ? 1 : 0;
  int rbi = runs;
  // 打者の1アウトに加え、走塁死で走者がアウトになった分を数える。
  bool r3Out = false;
  bool r2Out = false;
  bool r1Out = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDState) => AlertDialog(
        title: const Text('犠打（バント）の進塁確認'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '打者はアウトになります。各走者の進塁先を選んでください：',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              RunnerAdvanceSection(
                runners: runners,
                findPlayer: session.findPlayer,
                options3rd: const ['本塁生還 (得点)', '3塁そのまま', '走塁死'],
                selected3rd: runs > 0 ? 0 : (new3rd != null ? 1 : 2),
                onSelected3rd: (val) {
                  setDState(() {
                    if (val == 0) {
                      runs = 1;
                      rbi = 1;
                      new3rd = null;
                      r3Out = false;
                    } else if (val == 1) {
                      runs = 0;
                      rbi = 0;
                      new3rd = runners.runner3rd;
                      r3Out = false;
                    } else {
                      runs = 0;
                      rbi = 0;
                      new3rd = null;
                      r3Out = true;
                    }
                  });
                },
                options2nd: const ['3塁へ進塁', '2塁そのまま', '走塁死'],
                selected2nd: new3rd == runners.runner2nd
                    ? 0
                    : (new2nd == runners.runner2nd ? 1 : 2),
                onSelected2nd: (val) {
                  setDState(() {
                    if (val == 0) {
                      new3rd = runners.runner2nd;
                      r2Out = false;
                    } else if (val == 1) {
                      new2nd = runners.runner2nd;
                      if (new3rd == runners.runner2nd) {
                        new3rd = null;
                      }
                      r2Out = false;
                    } else {
                      if (new3rd == runners.runner2nd) {
                        new3rd = null;
                      }
                      new2nd = null;
                      r2Out = true;
                    }
                  });
                },
                options1st: const ['2塁へ進塁', '1塁そのまま', '走塁死'],
                selected1st: new2nd == runners.runner1st
                    ? 0
                    : (new1st == runners.runner1st ? 1 : 2),
                onSelected1st: (val) {
                  setDState(() {
                    if (val == 0) {
                      new2nd = runners.runner1st;
                      r1Out = false;
                    } else if (val == 1) {
                      new1st = runners.runner1st;
                      if (new2nd == runners.runner1st) {
                        new2nd = null;
                      }
                      r1Out = false;
                    } else {
                      if (new2nd == runners.runner1st) {
                        new2nd = null;
                      }
                      new1st = null;
                      r1Out = true;
                    }
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
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              List<String> scoredIds = [];
              if (runs > 0 && runners.runner3rd != null) {
                scoredIds.add(runners.runner3rd!);
              }
              notifier.applyCustomHitResult(
                AtBatResult.sacrificeHit,
                '投',
                BaseRunners(
                  runner1st: new1st,
                  runner2nd: new2nd,
                  runner3rd: new3rd,
                ),
                runs,
                rbi,
                scoredIds,
                outsAdded:
                    AtBatResult.sacrificeHit.guaranteedOuts +
                    (r3Out ? 1 : 0) +
                    (r2Out ? 1 : 0) +
                    (r1Out ? 1 : 0),
              );
            },
            child: Text(
              '確定 (${1 + (r3Out ? 1 : 0) + (r2Out ? 1 : 0) + (r1Out ? 1 : 0)}アウト)',
            ),
          ),
        ],
      ),
    ),
  );
}
