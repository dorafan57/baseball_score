import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'runner_advance_section.dart';

/// 併殺（ダブルプレイ）の送球経路と、アウトにならない走者（2塁・3塁）の
/// 進塁先を選択するダイアログ。打者と1塁走者は必ずアウトになる前提。
void showDoublePlayRouteDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
  String? errorPlayerId,
}) {
  final runners = session.runners;
  // 打者・1塁走者の2つのアウトでこのプレーの3アウト目が成立する場合、
  // 1塁走者アウトは封殺（フォースアウト）であるため、野球規則上
  // 3塁走者が先に生還していても得点は認められない（タイムプレイの例外）。
  final invalidatedByTimingRule = session.outs >= 1;

  List<String> route = [];
  String? new2nd = runners.runner2nd;
  String? new3rd = runners.runner3rd;
  int runs = 0;
  int rbi = 0;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDState) => AlertDialog(
        title: const Text('併殺の経路を選択'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.infinity,
                child: Text(
                  route.isEmpty ? "(未選択)" : route.join(" → "),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'].map((
                  pos,
                ) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () {
                      setDState(() {
                        route.add(pos);
                      });
                    },
                    child: Text(pos),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  setDState(() {
                    route.clear();
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('クリア'),
              ),
              if (runners.runner2nd != null || runners.runner3rd != null) ...[
                const Divider(height: 20),
                const Text(
                  '打者・1塁走者はアウト。他の走者の進塁先を選択してください：',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                if (invalidatedByTimingRule) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '⚠️ このプレーが3アウト目（1塁走者の封殺）となるため、'
                    '規則上この打席での得点は無効になります。',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 8),
                RunnerAdvanceSection(
                  runners: BaseRunners(
                    runner2nd: runners.runner2nd,
                    runner3rd: runners.runner3rd,
                  ),
                  findPlayer: session.findPlayer,
                  options3rd: const ['本塁生還 (得点・打点1)', '3塁そのまま'],
                  selected3rd: runs > 0 ? 0 : 1,
                  onSelected3rd: (val) {
                    setDState(() {
                      if (val == 0) {
                        runs = 1;
                        rbi = 1;
                        new3rd = null;
                      } else {
                        runs = 0;
                        rbi = 0;
                        new3rd = runners.runner3rd;
                      }
                    });
                  },
                  options2nd: const ['3塁へ進塁', '2塁そのまま'],
                  selected2nd: new3rd == runners.runner2nd ? 0 : 1,
                  onSelected2nd: (val) {
                    setDState(() {
                      if (val == 0) {
                        new3rd = runners.runner2nd;
                        new2nd = null;
                      } else {
                        new2nd = runners.runner2nd;
                        if (new3rd == runners.runner2nd) {
                          new3rd = null;
                        }
                      }
                    });
                  },
                  options1st: const [],
                  selected1st: 0,
                  onSelected1st: (_) {},
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              String direction = route.join('→');
              if (direction.isEmpty) {
                direction = '併殺';
              }
              final finalRuns = invalidatedByTimingRule ? 0 : runs;
              final finalRbi = invalidatedByTimingRule ? 0 : rbi;
              final scoredIds = (finalRuns > 0 && runners.runner3rd != null)
                  ? [runners.runner3rd!]
                  : <String>[];
              notifier.applyCustomHitResult(
                AtBatResult.doublePlay,
                direction,
                BaseRunners(runner2nd: new2nd, runner3rd: new3rd),
                finalRuns,
                finalRbi,
                scoredIds,
                outsAdded: AtBatResult.doublePlay.guaranteedOuts,
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
