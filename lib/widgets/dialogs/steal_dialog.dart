import 'package:flutter/material.dart';

import '../../models/base_runners.dart';
import '../../providers/game_provider.dart';
import 'rule_warning.dart';

/// 盗塁した走者を選ぶダイアログ。
void showStealDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  final runners = session.runners;

  if (runners.isEmpty) {
    showRuleWarning(context, '⚠️ 走者がいないため、盗塁はできません。');
    return;
  }
  List<MapEntry<String, String>> onBase = [];
  if (runners.runner1st != null) {
    onBase.add(
      MapEntry(
        '1塁走者 (${session.findPlayer(runners.runner1st)?.name})',
        runners.runner1st!,
      ),
    );
  }
  if (runners.runner2nd != null) {
    onBase.add(
      MapEntry(
        '2塁走者 (${session.findPlayer(runners.runner2nd)?.name})',
        runners.runner2nd!,
      ),
    );
  }
  if (runners.runner3rd != null) {
    onBase.add(
      MapEntry(
        '3塁走者 (${session.findPlayer(runners.runner3rd)?.name})',
        runners.runner3rd!,
      ),
    );
  }

  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('盗塁した走者を選択'),
      children: onBase.map((entry) {
        return SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            _executeStealForRunner(
              session: session,
              notifier: notifier,
              runnerId: entry.value,
            );
          },
          child: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        );
      }).toList(),
    ),
  );
}

/// 盗塁成功を記録する。
///
/// 盗塁した走者と、その後ろにいる走者がそれぞれ1つずつ進塁する
/// （重盗を想定した挙動）ものとして扱う。
void _executeStealForRunner({
  required GameSessionState session,
  required GameNotifier notifier,
  required String runnerId,
}) {
  final runners = session.runners;
  final runnerName = session.findPlayer(runnerId)?.name ?? '';
  BaseRunners nextRunners;
  int calcRuns = 0;
  final scoredIds = <String>[];

  if (runnerId == runners.runner3rd) {
    // 本盗。3塁走者が生還し、後続はひとつずつ進む。
    calcRuns++;
    scoredIds.add(runnerId);
    nextRunners = BaseRunners(
      runner2nd: runners.runner1st,
      runner3rd: runners.runner2nd,
    );
  } else if (runnerId == runners.runner2nd) {
    nextRunners = BaseRunners(
      runner2nd: runners.runner1st,
      runner3rd: runners.runner2nd,
    );
  } else {
    nextRunners = BaseRunners(
      runner2nd: runners.runner1st,
      runner3rd: runners.runner3rd,
    );
  }

  notifier.recordBaserunningEvent(
    '盗塁成功 ($runnerName)',
    nextRunners,
    isSteal: true,
    batterId: session.currentBatters[session.currentBatterIndex].id,
    runnerId: runnerId,
    runs: calcRuns,
    scoredIds: scoredIds,
  );
}
