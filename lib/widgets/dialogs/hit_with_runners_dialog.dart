import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'error_player_selection_dialog.dart';
import 'rule_warning.dart';
import 'runner_advance_section.dart';

/// 安打（単打・二塁打・三塁打）時の走者・打者の進塁先を確認するダイアログ。
///
/// この画面には走者がアウトになる選択肢がないため、追加アウトは発生しない。
/// 「追加進塁は敵失によるもの」にチェックを入れた場合は、
/// 続けてエラーを犯した野手の選択ダイアログを表示する。
void showHitWithRunnersDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
  required AtBatResult result,
  required String direction,
}) {
  final runners = session.runners;

  if (session.outs >= 3 && session.activeEvent == null) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。');
    return;
  }

  if (result == AtBatResult.homeRun) {
    notifier.recordOrUpdateAtBat(result, direction: direction);
    return;
  }

  if (runners.isEmpty) {
    if (result == AtBatResult.error) {
      showErrorPlayerSelectionDialog(
        context,
        session: session,
        notifier: notifier,
        result: result,
        direction: direction,
        customRunners: BaseRunners(
          runner1st: session.currentBatters[session.currentBatterIndex].id,
        ),
        runs: 0,
        rbi: 0,
        scoredIds: const [],
      );
    } else {
      notifier.recordOrUpdateAtBat(result, direction: direction);
    }
    return;
  }

  String batterId = session.currentBatters[session.currentBatterIndex].id;
  int r3Choice = 0;
  int r2Choice = 0;
  int r1Choice = 0;
  int batterChoice = 0;
  bool isErrorExtraAdvance = false;

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
                '打者 [${session.currentBatters[session.currentBatterIndex].name}] は${result.label}です。\n各走者・打者の進塁先を選んでください：',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),

              RunnerAdvanceSection(
                runners: runners,
                findPlayer: session.findPlayer,
                options3rd: const ['本塁生還 (得点)', '3塁で止まる'],
                selected3rd: r3Choice,
                onSelected3rd: (val) {
                  setDState(() {
                    r3Choice = val;
                  });
                },
                options2nd: result == AtBatResult.singleHit
                    ? const ['3塁へ進塁', '2塁で止まる', '本塁生還 (追加進塁)']
                    : const ['本塁生還 (得点)', '2塁で止まる', '3塁で止まる'],
                selected2nd: r2Choice,
                onSelected2nd: (val) {
                  setDState(() {
                    r2Choice = val;
                  });
                },
                options1st: result == AtBatResult.singleHit
                    ? const ['2塁へ進塁', '1塁で止まる', '3塁へ (追加進塁)']
                    : const ['3塁へ進塁', '2塁で止まる', '本塁生還 (追加進塁)'],
                selected1st: r1Choice,
                onSelected1st: (val) {
                  setDState(() {
                    r1Choice = val;
                  });
                },
              ),

              // 打者自身の進塁先はこのダイアログ固有のため、共通セクションの外に置く。
              RunnerChoiceTile(
                '打者: ${session.currentBatters[session.currentBatterIndex].name}',
                result == AtBatResult.singleHit
                    ? const ['1塁へ (標準)', '2塁へ (追加進塁)']
                    : result == AtBatResult.doubleHit
                    ? const ['2塁へ (標準)', '3塁へ (追加進塁)']
                    : const ['3塁へ (標準)', '本塁へ (追加進塁)'],
                (val) {
                  setDState(() {
                    batterChoice = val;
                  });
                },
                batterChoice,
              ),

              const Divider(height: 20),
              CheckboxListTile(
                title: const Text(
                  '追加進塁は守備側のエラー(敵失)によるもの',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                value: isErrorExtraAdvance,
                onChanged: (val) {
                  setDState(() {
                    isErrorExtraAdvance = val ?? false;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
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
              int calcRbi = 0;
              List<String> scoredIds = [];
              String? final3rd;
              String? final2nd;
              String? final1st;

              int baseRbi = 0;
              if (result == AtBatResult.singleHit) {
                if (runners.runner3rd != null) {
                  baseRbi++;
                }
              } else if (result == AtBatResult.doubleHit) {
                if (runners.runner3rd != null) {
                  baseRbi++;
                }
                if (runners.runner2nd != null) {
                  baseRbi++;
                }
              } else if (result == AtBatResult.tripleHit) {
                if (runners.runner3rd != null) {
                  baseRbi++;
                }
                if (runners.runner2nd != null) {
                  baseRbi++;
                }
                if (runners.runner1st != null) {
                  baseRbi++;
                }
              }
              calcRbi = baseRbi;

              String? bDest = batterChoice == 0
                  ? (result == AtBatResult.singleHit
                        ? '1st'
                        : result == AtBatResult.doubleHit
                        ? '2nd'
                        : '3rd')
                  : (result == AtBatResult.singleHit
                        ? '2nd'
                        : result == AtBatResult.doubleHit
                        ? '3rd'
                        : 'home');

              if (bDest == '1st') {
                final1st = batterId;
              }
              if (bDest == '2nd') {
                final2nd = batterId;
              }
              if (bDest == '3rd') {
                final3rd = batterId;
              }
              if (bDest == 'home') {
                calcRuns++;
                scoredIds.add(batterId);
                if (!isErrorExtraAdvance) {
                  calcRbi++;
                }
              }

              if (runners.runner1st != null) {
                if (r1Choice == 0) {
                  String target = result == AtBatResult.singleHit
                      ? '2nd'
                      : '3rd';
                  if (target == '2nd') {
                    final2nd ??= runners.runner1st;
                  } else if (target == '3rd') {
                    final3rd ??= runners.runner1st;
                  }
                } else if (r1Choice == 1) {
                  String target = result == AtBatResult.singleHit
                      ? '1st'
                      : '2nd';
                  if (target == '1st') {
                    final1st ??= runners.runner1st;
                  } else if (target == '2nd') {
                    final2nd ??= runners.runner1st;
                  }
                } else {
                  String target = result == AtBatResult.singleHit
                      ? '3rd'
                      : 'home';
                  if (target == '3rd') {
                    final3rd ??= runners.runner1st;
                  } else if (target == 'home') {
                    calcRuns++;
                    scoredIds.add(runners.runner1st!);
                    if (!isErrorExtraAdvance) {
                      calcRbi++;
                    }
                  }
                }
              }

              if (runners.runner2nd != null) {
                if (r2Choice == 0) {
                  if (result == AtBatResult.singleHit) {
                    final3rd ??= runners.runner2nd;
                  } else {
                    calcRuns++;
                    scoredIds.add(runners.runner2nd!);
                  }
                } else if (r2Choice == 1) {
                  final2nd ??= runners.runner2nd;
                } else {
                  if (result == AtBatResult.singleHit) {
                    calcRuns++;
                    scoredIds.add(runners.runner2nd!);
                    if (!isErrorExtraAdvance) {
                      calcRbi++;
                    }
                  } else {
                    final3rd ??= runners.runner2nd;
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

              if (isErrorExtraAdvance) {
                showErrorPlayerSelectionDialog(
                  context,
                  session: session,
                  notifier: notifier,
                  result: result,
                  direction: direction,
                  customRunners: customRunners,
                  runs: calcRuns,
                  rbi: calcRbi,
                  scoredIds: scoredIds,
                );
              } else {
                notifier.applyCustomHitResult(
                  result,
                  direction,
                  customRunners,
                  calcRuns,
                  calcRbi,
                  scoredIds,
                  // この画面では走者がアウトになる選択肢がないため、
                  // 安打の必須アウト数（0）のみで確定する。
                  outsAdded: result.guaranteedOuts,
                );
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    ),
  );
}
