import 'package:flutter/material.dart';

import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'rule_warning.dart';
import 'runner_advance_section.dart';

/// 暴投（WP）・捕逸（PB）など、打席をともなわない進塁を記録するダイアログ。
void showAdvanceRunnersDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
  required String eventName,
}) {
  final runners = session.runners;

  if (runners.isEmpty) {
    showRuleWarning(context, '⚠️ 走者がいないため発生しません。');
    return;
  }

  int r3Choice = 1;
  int r2Choice = 2;
  int r1Choice = 1;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDState) => AlertDialog(
        title: Text('$eventName 時の各走者の進塁先設定'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '各走者の進塁先を個別に選んでください：',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              RunnerAdvanceSection(
                runners: runners,
                findPlayer: session.findPlayer,
                options3rd: const ['本塁生還 (得点)', '3塁そのまま'],
                selected3rd: r3Choice,
                onSelected3rd: (val) {
                  setDState(() {
                    r3Choice = val;
                  });
                },
                options2nd: const ['3塁へ進塁', '2塁そのまま'],
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
              String? original1st = runners.runner1st;
              String? original2nd = runners.runner2nd;
              String? original3rd = runners.runner3rd;

              String? next3rd;
              String? next2nd;
              String? next1st;

              if (original1st != null) {
                if (r1Choice == 0) {
                  next2nd = original1st;
                } else {
                  next1st = original1st;
                }
              }

              if (original2nd != null) {
                if (r2Choice == 0) {
                  next3rd = original2nd;
                } else {
                  if (next2nd == null) {
                    next2nd = original2nd;
                  } else {
                    next3rd = original2nd;
                  }
                }
              }

              if (original3rd != null) {
                if (r3Choice == 0) {
                  calcRuns++;
                  scoredIds.add(original3rd);
                } else {
                  if (next3rd == null) {
                    next3rd = original3rd;
                  } else if (next2nd == null) {
                    next2nd = next3rd;
                    next3rd = original3rd;
                  } else {
                    next1st ??= next2nd;
                    next2nd = next3rd;
                    next3rd = original3rd;
                  }
                }
              }

              BaseRunners nextR = BaseRunners(
                runner1st: next1st,
                runner2nd: next2nd,
                runner3rd: next3rd,
              );
              notifier.recordBaserunningEvent(
                eventName,
                nextR,
                runs: calcRuns,
                scoredIds: scoredIds,
              );
            },
            child: const Text('確定'),
          ),
        ],
      ),
    ),
  );
}
