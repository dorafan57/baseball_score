import 'package:baseball_score/logic/advance_calculator.dart';
import 'package:baseball_score/models/at_bat_result.dart';
import 'package:baseball_score/models/base_runners.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const batter = 'batter';

  group('calculateDefaultAdvance', () {
    test('走者なしの単打で打者が1塁に出る', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.singleHit,
        runners: BaseRunners.empty,
        batterId: batter,
      );

      expect(advance.runners, const BaseRunners(runner1st: batter));
      expect(advance.runs, 0);
      expect(advance.rbi, 0);
      expect(advance.scoredPlayerIds, isEmpty);
    });

    test('1・3塁からの単打で3塁走者が生還し、打点がつく', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.singleHit,
        runners: const BaseRunners(runner1st: 'r1', runner3rd: 'r3'),
        batterId: batter,
      );

      expect(
        advance.runners,
        const BaseRunners(runner1st: batter, runner2nd: 'r1'),
      );
      expect(advance.runs, 1);
      expect(advance.rbi, 1);
      expect(advance.scoredPlayerIds, ['r3']);
    });

    test('二塁打では2・3塁走者が生還し、1塁走者は3塁へ進む', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.doubleHit,
        runners: const BaseRunners(
          runner1st: 'r1',
          runner2nd: 'r2',
          runner3rd: 'r3',
        ),
        batterId: batter,
      );

      expect(
        advance.runners,
        const BaseRunners(runner2nd: batter, runner3rd: 'r1'),
      );
      expect(advance.runs, 2);
      expect(advance.rbi, 2);
      expect(advance.scoredPlayerIds, ['r3', 'r2']);
    });

    test('満塁本塁打で4点が入る', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.homeRun,
        runners: const BaseRunners(
          runner1st: 'r1',
          runner2nd: 'r2',
          runner3rd: 'r3',
        ),
        batterId: batter,
      );

      expect(advance.runners, BaseRunners.empty);
      expect(advance.runs, 4);
      expect(advance.rbi, 4);
      expect(advance.scoredPlayerIds, ['r3', 'r2', 'r1', batter]);
    });

    test('満塁の四球は押し出しで1点', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.walk,
        runners: const BaseRunners(
          runner1st: 'r1',
          runner2nd: 'r2',
          runner3rd: 'r3',
        ),
        batterId: batter,
      );

      expect(
        advance.runners,
        const BaseRunners(runner1st: batter, runner2nd: 'r1', runner3rd: 'r2'),
      );
      expect(advance.runs, 1);
      expect(advance.rbi, 1);
      expect(advance.scoredPlayerIds, ['r3']);
    });

    test('1・3塁の四球では3塁走者は動かず、得点は入らない', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.walk,
        runners: const BaseRunners(runner1st: 'r1', runner3rd: 'r3'),
        batterId: batter,
      );

      expect(
        advance.runners,
        const BaseRunners(runner1st: batter, runner2nd: 'r1', runner3rd: 'r3'),
      );
      expect(advance.runs, 0);
    });

    test('2・3塁の四球では走者は動かない', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.walk,
        runners: const BaseRunners(runner2nd: 'r2', runner3rd: 'r3'),
        batterId: batter,
      );

      expect(
        advance.runners,
        const BaseRunners(runner1st: batter, runner2nd: 'r2', runner3rd: 'r3'),
      );
      expect(advance.runs, 0);
    });

    test('敵失による生還には打点がつかない', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.error,
        runners: const BaseRunners(runner3rd: 'r3'),
        batterId: batter,
      );

      expect(advance.runs, 1);
      expect(advance.rbi, 0);
      expect(advance.scoredPlayerIds, ['r3']);
    });

    test('併殺打では1塁走者が消え、他の走者は残る', () {
      final advance = calculateDefaultAdvance(
        result: AtBatResult.doublePlay,
        runners: const BaseRunners(runner1st: 'r1', runner3rd: 'r3'),
        batterId: batter,
      );

      expect(advance.runners, const BaseRunners(runner3rd: 'r3'));
      expect(advance.runs, 0);
      expect(advance.outsAdded, 2, reason: '併殺打は打者と1塁走者の2アウト');
    });

    test('凡退では走者は動かない', () {
      const runners = BaseRunners(runner1st: 'r1', runner2nd: 'r2');
      for (final result in [
        AtBatResult.strikeout,
        AtBatResult.groundOut,
        AtBatResult.flyOut,
        AtBatResult.foulFlyOut,
      ]) {
        final advance = calculateDefaultAdvance(
          result: result,
          runners: runners,
          batterId: batter,
        );
        expect(advance.runners, runners, reason: '$result で走者が動いた');
        expect(advance.runs, 0);
        expect(advance.outsAdded, 1, reason: '$result は打者の1アウト');
      }
    });

    test('安打・四死球・敵失ではアウトは増えない', () {
      for (final result in [
        AtBatResult.singleHit,
        AtBatResult.doubleHit,
        AtBatResult.tripleHit,
        AtBatResult.homeRun,
        AtBatResult.walk,
        AtBatResult.hitByPitch,
        AtBatResult.error,
      ]) {
        final advance = calculateDefaultAdvance(
          result: result,
          runners: BaseRunners.empty,
          batterId: batter,
        );
        expect(advance.outsAdded, 0, reason: '$result でアウトが増えた');
      }
    });
  });
}
