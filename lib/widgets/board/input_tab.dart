import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../dialogs/advance_runners_dialog.dart';
import '../dialogs/change_pitcher_dialog.dart';
import '../dialogs/jump_batter_dialog.dart';
import '../dialogs/pickoff_dialog.dart';
import '../dialogs/steal_dialog.dart';
import 'action_buttons.dart';
import 'board_header.dart';
import 'diamond_field.dart';

/// 1. 盤面入力タブ。
///
/// 進行状態の購読（`ref.watch`）は親の `ScoreInputScreen` 側で1回だけ行い、
/// ここへはその時点のスナップショット [session] と [notifier] を渡す。
class InputTab extends StatelessWidget {
  final GameSessionState session;
  final GameNotifier notifier;

  /// イニングを移動する（画面側のラッパーを受け取る）。
  final void Function(int targetInning, bool targetIsTop) onJumpToInning;

  /// 打順を移動する。
  final ValueChanged<int> onJumpToBatter;

  /// 現在選択中の打席の入力を削除する。
  final VoidCallback onDeleteCurrentPlateEvent;

  /// 試合を保存して一覧へ戻る。
  final VoidCallback onSaveAndExit;

  const InputTab({
    super.key,
    required this.session,
    required this.notifier,
    required this.onJumpToInning,
    required this.onJumpToBatter,
    required this.onDeleteCurrentPlateEvent,
    required this.onSaveAndExit,
  });

  /// 守備位置からその位置を守っている選手を引く。
  Player? _getPlayerByPosition(String pos) {
    return session.defendingPlayers.where((p) => p.position == pos).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    // 元のコードと同じ読み取り方を保つため、必要な値をローカルへ取り出す。
    final teamNameTop = session.teamNameTop;
    final teamNameBottom = session.teamNameBottom;
    final totalInningsConfig = session.totalInningsConfig;
    final inning = session.inning;
    final isTop = session.isTop;
    final outs = session.outs;
    final runners = session.runners;
    final currentBatters = session.currentBatters;
    final currentBatterIndex = session.currentBatterIndex;
    final activePitcher = session.activePitcher;
    final scoresTop = session.scoresTop;
    final scoresBottom = session.scoresBottom;
    final totalScoreTop = session.totalScoreTop;
    final totalScoreBottom = session.totalScoreBottom;
    final activeEvent = session.activeEvent;
    final maxCycleInCurrentInning = session.maxCycleInCurrentInning;
    final gameEvents = session.gameEvents;
    final currentCycle = session.currentCycle;

    int displayInnings = scoresTop.length > totalInningsConfig
        ? scoresTop.length
        : totalInningsConfig;
    String currentAttackingTeamName = isTop ? teamNameTop : teamNameBottom;
    final currentEv = activeEvent;
    int maxCycle = maxCycleInCurrentInning;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2E14),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BoardTeam(teamNameTop, totalScoreTop, isTop),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    BoardTeam(teamNameBottom, totalScoreBottom, !isTop),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 4),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: const Text(
                          '回移動▶',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...List.generate(displayInnings, (i) {
                        int inn = i + 1;
                        bool isCurrentTop = (inning == inn && isTop);
                        bool isCurrentBottom = (inning == inn && !isTop);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: (inning == inn)
                                  ? Colors.amberAccent
                                  : Colors.white24,
                              width: (inning == inn) ? 1.5 : 0.8,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                color: Colors.black26,
                                alignment: Alignment.center,
                                child: Text(
                                  '$inn回',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  onJumpToInning(inn, true);
                                },
                                child: Container(
                                  width: 32,
                                  height: 22,
                                  color: isCurrentTop
                                      ? Colors.amber.shade700
                                      : Colors.white12,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${scoresTop.length > i ? scoresTop[i] : 0}',
                                    style: TextStyle(
                                      color: isCurrentTop
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: isCurrentTop
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  onJumpToInning(inn, false);
                                },
                                child: Container(
                                  width: 32,
                                  height: 22,
                                  color: isCurrentBottom
                                      ? Colors.amber.shade700
                                      : Colors.black12,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${scoresBottom.length > i ? scoresBottom[i] : 0}',
                                    style: TextStyle(
                                      color: isCurrentBottom
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: isCurrentBottom
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: currentEv != null
                  ? Colors.blue.shade50
                  : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: currentEv != null
                    ? Colors.blue.shade300
                    : Colors.amber.shade400,
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$inning回 ${isTop ? "表" : "裏"} ($currentAttackingTeamName 攻)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currentBatterIndex + 1}番 [${currentBatters[currentBatterIndex].position}] ${currentBatters[currentBatterIndex].name}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (currentEv != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'この打席を削除',
                            onPressed: onDeleteCurrentPlateEvent,
                          ),
                        TextButton.icon(
                          onPressed: () => showJumpBatterDialog(
                            context,
                            session: session,
                            onJumpToBatter: onJumpToBatter,
                          ),
                          icon: const Icon(Icons.touch_app, size: 14),
                          label: const Text(
                            '打者一覧',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.sports, size: 13, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      '対戦投手: [${activePitcher.position}] ${activePitcher.name}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${activePitcher.stats.pitching.inningsPitched}回 ${activePitcher.stats.pitching.strikeouts}K ${activePitcher.stats.pitching.runsAllowed}失点)',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => showChangePitcherDialog(
                        context,
                        session: session,
                        notifier: notifier,
                      ),
                      icon: const Icon(Icons.swap_calls, size: 12),
                      label: const Text('投手交代', style: TextStyle(fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ),
                        minimumSize: const Size(50, 24),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'イニング巡目:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...List.generate(maxCycle + 1, (cIdx) {
                        bool isCur = currentCycle == cIdx;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ChoiceChip(
                            label: Text(
                              '第${cIdx + 1}巡目',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCur
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isCur,
                            selectedColor: Colors.blue.shade200,
                            onSelected: (_) {
                              notifier.selectCycle(cIdx);
                            },
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 12),
                        label: Text(
                          '第${maxCycle + 2}巡目を新設',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.purple.shade50,
                        onPressed: () {
                          notifier.selectCycle(maxCycle + 1, batterIndex: 0);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: currentBatters.asMap().entries.map((entry) {
                int idx = entry.key;
                Player b = entry.value;
                bool isCurrent = idx == currentBatterIndex;
                final evInThisCycle = gameEvents
                    .where(
                      (e) =>
                          !e.isBaserunningEvent &&
                          e.inning == inning &&
                          e.isTop == isTop &&
                          e.cycleIndex == currentCycle &&
                          e.batterIndex == idx,
                    )
                    .firstOrNull;

                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: ChoiceChip(
                    avatar: evInThisCycle != null
                        ? CircleAvatar(
                            radius: 7,
                            backgroundColor:
                                evInThisCycle.result != null &&
                                    evInThisCycle.result!.isHit
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            child: const Text(
                              '✓',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                    label: Text(
                      '${idx + 1}.${b.name}${evInThisCycle != null ? " [${evInThisCycle.displayShortLabel}]" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isCurrent,
                    selectedColor: Colors.amber.shade300,
                    onSelected: (_) {
                      onJumpToBatter(idx);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OUT カウント',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // TODO: アウトカウントは記録済みイベントの再生結果から
                      // 導出される値のため、ランプを直接タップして増減させる
                      // には「アウトだけを記録するイベント種別」を
                      // GameEvent 側に追加する必要がある（UI分割の範囲外）。
                      // ウィジェット側は onTap を受け取れるようにしてある。
                      Row(
                        children: [
                          OutLamp(targetOut: 1, outs: outs),
                          const SizedBox(width: 8),
                          OutLamp(targetOut: 2, outs: outs),
                        ],
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () {
                          notifier.forceChangeInning();
                        },
                        icon: const Icon(Icons.swap_horiz, size: 14),
                        label: const Text(
                          'チェンジ',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                          minimumSize: const Size(50, 24),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 175,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white70,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          left: 10,
                          child: PosTag('左', _getPlayerByPosition('左')),
                        ),
                        Positioned(
                          top: 2,
                          child: PosTag('中', _getPlayerByPosition('中')),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: PosTag('右', _getPlayerByPosition('右')),
                        ),
                        Positioned(
                          top: 36,
                          left: 26,
                          child: PosTag('遊', _getPlayerByPosition('遊')),
                        ),
                        Positioned(
                          top: 36,
                          right: 26,
                          child: PosTag('二', _getPlayerByPosition('二')),
                        ),
                        Positioned(
                          bottom: 24,
                          left: 8,
                          child: PosTag('三', _getPlayerByPosition('三')),
                        ),
                        Positioned(
                          bottom: 24,
                          right: 8,
                          child: PosTag('一', _getPlayerByPosition('一')),
                        ),
                        Positioned(child: PosTag('投', activePitcher)),
                        Positioned(
                          bottom: 2,
                          child: PosTag('捕', _getPlayerByPosition('捕')),
                        ),

                        // TODO: 塁のタップ時の挙動（代走・走者の入れ替えなど）は
                        // まだ仕様が決まっていないため onTap は渡していない。
                        // BaseNode 側は onTap を渡せば反応するようになっている。
                        Positioned(
                          top: 14,
                          child: BaseNode(
                            baseName: '2塁',
                            runner: session.findPlayer(runners.runner2nd),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          child: BaseNode(
                            baseName: '3塁',
                            runner: session.findPlayer(runners.runner3rd),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          child: BaseNode(
                            baseName: '1塁',
                            runner: session.findPlayer(runners.runner1st),
                          ),
                        ),
                        const Positioned(
                          bottom: 14,
                          child: Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_run,
                  size: 15,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                const Text(
                  '走塁:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showStealDialog(
                      context,
                      session: session,
                      notifier: notifier,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      '盗塁',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showAdvanceRunnersDialog(
                      context,
                      session: session,
                      notifier: notifier,
                      eventName: 'ワイルドピッチ (WP)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      'WP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showAdvanceRunnersDialog(
                      context,
                      session: session,
                      notifier: notifier,
                      eventName: 'パスボール (PB)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      'PB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showPickoffDialog(
                      context,
                      session: session,
                      notifier: notifier,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.red.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      '走塁死',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          CategorizedActionButtons(session: session, notifier: notifier),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: onSaveAndExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.save),
              label: const Text(
                '保存して一覧に戻る',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
