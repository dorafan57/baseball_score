import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../models/resolved_event.dart';
import '../../providers/game_provider.dart';
import '../dialogs/edit_batter_dialog.dart';
import 'stat_widgets.dart';

/// 2. スコア・個人成績タブ。
///
/// 進行状態の購読（`ref.watch`）は親の `ScoreInputScreen` 側で1回だけ行い、
/// ここへはその時点のスナップショット [session] と [notifier] を渡す。
class ScoreStatsTab extends StatelessWidget {
  final GameSessionState session;
  final GameNotifier notifier;

  /// 表示中のチーム（0: 先攻 / 1: 後攻）。
  final int teamIndex;
  final ValueChanged<int> onTeamChanged;

  /// イニングを移動して盤面入力タブへ切り替える。
  final void Function(int targetInning, bool targetIsTop) onJumpToInning;

  /// 盤面入力タブへ切り替える。
  final VoidCallback onShowBoardTab;

  const ScoreStatsTab({
    super.key,
    required this.session,
    required this.notifier,
    required this.teamIndex,
    required this.onTeamChanged,
    required this.onJumpToInning,
    required this.onShowBoardTab,
  });

  @override
  Widget build(BuildContext context) {
    // 元のコードと同じ読み取り方を保つため、必要な値をローカルへ取り出す。
    final teamNameTop = session.teamNameTop;
    final teamNameBottom = session.teamNameBottom;
    final totalInningsConfig = session.totalInningsConfig;
    final inning = session.inning;
    final isTop = session.isTop;
    final playersTop = session.playersTop;
    final playersBottom = session.playersBottom;
    final scoresTop = session.scoresTop;
    final scoresBottom = session.scoresBottom;
    final totalScoreTop = session.totalScoreTop;
    final totalScoreBottom = session.totalScoreBottom;
    final totalHitsTop = session.totalHitsTop;
    final totalHitsBottom = session.totalHitsBottom;
    final errorsTop = session.errorsTop;
    final errorsBottom = session.errorsBottom;

    int displayInnings = scoresTop.length > totalInningsConfig
        ? scoresTop.length
        : totalInningsConfig;
    List<Player> activeBatters = (teamIndex == 0) ? playersTop : playersBottom;
    List<Player> activePitchers = (teamIndex == 0) ? playersTop : playersBottom;
    String activeTeamName = (teamIndex == 0) ? teamNameTop : teamNameBottom;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ラインスコア',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<int>(
                value: totalInningsConfig,
                underline: const SizedBox(),
                items: [5, 7, 9]
                    .map(
                      (val) =>
                          DropdownMenuItem(value: val, child: Text('$val回制')),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    notifier.setTotalInnings(val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(32),
                columnWidths: const {0: FixedColumnWidth(110)},
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.8,
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFF0D2E14)),
                    children: [
                      StatsHeaderCell('チーム (移動)'),
                      ...List.generate(
                        displayInnings,
                        (i) => StatsHeaderCell('${i + 1}'),
                      ),
                      StatsHeaderCell('R', isAccent: true),
                      StatsHeaderCell('H'),
                      StatsHeaderCell('E'),
                    ],
                  ),
                  TableRow(
                    decoration: BoxDecoration(
                      color: isTop ? Colors.green.shade50 : Colors.white,
                    ),
                    children: [
                      StatsDataCell(teamNameTop, isBold: true),
                      ...List.generate(displayInnings, (i) {
                        int inn = i + 1;
                        bool isCurrent = (inning == inn && isTop);
                        return InkWell(
                          onTap: () {
                            onJumpToInning(inn, true);
                          },
                          child: Container(
                            color: isCurrent
                                ? Colors.amber.shade200
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: Text(
                              '${scoresTop.length > i ? scoresTop[i] : 0}',
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                      StatsDataCell(
                        '$totalScoreTop',
                        isBold: true,
                        textColor: Colors.green.shade900,
                      ),
                      StatsDataCell('$totalHitsTop', isBold: true),
                      StatsDataCell('$errorsTop'),
                    ],
                  ),
                  TableRow(
                    decoration: BoxDecoration(
                      color: !isTop ? Colors.green.shade50 : Colors.white,
                    ),
                    children: [
                      StatsDataCell(teamNameBottom, isBold: true),
                      ...List.generate(displayInnings, (i) {
                        int inn = i + 1;
                        bool isCurrent = (inning == inn && !isTop);
                        return InkWell(
                          onTap: () {
                            onJumpToInning(inn, false);
                          },
                          child: Container(
                            color: isCurrent
                                ? Colors.amber.shade200
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: Text(
                              '${scoresBottom.length > i ? scoresBottom[i] : 0}',
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                      StatsDataCell(
                        '$totalScoreBottom',
                        isBold: true,
                        textColor: Colors.green.shade900,
                      ),
                      StatsDataCell('$totalHitsBottom', isBold: true),
                      StatsDataCell('$errorsBottom'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(teamNameTop)),
                ButtonSegment(value: 1, label: Text(teamNameBottom)),
              ],
              selected: {teamIndex},
              onSelectionChanged: (set) => onTeamChanged(set.first),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeTeamName 打者成績',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '安打計: ${activeBatters.fold(0, (s, b) => s + b.stats.hits)}本',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(38),
                columnWidths: const {
                  0: FixedColumnWidth(28),
                  1: FixedColumnWidth(80),
                },
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.8,
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: (teamIndex == 0)
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF2E7D32),
                    ),
                    children: [
                      StatsHeaderCell('順'),
                      StatsHeaderCell('選手名'),
                      ...List.generate(
                        displayInnings,
                        (i) => StatsHeaderCell('${i + 1}回'),
                      ),
                      StatsHeaderCell('打席'),
                      StatsHeaderCell('打数'),
                      StatsHeaderCell('安打', isAccent: true),
                      StatsHeaderCell('２塁'),
                      StatsHeaderCell('３塁'),
                      StatsHeaderCell('本塁', isAccent: true),
                      StatsHeaderCell('打点', isAccent: true),
                      StatsHeaderCell('得点'),
                      StatsHeaderCell('盗塁', isAccent: true),
                      StatsHeaderCell('四球'),
                      StatsHeaderCell('死球'),
                      StatsHeaderCell('犠打'),
                      StatsHeaderCell('犠飛'),
                      StatsHeaderCell('三振'),
                      StatsHeaderCell('敵失'),
                      StatsHeaderCell('打率', isAccent: true),
                      StatsHeaderCell('失策', isAccent: true),
                    ],
                  ),
                  ...activeBatters.asMap().entries.map((entry) {
                    int bIdx = entry.key;
                    Player b = entry.value;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: (bIdx % 2 == 0)
                            ? Colors.white
                            : Colors.grey.shade50,
                      ),
                      children: [
                        StatsDataCell('${bIdx + 1}', isBold: true),
                        StatsDataCell(
                          '${b.name} (${b.position})',
                          isBold: true,
                        ),
                        ...List.generate(displayInnings, (innIdx) {
                          int currentInn = innIdx + 1;
                          final pas = b.stats.appearances
                              .where((p) => p.inning == currentInn)
                              .toList();
                          if (pas.isEmpty) {
                            return StatsDataCell('-');
                          }
                          bool hasHit = pas.any(
                            (p) => p.result != null && p.result!.isHit,
                          );
                          String text = pas
                              .map(
                                (p) =>
                                    '${p.displayShortLabel}${p.rbi > 0 ? " [${p.rbi}]" : ""}',
                              )
                              .join('\n');

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            color: hasHit
                                ? Colors.blue.shade50
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: hasHit
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: hasHit
                                    ? Colors.blue.shade900
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }),
                        StatsDataCell('${b.stats.pa}'),
                        StatsDataCell('${b.stats.ab}'),
                        StatsDataCell(
                          '${b.stats.hits}',
                          isBold: true,
                          textColor: Colors.blue.shade900,
                        ),
                        StatsDataCell('${b.stats.doubles}'),
                        StatsDataCell('${b.stats.triples}'),
                        StatsDataCell(
                          '${b.stats.hr}',
                          isBold: b.stats.hr > 0,
                          textColor: b.stats.hr > 0
                              ? Colors.purple.shade800
                              : null,
                        ),
                        StatsDataCell(
                          '${b.stats.rbi}',
                          isBold: b.stats.rbi > 0,
                          textColor: b.stats.rbi > 0
                              ? Colors.red.shade800
                              : null,
                        ),
                        StatsDataCell('${b.stats.runsScored}'),
                        StatsDataCell(
                          '${b.stats.sb}',
                          isBold: b.stats.sb > 0,
                          textColor: Colors.teal.shade800,
                        ),
                        StatsDataCell('${b.stats.bb}'),
                        StatsDataCell('${b.stats.hbp}'),
                        StatsDataCell('${b.stats.sh}'),
                        StatsDataCell('${b.stats.sf}'),
                        StatsDataCell('${b.stats.so}'),
                        StatsDataCell('${b.stats.roe}'),
                        StatsDataCell(
                          b.stats.battingAverage,
                          isBold: true,
                          textColor: Colors.green.shade900,
                        ),
                        StatsDataCell(
                          '${b.stats.errorsCommitted}',
                          textColor: b.stats.errorsCommitted > 0
                              ? Colors.red.shade800
                              : null,
                        ),
                      ],
                    );
                  }),
                  // チーム合計行
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFE8F5E9)),
                    children: [
                      StatsDataCell('計', isBold: true),
                      StatsDataCell('-', isBold: true),
                      ...List.generate(displayInnings, (innIdx) {
                        int currentInn = innIdx + 1;
                        int innRuns = isTop
                            ? (scoresTop.length >= currentInn
                                  ? scoresTop[currentInn - 1]
                                  : 0)
                            : (scoresBottom.length >= currentInn
                                  ? scoresBottom[currentInn - 1]
                                  : 0);
                        return StatsDataCell(
                          innRuns > 0 ? '$innRuns' : '-',
                          isBold: true,
                        );
                      }),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.pa)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.ab)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.hits)}',
                        isBold: true,
                        textColor: Colors.blue.shade900,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.doubles)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.triples)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.hr)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.rbi)}',
                        isBold: true,
                        textColor: Colors.red.shade800,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.runsScored)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.sb)}',
                        isBold: true,
                        textColor: Colors.teal.shade800,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.bb)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.hbp)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.sh)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.sf)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.so)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.roe)}',
                        isBold: true,
                      ),
                      StatsDataCell(
                        _teamBattingAverage(activeBatters),
                        isBold: true,
                        textColor: Colors.green.shade900,
                      ),
                      StatsDataCell(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.errorsCommitted)}',
                        isBold: true,
                        textColor: Colors.red.shade800,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeTeamName 投手成績',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '※$totalInningsConfig回制防御率換算',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(44),
                columnWidths: const {0: FixedColumnWidth(90)},
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.8,
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: (teamIndex == 0)
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF2E7D32),
                    ),
                    children: [
                      StatsHeaderCell('投手名'),
                      StatsHeaderCell('回数', isAccent: true),
                      StatsHeaderCell('打者'),
                      StatsHeaderCell('安打'),
                      StatsHeaderCell('本塁'),
                      StatsHeaderCell('三振', isAccent: true),
                      StatsHeaderCell('四球'),
                      StatsHeaderCell('死球'),
                      StatsHeaderCell('失点'),
                      StatsHeaderCell('自責', isAccent: true),
                      StatsHeaderCell('防御率', isAccent: true),
                    ],
                  ),
                  ...activePitchers
                      .where(
                        (p) =>
                            p.stats.pitchingEvents.isNotEmpty ||
                            p.position == '投',
                      )
                      .map((p) {
                        final pStats = p.stats.pitching;
                        return TableRow(
                          children: [
                            StatsDataCell(
                              '${p.name} (${p.position})',
                              isBold: true,
                            ),
                            StatsDataCell(
                              pStats.inningsPitched,
                              isBold: true,
                              textColor: Colors.blue.shade900,
                            ),
                            StatsDataCell('${pStats.battersFaced}'),
                            StatsDataCell('${pStats.hitsAllowed}'),
                            StatsDataCell('${pStats.hrAllowed}'),
                            StatsDataCell(
                              '${pStats.strikeouts}',
                              isBold: true,
                              textColor: Colors.green.shade900,
                            ),
                            StatsDataCell('${pStats.walks}'),
                            StatsDataCell('${pStats.hitByPitch}'),
                            StatsDataCell('${pStats.runsAllowed}'),
                            StatsDataCell(
                              '${pStats.earnedRuns}',
                              isBold: true,
                              textColor: pStats.earnedRuns > 0
                                  ? Colors.red.shade800
                                  : null,
                            ),
                            StatsDataCell(
                              pStats.era(regulationInnings: totalInningsConfig),
                              isBold: true,
                              textColor: Colors.brown.shade900,
                            ),
                          ],
                        );
                      }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          ...activeBatters.asMap().entries.map((entry) {
            int idx = entry.key;
            Player b = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          b.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${b.position})',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '打率 ${b.stats.battingAverage}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => showEditBatterDialog(
                            context,
                            notifier: notifier,
                            player: b,
                            index: idx,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            StatItem('打席', '${b.stats.pa}'),
                            StatItem('打数', '${b.stats.ab}'),
                            StatItem('安打', '${b.stats.hits}', isBold: true),
                            StatItem('2塁打', '${b.stats.doubles}'),
                            StatItem('3塁打', '${b.stats.triples}'),
                            StatItem('本塁打', '${b.stats.hr}', isBold: true),
                            StatItem(
                              '打点',
                              '${b.stats.rbi}',
                              textColor: Colors.red.shade800,
                            ),
                            StatItem('得点', '${b.stats.runsScored}'),
                            StatItem(
                              '盗塁',
                              '${b.stats.sb}',
                              isBold: b.stats.sb > 0,
                              textColor: Colors.teal.shade800,
                            ),
                            StatItem('四球', '${b.stats.bb}'),
                            StatItem('死球', '${b.stats.hbp}'),
                            StatItem('犠打', '${b.stats.sh}'),
                            StatItem('犠飛', '${b.stats.sf}'),
                            StatItem('三振', '${b.stats.so}'),
                            StatItem('敵失出塁', '${b.stats.roe}'),
                            StatItem(
                              '守備エラー',
                              '${b.stats.errorsCommitted}',
                              textColor: b.stats.errorsCommitted > 0
                                  ? Colors.red
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (b.stats.appearances.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: b.stats.appearances.asMap().entries.map((
                            pEntry,
                          ) {
                            final paIdx = pEntry.key;
                            final ResolvedEvent pa = pEntry.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ActionChip(
                                avatar: CircleAvatar(
                                  radius: 7,
                                  backgroundColor:
                                      pa.result != null && pa.result!.isHit
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade600,
                                  child: Text(
                                    '${paIdx + 1}',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                label: Text(
                                  '${pa.inning}回(${pa.displayShortLabel})${pa.rbi > 0 ? " [${pa.rbi}点]" : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        pa.result != null && pa.result!.isHit
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: pa.result != null && pa.result!.isHit
                                        ? Colors.blue.shade900
                                        : Colors.black87,
                                  ),
                                ),
                                backgroundColor:
                                    pa.result != null && pa.result!.isHit
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                onPressed: () {
                                  notifier.jumpToAtBat(
                                    pa.inning,
                                    pa.isTop,
                                    pa.cycleIndex,
                                    pa.batterIndex,
                                  );
                                  onShowBoardTab();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),

          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                notifier.addPlayer(teamIndex == 0);
              },
              icon: const Icon(Icons.add),
              label: Text('$activeTeamName の打順を追加'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// チーム全体の打率を算出する。
String _teamBattingAverage(List<Player> batters) {
  int totalAb = batters.fold(0, (s, b) => s + b.stats.ab);
  int totalHits = batters.fold(0, (s, b) => s + b.stats.hits);
  if (totalAb == 0) {
    return '.---';
  }
  double avg = totalHits / totalAb;
  if (avg >= 1.0) {
    return '1.000';
  }
  return avg.toStringAsFixed(3).substring(1);
}
