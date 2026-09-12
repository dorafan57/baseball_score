import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';
import 'rule_warning.dart';

/// 牽制死・走塁死になった走者を選ぶダイアログ。
///
/// 走者が1人しかいない場合はダイアログを出さずにそのまま記録する。
void showPickoffDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  final runners = session.runners;

  if (session.outs >= 3) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。');
    return;
  }
  if (runners.isEmpty) {
    showRuleWarning(context, '⚠️ 走者がいないため、牽制死・走塁死は発生しません。');
    return;
  }

  List<MapEntry<String, String>> onBase = [];
  if (runners.runner1st != null) {
    onBase.add(MapEntry('1塁', runners.runner1st!));
  }
  if (runners.runner2nd != null) {
    onBase.add(MapEntry('2塁', runners.runner2nd!));
  }
  if (runners.runner3rd != null) {
    onBase.add(MapEntry('3塁', runners.runner3rd!));
  }

  if (onBase.length == 1) {
    _applyPickoff(
      context,
      session: session,
      notifier: notifier,
      base: onBase.first.key,
      runnerId: onBase.first.value,
    );
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('アウトになった走者を選択'),
      children: onBase.map((entry) {
        final b = session.findPlayer(entry.value);
        return SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            _applyPickoff(
              context,
              session: session,
              notifier: notifier,
              base: entry.key,
              runnerId: entry.value,
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${b?.name} (${b?.position})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

/// 選ばれた走者の走塁死を記録する。
void _applyPickoff(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
  required String base,
  required String runnerId,
}) {
  if (session.outs >= 3) {
    showRuleWarning(context, '⚠️ すでに3アウト（チェンジ）状態です。');
    return;
  }
  final player = session.findPlayer(runnerId);
  notifier.recordBaserunningEvent(
    '走塁死 (${player?.name ?? ""} $base)',
    session.runners.without(runnerId),
    batterId: session.currentBatters[session.currentBatterIndex].id,
    runnerId: runnerId,
    outsAdded: 1,
  );
}
