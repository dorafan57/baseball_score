import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'rule_warning.dart';
import 'runner_advance_section.dart';

/// 犠飛（犠牲フライ）／フライ進塁（タッチアップ）時の走者状況を指定するダイアログ。
///
/// 確定後にフライの方向を選ぶダイアログを挟んでから記録する。
void showSacrificeFlyDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  final runners = session.runners;

  if (session.outs >= 3 && session.activeEvent == null) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。');
    return;
  }
  if (session.outs >= 2 && session.activeEvent == null) {
    showRuleWarning(context, '2アウトの場面で犠牲フライ・フライ進塁は記録できません。');
    return;
  }
  if (runners.isEmpty) {
    showRuleWarning(context, '⚠️ 走者がいない場面でのフライ進塁は発生しません。');
    return;
  }

  int runs = (runners.runner3rd != null) ? 1 : 0;
  int rbi = runs;
  String? new3rd = runners.runner2nd;
  String? new2nd = runners.runner1st;
  String? new1st;
  // 打者の1アウトに加え、走塁死で走者がアウトになった分を数える。
  bool r3Out = false;
  bool r2Out = false;
  bool r1Out = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDState) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: Colors.purple),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                runners.runner3rd != null ? '犠飛（犠牲フライ）の確認' : 'フライ進塁（タッチアップ）の確認',
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: runs > 0 ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      runs > 0 ? Icons.check_circle : Icons.info_outline,
                      color: runs > 0 ? Colors.green : Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        runs > 0
                            ? '3塁走者生還により【犠牲フライ】（打点1・打数免除）として記録されます。'
                            : '生還走者がいないため【飛球進塁打】（打数カウントあり）として記録されます。',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: runs > 0
                              ? Colors.green.shade900
                              : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '各走者の進塁・残塁状況：',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              RunnerAdvanceSection(
                runners: runners,
                findPlayer: session.findPlayer,
                options3rd: const ['本塁生還 (得点)', '3塁そのまま', '走塁死'],
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
                options2nd: const ['3塁へタッチアップ', '2塁そのまま', '走塁死'],
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
                options1st: const ['2塁へタッチアップ', '1塁そのまま', '走塁死'],
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
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final finalResult = (runs > 0)
                  ? AtBatResult.sacrificeFly
                  : AtBatResult.flyAdvance;

              showDialog(
                context: context,
                builder: (dirCtx) => SimpleDialog(
                  title: const Text('フライの方向を選択'),
                  children: ['左', '中', '右'].map((dir) {
                    return SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(dirCtx);
                        List<String> scoredIds = [];
                        if (runs > 0 && runners.runner3rd != null) {
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
                          runs,
                          rbi,
                          scoredIds,
                          outsAdded:
                              finalResult.guaranteedOuts +
                              (r3Out ? 1 : 0) +
                              (r2Out ? 1 : 0) +
                              (r1Out ? 1 : 0),
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
              '確定 (${1 + (r3Out ? 1 : 0) + (r2Out ? 1 : 0) + (r1Out ? 1 : 0)}アウト${runs > 0 ? "・$runs得点" : ""})',
            ),
          ),
        ],
      ),
    ),
  );
}
