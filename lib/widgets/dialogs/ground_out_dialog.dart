import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'direction_dialog.dart';
import 'rule_warning.dart';
import 'runner_advance_section.dart';

/// ゴロアウト時の走者の進塁・生還・アウトを指定するダイアログ。
///
/// 確定後にゴロの方向を選ぶダイアログを挟んでから記録する。
void showGroundOutDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  final runners = session.runners;

  if (session.outs >= 3 && session.activeEvent == null) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。これ以上アウトになる打席は入力できません。');
    return;
  }

  if (runners.isEmpty) {
    promptDirectionAndRecord(
      context,
      session: session,
      notifier: notifier,
      result: AtBatResult.groundOut,
    );
    return;
  }

  String? new1st;
  String? new2nd = runners.runner1st;
  String? new3rd = runners.runner2nd;
  int runs = (runners.runner3rd != null) ? 1 : 0;
  int rbi = runs;
  // 打者の1アウトに加え、本塁憤死・封殺などで走者がアウトになった分を数える。
  bool r3Out = false;
  bool r2Out = false;
  bool r1Out = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sports_baseball, color: Colors.brown),
            SizedBox(width: 8),
            Flexible(child: Text('ゴロアウト時の走者状況')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '打者はアウト（1アウト加算）。走者の進塁・生還を選択してください：',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  ActionChip(
                    label: const Text(
                      '走者進塁なし (残塁)',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.grey.shade100,
                    onPressed: () {
                      setDState(() {
                        runs = 0;
                        rbi = 0;
                        new1st = runners.runner1st;
                        new2nd = runners.runner2nd;
                        new3rd = runners.runner3rd;
                        r3Out = false;
                        r2Out = false;
                        r1Out = false;
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text(
                      '進塁打 (全走者1つ進む)',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.brown.shade50,
                    onPressed: () {
                      setDState(() {
                        runs = (runners.runner3rd != null) ? 1 : 0;
                        rbi = runs;
                        new3rd = runners.runner2nd;
                        new2nd = runners.runner1st;
                        new1st = null;
                        r3Out = false;
                        r2Out = false;
                        r1Out = false;
                      });
                    },
                  ),
                ],
              ),
              const Divider(height: 18),
              RunnerAdvanceSection(
                runners: runners,
                findPlayer: session.findPlayer,
                options3rd: const ['本塁生還 (得点・打点1)', '3塁そのまま', '本塁憤死 (アウト)'],
                selected3rd: runs > 0
                    ? 0
                    : (new3rd == runners.runner3rd ? 1 : 2),
                onSelected3rd: (val) {
                  setDState(() {
                    if (val == 0) {
                      runs = 1;
                      rbi = 1;
                      new3rd = runners.runner2nd;
                      r3Out = false;
                    } else if (val == 1) {
                      runs = 0;
                      rbi = 0;
                      new3rd = runners.runner3rd;
                      r3Out = false;
                    } else {
                      runs = 0;
                      rbi = 0;
                      new3rd = runners.runner2nd;
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
                      if (new2nd == runners.runner2nd) {
                        new2nd = null;
                      }
                      r2Out = true;
                    }
                  });
                },
                options1st: const ['2塁へ進塁', '1塁そのまま', '2塁封殺 (フォースアウト)'],
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
                      if (new1st == runners.runner1st) {
                        new1st = null;
                      }
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
              backgroundColor: const Color(0xFF5D4037),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final hasAdvanced =
                  (runs > 0) ||
                  (new3rd == runners.runner2nd) ||
                  (new2nd == runners.runner1st);
              final finalResult = hasAdvanced
                  ? AtBatResult.groundAdvance
                  : AtBatResult.groundOut;
              // 打者の1アウトに、本塁憤死・封殺で追加されたアウトを加算する。
              final outsAdded =
                  finalResult.guaranteedOuts +
                  (r3Out ? 1 : 0) +
                  (r2Out ? 1 : 0) +
                  (r1Out ? 1 : 0);

              showDialog(
                context: context,
                builder: (dirCtx) => SimpleDialog(
                  title: const Text('ゴロの方向を選択'),
                  children: ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'].map((
                    dir,
                  ) {
                    return SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(dirCtx);
                        // 打者自身のアウト（このダイアログでは常に1つ発生する）だけで
                        // 3アウト目が成立する場合はタイムプレイの例外により得点無効。
                        // 封殺・本塁憤死など打者以外の走者アウトが絡んで3アウト目に
                        // なる場合は従来通り得点を有効とする。
                        final hasExtraRunnerOut = r3Out || r2Out || r1Out;
                        final invalidatedByTimingRule =
                            !hasExtraRunnerOut &&
                            (session.outs + outsAdded >= 3);
                        final finalRuns = invalidatedByTimingRule ? 0 : runs;
                        final finalRbi = invalidatedByTimingRule ? 0 : rbi;
                        List<String> scoredIds = [];
                        if (finalRuns > 0 && runners.runner3rd != null) {
                          scoredIds.add(runners.runner3rd!);
                        }
                        notifier.applyCustomHitResult(
                          finalResult,
                          dir,
                          BaseRunners(
                            runner1st: new1st,
                            runner2nd: new2nd,
                            runner3rd: new3rd,
                          ),
                          finalRuns,
                          finalRbi,
                          scoredIds,
                          outsAdded: outsAdded,
                        );
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
              );
            },
            child: Text(
              '確定 (${1 + (r3Out ? 1 : 0) + (r2Out ? 1 : 0) + (r1Out ? 1 : 0)}アウト${runs > 0 ? "・$runs点" : ""})',
            ),
          ),
        ],
      ),
    ),
  );
}
