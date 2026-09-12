import 'package:flutter/material.dart';

import '../../logic/box_score_report.dart';
import 'stat_widgets.dart';

/// ボックススコア（ラインスコア＋両チームの打者・投手成績）を1画面にまとめて
/// 表示するウィジェット。画面表示・PDF/Excelエクスポートのプレビューを兼ねる。
class BoxScoreView extends StatelessWidget {
  final BoxScoreReport report;

  const BoxScoreView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ラインスコア',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _lineScoreTable(),
          const SizedBox(height: 18),
          _teamSection(report.top),
          const SizedBox(height: 18),
          _teamSection(report.bottom),
        ],
      ),
    );
  }

  Widget _lineScoreTable() {
    final innings = report.lineScore.scoresTop.length;
    return _bordered(
      Table(
        defaultColumnWidth: const FixedColumnWidth(32),
        columnWidths: const {0: FixedColumnWidth(110)},
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFF0D2E14)),
            children: [
              const StatsHeaderCell('チーム'),
              ...List.generate(innings, (i) => StatsHeaderCell('${i + 1}')),
              const StatsHeaderCell('R'),
              const StatsHeaderCell('H'),
              const StatsHeaderCell('E'),
            ],
          ),
          _lineScoreRow(
            report.top.teamName,
            report.lineScore.scoresTop,
            report.lineScore.totalScoreTop,
            report.lineScore.totalHitsTop,
            report.lineScore.errorsTop,
          ),
          _lineScoreRow(
            report.bottom.teamName,
            report.lineScore.scoresBottom,
            report.lineScore.totalScoreBottom,
            report.lineScore.totalHitsBottom,
            report.lineScore.errorsBottom,
          ),
        ],
      ),
    );
  }

  TableRow _lineScoreRow(
    String teamName,
    List<int> scores,
    int totalScore,
    int totalHits,
    int errors,
  ) => TableRow(
    children: [
      StatsDataCell(teamName, isBold: true),
      ...scores.map((s) => StatsDataCell('$s')),
      StatsDataCell('$totalScore', isBold: true),
      StatsDataCell('$totalHits', isBold: true),
      StatsDataCell('$errors'),
    ],
  );

  Widget _teamSection(BoxScoreTeamReport team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${team.teamName} 打者成績',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        _batterTable(team),
        const SizedBox(height: 10),
        Text(
          '${team.teamName} 投手成績',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        _pitcherTable(team),
      ],
    );
  }

  Widget _batterTable(BoxScoreTeamReport team) {
    return _bordered(
      Table(
        defaultColumnWidth: const FixedColumnWidth(40),
        columnWidths: const {0: FixedColumnWidth(28), 1: FixedColumnWidth(80)},
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFF1B5E20)),
            children: [
              StatsHeaderCell('順'),
              StatsHeaderCell('選手名'),
              StatsHeaderCell('打席'),
              StatsHeaderCell('打数'),
              StatsHeaderCell('安打'),
              StatsHeaderCell('本塁'),
              StatsHeaderCell('打点'),
              StatsHeaderCell('得点'),
              StatsHeaderCell('盗塁'),
              StatsHeaderCell('打率'),
              StatsHeaderCell('出塁率'),
              StatsHeaderCell('長打率'),
              StatsHeaderCell('OPS'),
              StatsHeaderCell('得点圏'),
            ],
          ),
          ...team.batters.map(
            (b) => TableRow(
              children: [
                StatsDataCell('${b.order}', isBold: true),
                StatsDataCell('${b.name}(${b.position})', isBold: true),
                StatsDataCell('${b.pa}'),
                StatsDataCell('${b.ab}'),
                StatsDataCell('${b.hits}', isBold: true),
                StatsDataCell('${b.hr}', isBold: b.hr > 0),
                StatsDataCell('${b.rbi}', isBold: b.rbi > 0),
                StatsDataCell('${b.runs}', isBold: b.runs > 0),
                StatsDataCell('${b.sb}', isBold: b.sb > 0),
                StatsDataCell(b.battingAverage, isBold: true),
                StatsDataCell(b.onBasePercentage),
                StatsDataCell(b.sluggingPercentage),
                StatsDataCell(b.ops, isBold: true),
                StatsDataCell(b.rispBattingAverage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pitcherTable(BoxScoreTeamReport team) {
    return _bordered(
      Table(
        defaultColumnWidth: const FixedColumnWidth(44),
        columnWidths: const {0: FixedColumnWidth(90)},
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFF1B5E20)),
            children: [
              StatsHeaderCell('投手名'),
              StatsHeaderCell('回数'),
              StatsHeaderCell('打者'),
              StatsHeaderCell('安打'),
              StatsHeaderCell('本塁'),
              StatsHeaderCell('三振'),
              StatsHeaderCell('四球'),
              StatsHeaderCell('失点'),
              StatsHeaderCell('自責'),
              StatsHeaderCell('防御率'),
            ],
          ),
          ...team.pitchers.map(
            (p) => TableRow(
              children: [
                StatsDataCell('${p.name}(${p.position})', isBold: true),
                StatsDataCell(p.inningsPitched, isBold: true),
                StatsDataCell('${p.battersFaced}'),
                StatsDataCell('${p.hitsAllowed}'),
                StatsDataCell('${p.hrAllowed}'),
                StatsDataCell('${p.strikeouts}'),
                StatsDataCell('${p.walks}'),
                StatsDataCell('${p.runsAllowed}'),
                StatsDataCell('${p.earnedRuns}', isBold: true),
                StatsDataCell(p.era, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bordered(Widget table) => HorizontalScrollTable(table: table);
}
