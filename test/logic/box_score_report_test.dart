import 'package:baseball_score/logic/box_score_report.dart';
import 'package:baseball_score/logic/game_replay.dart';
import 'package:baseball_score/models/at_bat_result.dart';
import 'package:baseball_score/models/base_runners.dart';
import 'package:baseball_score/models/game_event.dart';
import 'package:baseball_score/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

GameEvent atBat({
  required int eventId,
  required int inning,
  bool isTop = true,
  required AtBatResult result,
  required String batterId,
  String pitcherId = 'p1',
  int runs = 0,
  int rbi = 0,
  List<String>? scoredPlayerIds,
}) => GameEvent(
  eventId: eventId,
  inning: inning,
  isTop: isTop,
  description: '',
  batterId: batterId,
  pitcherId: pitcherId,
  result: result,
  runs: runs,
  rbi: rbi,
  earnedRuns: runs,
  scoredPlayerIds: scoredPlayerIds,
  runnersAfter: BaseRunners.empty,
  outsAdded: result.guaranteedOuts,
);

void main() {
  test('buildBoxScoreReport はラインスコアと両チームの成績をまとめる', () {
    final players1 = [Player(id: 'b1', name: '選手1', position: '投')];
    final players2 = [Player(id: 'x1', name: '選手A', position: '')];

    final state = replayGame(
      events: [
        atBat(
          eventId: 1,
          inning: 1,
          result: AtBatResult.homeRun,
          batterId: 'b1',
          runs: 1,
          rbi: 1,
          scoredPlayerIds: const ['b1'],
        ),
        atBat(
          eventId: 2,
          inning: 1,
          isTop: false,
          result: AtBatResult.strikeout,
          batterId: 'x1',
          pitcherId: 'b1',
        ),
      ],
      minInnings: 7,
    );
    for (final p in [...players1, ...players2]) {
      p.stats = state.statsOf(p.id);
    }

    final report = buildBoxScoreReport(
      teamNameTop: '先攻',
      teamNameBottom: '後攻',
      totalInningsConfig: 7,
      playersTop: players1,
      playersBottom: players2,
      scoresTop: state.scoresTop,
      scoresBottom: state.scoresBottom,
      totalScoreTop: state.totalScoreTop,
      totalScoreBottom: state.totalScoreBottom,
      totalHitsTop: players1.fold(0, (s, p) => s + p.stats.hits),
      totalHitsBottom: players2.fold(0, (s, p) => s + p.stats.hits),
      errorsTop: state.errorsTop,
      errorsBottom: state.errorsBottom,
    );

    expect(report.lineScore.totalScoreTop, 1);
    expect(report.top.teamName, '先攻');
    expect(report.top.batters, hasLength(1));
    expect(report.top.batters.single.hr, 1);
    expect(report.top.batters.single.ops, isNot('.---'));

    // b1 は投手として後攻の攻撃中に登板しているので投手成績にも現れる。
    expect(report.top.pitchers, hasLength(1));
    expect(report.top.pitchers.single.strikeouts, 1);

    expect(report.bottom.batters.single.so, 1);
  });
}
