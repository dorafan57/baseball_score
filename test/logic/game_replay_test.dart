import 'package:baseball_score/logic/game_replay.dart';
import 'package:baseball_score/models/at_bat_result.dart';
import 'package:baseball_score/models/base_runners.dart';
import 'package:baseball_score/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用に打席イベントを1件作る。
///
/// [outsAdded] を省略した場合は、結果ごとの必須アウト数
/// （[AtBatResult.guaranteedOuts]）をそのまま使う。
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
  int earnedRuns = 0,
  int? outsAdded,
  List<String>? scoredPlayerIds,
  String? errorPlayerId,
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
  earnedRuns: earnedRuns,
  outsAdded: outsAdded ?? result.guaranteedOuts,
  scoredPlayerIds: scoredPlayerIds,
  errorPlayerId: errorPlayerId,
);

/// テスト用に走塁イベントを1件作る。
GameEvent baserunning({
  required int eventId,
  required int inning,
  bool isTop = true,
  required BaseRunners runnersAfter,
  String? runnerId,
  bool isSteal = false,
  int runs = 0,
  int outsAdded = 0,
  List<String>? scoredPlayerIds,
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
  runs: runs,
  outsAdded: outsAdded,
  scoredPlayerIds: scoredPlayerIds,
);

void main() {
  group('replayGame — アウトカウント', () {
    test('凡退3つで3アウトになり、半イニングが終了する', () {
      final state = replayGame(
        events: [
          atBat(eventId: 1, inning: 1, result: AtBatResult.strikeout),
          atBat(eventId: 2, inning: 1, result: AtBatResult.groundOut),
          atBat(eventId: 3, inning: 1, result: AtBatResult.flyOut),
        ],
      );

      expect(state.events.map((e) => e.outsAfter), [1, 2, 3]);
      expect(state.events.last.causedInningEnd, isTrue);
    });

    test('併殺打は2アウトとして数える', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            result: AtBatResult.singleHit,
            runnersAfter: const BaseRunners(runner1st: 'b1'),
          ),
          atBat(eventId: 2, inning: 1, result: AtBatResult.doublePlay),
        ],
      );

      expect(state.events.last.addedOuts, 2);
      expect(state.events.last.outsAfter, 2);
    });

    test('3アウト成立後に記録されたイベントは集計対象外になる', () {
      final state = replayGame(
        events: [
          atBat(eventId: 1, inning: 1, result: AtBatResult.strikeout),
          atBat(eventId: 2, inning: 1, result: AtBatResult.strikeout),
          atBat(eventId: 3, inning: 1, result: AtBatResult.strikeout),
          atBat(
            eventId: 4,
            inning: 1,
            result: AtBatResult.homeRun,
            runs: 1,
            rbi: 1,
            scoredPlayerIds: ['b1'],
          ),
        ],
      );

      expect(state.events.last.isIgnored, isTrue);
      expect(state.scoresTop[0], 0, reason: '無効イベントの得点は加算されない');
      expect(state.statsOf('b1').hr, 0);
    });

    test('走塁死では走者が1人減りアウトが1つ増える', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            result: AtBatResult.singleHit,
            runnersAfter: const BaseRunners(runner1st: 'b1'),
          ),
          baserunning(
            eventId: 2,
            inning: 1,
            runnersAfter: BaseRunners.empty,
            runnerId: 'b1',
            outsAdded: 1,
          ),
        ],
      );

      expect(state.events.last.addedOuts, 1);
      expect(state.events.last.outsAfter, 1);
    });

    test('アウト数は走者数の増減からの逆算ではなく、明示的な指定値に従う', () {
      // 1塁走者がフォースアウトになり、打者が1塁に生きる「進塁打」のケース。
      // 走者の増減だけを見ると（1塁走者が消えて打者も塁に乗らないため）
      // 2アウト分の変化に見えてしまうが、実際のアウトは1つだけ。
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            result: AtBatResult.singleHit,
            runnersAfter: const BaseRunners(runner1st: 'b1'),
          ),
          atBat(
            eventId: 2,
            inning: 1,
            result: AtBatResult.groundAdvance,
            runnersAfter: BaseRunners.empty,
            outsAdded: 1,
          ),
        ],
      );

      expect(state.events.last.addedOuts, 1);
      expect(state.events.last.outsAfter, 1);
    });
  });

  group('replayGame — 得点と成績', () {
    test('イニングごとの得点が正しく集計される', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            result: AtBatResult.homeRun,
            runs: 1,
            rbi: 1,
            scoredPlayerIds: ['b1'],
          ),
          atBat(
            eventId: 2,
            inning: 3,
            isTop: false,
            result: AtBatResult.homeRun,
            batterId: 'x1',
            runs: 2,
            rbi: 2,
            scoredPlayerIds: ['x1', 'x2'],
          ),
        ],
      );

      expect(state.scoresTop[0], 1);
      expect(state.scoresBottom[2], 2);
      expect(state.totalScoreTop, 1);
      expect(state.totalScoreBottom, 2);
      expect(state.statsOf('b1').runsScored, 1);
      expect(state.statsOf('x2').runsScored, 1);
    });

    test('打率は打数と安打から算出され、犠打は打数に含まれない', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            result: AtBatResult.singleHit,
            runnersAfter: const BaseRunners(runner1st: 'b1'),
          ),
          atBat(eventId: 2, inning: 2, result: AtBatResult.strikeout),
          atBat(eventId: 3, inning: 3, result: AtBatResult.sacrificeHit),
        ],
      );

      final stats = state.statsOf('b1');
      expect(stats.pa, 3);
      expect(stats.ab, 2, reason: '犠打は打数に含めない');
      expect(stats.hits, 1);
      expect(stats.sh, 1);
      expect(stats.battingAverage, '.500');
    });

    test('失策は守備側チームに計上される', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            result: AtBatResult.error,
            runnersAfter: const BaseRunners(runner1st: 'b1'),
            errorPlayerId: 'd1',
          ),
        ],
      );

      // 表の攻撃中の失策なので、守備側である後攻チームの失策になる。
      expect(state.errorsBottom, 1);
      expect(state.errorsTop, 0);
      expect(state.statsOf('d1').errorsCommitted, 1);
    });

    test('盗塁は盗塁した走者に記録される', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
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
        ],
      );

      expect(state.statsOf('b1').sb, 1);
      expect(state.events.last.addedOuts, 0, reason: '盗塁成功でアウトは増えない');
    });

    test('投球回と防御率が投手に集計される', () {
      final state = replayGame(
        events: [
          atBat(eventId: 1, inning: 1, result: AtBatResult.strikeout),
          atBat(eventId: 2, inning: 1, result: AtBatResult.strikeout),
          atBat(eventId: 3, inning: 1, result: AtBatResult.groundOut),
          atBat(
            eventId: 4,
            inning: 2,
            result: AtBatResult.homeRun,
            runs: 1,
            rbi: 1,
            earnedRuns: 1,
            scoredPlayerIds: ['b1'],
          ),
        ],
      );

      final pitching = state.statsOf('p1').pitching;
      expect(pitching.outsRecorded, 3);
      expect(pitching.inningsPitched, '1');
      expect(pitching.strikeouts, 2);
      expect(pitching.hrAllowed, 1);
      expect(pitching.runsAllowed, 1);
      expect(pitching.earnedRuns, 1);
      // 7回制換算: 自責1 × 7 ÷ 1回 = 7.00
      expect(pitching.era(), '7.00');
    });

    test('盗塁など走塁イベントは対戦打者数に含めない', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
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
          atBat(eventId: 3, inning: 1, result: AtBatResult.strikeout),
        ],
      );

      final pitching = state.statsOf('p1').pitching;
      expect(pitching.battersFaced, 2, reason: '走塁イベントは対戦打者数に数えない');
    });
  });

  group('replayGame — イベントの並べ替え', () {
    test('前のイニングに戻って追記しても半イニングが分断されない', () {
      // 1回表 → 2回表と入力したあと、1回表に戻って2人目を追記した状況。
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            result: AtBatResult.singleHit,
            batterId: 'b1',
            runnersAfter: const BaseRunners(runner1st: 'b1'),
          ),
          atBat(
            eventId: 2,
            inning: 2,
            result: AtBatResult.strikeout,
            batterId: 'b3',
          ),
          atBat(
            eventId: 3,
            inning: 1,
            result: AtBatResult.strikeout,
            batterId: 'b2',
            // 三振では走者は動かないので、1塁走者はそのまま残る。
            runnersAfter: const BaseRunners(runner1st: 'b1'),
          ),
        ],
      );

      expect(
        state.events.map((e) => e.eventId),
        [1, 3, 2],
        reason: '回 → 表裏 → 記録順に並べ替えられる',
      );

      final secondAtBatOfFirstInning = state.events[1];
      expect(
        secondAtBatOfFirstInning.runnersBefore,
        const BaseRunners(runner1st: 'b1'),
        reason: '1回表の走者が引き継がれる',
      );
      expect(secondAtBatOfFirstInning.outsAfter, 1);
    });

    test('表の攻撃が裏より先に再生される', () {
      final state = replayGame(
        events: [
          atBat(
            eventId: 1,
            inning: 1,
            isTop: false,
            result: AtBatResult.strikeout,
          ),
          atBat(eventId: 2, inning: 1, result: AtBatResult.strikeout),
        ],
      );

      expect(state.events.map((e) => e.isTop), [true, false]);
    });

    test('半イニングをまたぐとアウトと走者がリセットされる', () {
      final state = replayGame(
        events: [
          atBat(eventId: 1, inning: 1, result: AtBatResult.strikeout),
          atBat(
            eventId: 2,
            inning: 1,
            isTop: false,
            result: AtBatResult.strikeout,
          ),
        ],
      );

      expect(state.events.last.outsBefore, 0);
      expect(state.events.last.runnersBefore, BaseRunners.empty);
    });
  });

  group('replayGame — ラインスコアのイニング数', () {
    test('既定では minInnings 分のイニングを確保する', () {
      final state = replayGame(events: const [], minInnings: 7);
      expect(state.inningCount, 7);
    });

    test('延長した場合は記録されたイニングまで拡張される', () {
      final state = replayGame(
        events: [atBat(eventId: 1, inning: 9, result: AtBatResult.strikeout)],
        minInnings: 7,
      );
      expect(state.inningCount, 9);
    });
  });

  test('replayGame は引数のイベント配列を変更しない', () {
    final events = [
      atBat(eventId: 2, inning: 2, result: AtBatResult.strikeout),
      atBat(eventId: 1, inning: 1, result: AtBatResult.strikeout),
    ];

    replayGame(events: events);

    expect(events.map((e) => e.eventId), [2, 1]);
  });
}
