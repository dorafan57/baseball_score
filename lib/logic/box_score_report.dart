import '../models/player.dart';

/// ラインスコア（イニング毎得点・R/H/E）。
class BoxScoreLineScore {
  final List<int> scoresTop;
  final List<int> scoresBottom;
  final int totalScoreTop;
  final int totalScoreBottom;
  final int totalHitsTop;
  final int totalHitsBottom;
  final int errorsTop;
  final int errorsBottom;

  const BoxScoreLineScore({
    required this.scoresTop,
    required this.scoresBottom,
    required this.totalScoreTop,
    required this.totalScoreBottom,
    required this.totalHitsTop,
    required this.totalHitsBottom,
    required this.errorsTop,
    required this.errorsBottom,
  });
}

/// 1選手分の打者成績（ボックススコア用に整形済み）。
class BoxScoreBatterRow {
  final int order;
  final String name;
  final String position;
  final int pa;
  final int ab;
  final int hits;
  final int doubles;
  final int triples;
  final int hr;
  final int rbi;
  final int runs;
  final int sb;
  final int bb;
  final int hbp;
  final int sh;
  final int sf;
  final int so;
  final int roe;
  final int errorsCommitted;
  final String battingAverage;
  final String onBasePercentage;
  final String sluggingPercentage;
  final String ops;
  final String rispBattingAverage;

  const BoxScoreBatterRow({
    required this.order,
    required this.name,
    required this.position,
    required this.pa,
    required this.ab,
    required this.hits,
    required this.doubles,
    required this.triples,
    required this.hr,
    required this.rbi,
    required this.runs,
    required this.sb,
    required this.bb,
    required this.hbp,
    required this.sh,
    required this.sf,
    required this.so,
    required this.roe,
    required this.errorsCommitted,
    required this.battingAverage,
    required this.onBasePercentage,
    required this.sluggingPercentage,
    required this.ops,
    required this.rispBattingAverage,
  });
}

/// 1投手分の投手成績（ボックススコア用に整形済み）。
class BoxScorePitcherRow {
  final String name;
  final String position;
  final String inningsPitched;
  final int battersFaced;
  final int hitsAllowed;
  final int hrAllowed;
  final int strikeouts;
  final int walks;
  final int hitByPitch;
  final int runsAllowed;
  final int earnedRuns;
  final String era;

  const BoxScorePitcherRow({
    required this.name,
    required this.position,
    required this.inningsPitched,
    required this.battersFaced,
    required this.hitsAllowed,
    required this.hrAllowed,
    required this.strikeouts,
    required this.walks,
    required this.hitByPitch,
    required this.runsAllowed,
    required this.earnedRuns,
    required this.era,
  });
}

/// 1チーム分の打者・投手成績。
class BoxScoreTeamReport {
  final String teamName;
  final List<BoxScoreBatterRow> batters;
  final List<BoxScorePitcherRow> pitchers;

  const BoxScoreTeamReport({
    required this.teamName,
    required this.batters,
    required this.pitchers,
  });
}

/// ボックススコア（ラインスコア＋両チームの打者・投手成績）。
class BoxScoreReport {
  final int totalInningsConfig;
  final BoxScoreLineScore lineScore;
  final BoxScoreTeamReport top;
  final BoxScoreTeamReport bottom;

  const BoxScoreReport({
    required this.totalInningsConfig,
    required this.lineScore,
    required this.top,
    required this.bottom,
  });
}

/// 試合の進行状態からボックススコアを組み立てる（純粋関数）。
///
/// 表示・PDF・Excelの各エクスポート先で同じデータを使い回すための共通の
/// 変換ロジック。集計値そのものは `PlayerStats`/`PitcherStats` から
/// 直接読むだけで、新たな集計は行わない。
BoxScoreReport buildBoxScoreReport({
  required String teamNameTop,
  required String teamNameBottom,
  required int totalInningsConfig,
  required List<Player> playersTop,
  required List<Player> playersBottom,
  required List<int> scoresTop,
  required List<int> scoresBottom,
  required int totalScoreTop,
  required int totalScoreBottom,
  required int totalHitsTop,
  required int totalHitsBottom,
  required int errorsTop,
  required int errorsBottom,
}) {
  final lineScore = BoxScoreLineScore(
    scoresTop: scoresTop,
    scoresBottom: scoresBottom,
    totalScoreTop: totalScoreTop,
    totalScoreBottom: totalScoreBottom,
    totalHitsTop: totalHitsTop,
    totalHitsBottom: totalHitsBottom,
    errorsTop: errorsTop,
    errorsBottom: errorsBottom,
  );

  return BoxScoreReport(
    totalInningsConfig: totalInningsConfig,
    lineScore: lineScore,
    top: _buildTeamReport(teamNameTop, playersTop,
        regulationInnings: totalInningsConfig),
    bottom: _buildTeamReport(teamNameBottom, playersBottom,
        regulationInnings: totalInningsConfig),
  );
}

BoxScoreTeamReport _buildTeamReport(
  String teamName,
  List<Player> players, {
  required int regulationInnings,
}) {
  final batters = players.asMap().entries.map((entry) {
    final stats = entry.value.stats;
    return BoxScoreBatterRow(
      order: entry.key + 1,
      name: entry.value.name,
      position: entry.value.positionLabel,
      pa: stats.pa,
      ab: stats.ab,
      hits: stats.hits,
      doubles: stats.doubles,
      triples: stats.triples,
      hr: stats.hr,
      rbi: stats.rbi,
      runs: stats.runsScored,
      sb: stats.sb,
      bb: stats.bb,
      hbp: stats.hbp,
      sh: stats.sh,
      sf: stats.sf,
      so: stats.so,
      roe: stats.roe,
      errorsCommitted: stats.errorsCommitted,
      battingAverage: stats.battingAverage,
      onBasePercentage: stats.onBasePercentage,
      sluggingPercentage: stats.sluggingPercentage,
      ops: stats.ops,
      rispBattingAverage: stats.rispBattingAverage,
    );
  }).toList();

  final pitchers = players
      .where((p) => p.stats.pitchingEvents.isNotEmpty || p.position == '投')
      .map((p) {
        final pStats = p.stats.pitching;
        return BoxScorePitcherRow(
          name: p.name,
          position: p.positionLabel,
          inningsPitched: pStats.inningsPitched,
          battersFaced: pStats.battersFaced,
          hitsAllowed: pStats.hitsAllowed,
          hrAllowed: pStats.hrAllowed,
          strikeouts: pStats.strikeouts,
          walks: pStats.walks,
          hitByPitch: pStats.hitByPitch,
          runsAllowed: pStats.runsAllowed,
          earnedRuns: pStats.earnedRuns,
          era: pStats.era(regulationInnings: regulationInnings),
        );
      })
      .toList();

  return BoxScoreTeamReport(
    teamName: teamName,
    batters: batters,
    pitchers: pitchers,
  );
}
