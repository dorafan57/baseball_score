import 'package:baseball_score/logic/game_replay.dart';
import 'package:baseball_score/models/at_bat_result.dart';
import 'package:baseball_score/models/base_runners.dart';
import 'package:baseball_score/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用に打席イベントを1件作る。
GameEvent atBat({
  required int eventId,
  required int inning,
  bool isTop = true,
  required AtBatResult result,
  String batterId = 'b1',
  String pitcherId = 'p1',
  BaseRunners runnersAfter = BaseRunners.empty,
  int runs = 0,
  int rbi = 0,
  int? outsAdded,
  List<String>? scoredPlayerIds,
}) => GameEvent(
  eventId: eventId,
  inning: inning,
  isTop: isTop,
  description: '',
  batterId: batterId,
  pitcherId: pitcherId,
  result: result,
  runnersAfter: runnersAfter,
  runs: runs,
  rbi: rbi,
  earnedRuns: runs,
  outsAdded: outsAdded ?? result.guaranteedOuts,
  scoredPlayerIds: scoredPlayerIds,
);

/// テスト用に走塁イベントを1件作る。
GameEvent baserunning({
  required int eventId,
  required int inning,
  bool isTop = true,
  required BaseRunners runnersAfter,
  String? runnerId,
  bool isSteal = false,
}) => GameEvent(
  eventId: eventId,
  inning: inning,
  isTop: isTop,
  description: '走塁',
  pitcherId: 'p1',
  runnersAfter: runnersAfter,
  runnerId: runnerId,
  isSteal: isSteal,
  isBaserunningEvent: true,
  outsAdded: 0,
);

void main() {
  group('PlayerStats — 出塁率・長打率・OPS', () {
    test('犠飛を含む打席から出塁率・長打率・OPSを算出する', () {
      final state = replayGame(
        events: [
          atBat(eventId: 1, inning: 1, result: AtBatResult.singleHit),
          atBat(eventId: 2, inning: 1, result: AtBatResult.doubleHit),
          atBat(eventId: 3, inning: 1, result: AtBatResult.walk),
          atBat(eventId: 4, inning: 1, result: AtBatResult.sacrificeFly),
          atBat(eventId: 5, inning: 1, result: AtBatResult.strikeout),
        ],
      );

      final stats = state.statsOf('b1');
      expect(stats.ab, 3, reason: '単打・二塁打・三振のみ打数に含む');
      expect(stats.totalBases, 3);
      expect(stats.onBasePercentage, '.600');
      expect(stats.sluggingPercentage, '1.000');
      expect(stats.ops, '1.600', reason: 'OPSは1.000を超えてもそのまま表示する');
    });

    test('打数0のときは `.---` を返す', () {
      final state = replayGame(
        events: [atBat(eventId: 1, inning: 1, result: AtBatResult.walk)],
      );

      final stats = state.statsOf('b1');
      expect(stats.sluggingPercentage, '.---');
      expect(stats.ops, '.---');
    });
  });

  group('PlayerStats — 得点圏打率', () {
    test('2塁または3塁に走者がいる打席のみを対象に算出する', () {
      final state = replayGame(
        events: [
          // 1人目の打席（走者なし）: RISPの対象外。
          atBat(
            eventId: 1,
            inning: 1,
            batterId: 'b1',
            result: AtBatResult.walk,
            runnersAfter: const BaseRunners(runner1st: 'b1'),
          ),
          baserunning(
            eventId: 2,
            inning: 1,
            runnersAfter: const BaseRunners(runner2nd: 'b1'),
            runnerId: 'b1',
            isSteal: true,
          ),
          // 2人目の打席（2塁に走者）: RISP対象、安打。
          atBat(
            eventId: 3,
            inning: 1,
            batterId: 'b2',
            result: AtBatResult.singleHit,
            runnersAfter: const BaseRunners(runner1st: 'b2'),
            runs: 1,
            rbi: 1,
            scoredPlayerIds: ['b1'],
          ),
          // 2人目の打席（走者なし）: RISP対象外、凡退。
          atBat(
            eventId: 4,
            inning: 2,
            batterId: 'b2',
            result: AtBatResult.strikeout,
          ),
        ],
      );

      final stats = state.statsOf('b2');
      expect(stats.ab, 2);
      expect(stats.hits, 1);
      expect(stats.battingAverage, '.500');
      expect(
        stats.rispBattingAverage,
        '1.000',
        reason: '得点圏での打席は1打数1安打のみ',
      );
    });

    test('得点圏での打席がなければ `.---` を返す', () {
      final state = replayGame(
        events: [
          atBat(eventId: 1, inning: 1, result: AtBatResult.singleHit),
        ],
      );

      expect(state.statsOf('b1').rispBattingAverage, '.---');
    });
  });
}
