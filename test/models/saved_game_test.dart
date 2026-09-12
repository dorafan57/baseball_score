import 'package:baseball_score/models/at_bat_result.dart';
import 'package:baseball_score/models/base_runners.dart';
import 'package:baseball_score/models/game_event.dart';
import 'package:baseball_score/models/player.dart';
import 'package:baseball_score/models/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseRunners の JSON 変換', () {
    test('走者ありの状態を変換しても値が保たれる', () {
      const runners = BaseRunners(runner1st: 'p1', runner3rd: 'p3');
      final restored = BaseRunners.fromJson(runners.toJson());
      expect(restored, runners);
    });

    test('空塁の状態も変換できる', () {
      final restored = BaseRunners.fromJson(BaseRunners.empty.toJson());
      expect(restored, BaseRunners.empty);
    });
  });

  group('Player の JSON 変換', () {
    test('名簿情報（成績を除く）が保たれる', () {
      final player = Player(id: 'p1', name: '佐藤', position: '遊');
      final restored = Player.fromJson(player.toJson());
      expect(restored.id, 'p1');
      expect(restored.name, '佐藤');
      expect(restored.position, '遊');
    });
  });

  group('GameEvent の JSON 変換', () {
    test('打席結果イベントの全フィールドが保たれる', () {
      final event = GameEvent(
        eventId: 3,
        inning: 2,
        isTop: false,
        description: '4番 田中: 中安',
        batterId: 'b4',
        batterIndex: 3,
        cycleIndex: 0,
        pitcherId: 't9',
        result: AtBatResult.singleHit,
        direction: '中',
        rbi: 1,
        runs: 1,
        earnedRuns: 1,
        scoredPlayerIds: const ['b1'],
        errorPlayerId: null,
        runnerId: null,
        runnersAfter: const BaseRunners(runner1st: 'b4'),
        outsAdded: 0,
      );

      final restored = GameEvent.fromJson(event.toJson());

      expect(restored.eventId, event.eventId);
      expect(restored.inning, event.inning);
      expect(restored.isTop, event.isTop);
      expect(restored.batterId, event.batterId);
      expect(restored.result, event.result);
      expect(restored.direction, event.direction);
      expect(restored.rbi, event.rbi);
      expect(restored.runs, event.runs);
      expect(restored.earnedRuns, event.earnedRuns);
      expect(restored.scoredPlayerIds, event.scoredPlayerIds);
      expect(restored.runnersAfter, event.runnersAfter);
      expect(restored.outsAdded, event.outsAdded);
    });

    test('走塁イベント（result が null）も変換できる', () {
      final event = GameEvent(
        eventId: 5,
        inning: 1,
        isTop: true,
        description: '盗塁成功',
        runnerId: 't1',
        runnersAfter: const BaseRunners(runner2nd: 't1'),
        outsAdded: 0,
        isBaserunningEvent: true,
        isSteal: true,
      );

      final restored = GameEvent.fromJson(event.toJson());

      expect(restored.result, isNull);
      expect(restored.isBaserunningEvent, isTrue);
      expect(restored.isSteal, isTrue);
      expect(restored.runnerId, 't1');
      expect(restored.runnersAfter, event.runnersAfter);
    });
  });

  group('SavedGame の JSON 変換', () {
    test('イベント列・名簿・進行状況を復元でき、replay() で成績を再現できる', () {
      final playersTop = [Player(id: 't1', name: '佐藤', position: '投')];
      final playersBottom = [Player(id: 'b1', name: '鈴木', position: '投')];
      final events = [
        GameEvent(
          eventId: 1,
          inning: 1,
          isTop: true,
          description: '1番 佐藤: 中安',
          batterId: 't1',
          batterIndex: 0,
          pitcherId: 'b1',
          result: AtBatResult.singleHit,
          direction: '中',
          runnersAfter: const BaseRunners(runner1st: 't1'),
          outsAdded: 0,
        ),
      ];
      final saved = SavedGame(
        gameId: 'game-1',
        savedAt: DateTime.utc(2026, 9, 13, 10, 30),
        gameDate: DateTime.utc(2026, 9, 12),
        teamNameTop: '自チーム',
        teamNameBottom: '相手チーム',
        totalInningsConfig: 7,
        inning: 1,
        isTop: true,
        batterIndexTop: 1,
        batterIndexBottom: 0,
        cycleIndexTop: 0,
        cycleIndexBottom: 0,
        currentPitcherIdTop: 't1',
        currentPitcherIdBottom: 'b1',
        nextEventId: 2,
        playersTop: playersTop,
        playersBottom: playersBottom,
        gameEvents: events,
      );

      final restored = SavedGame.fromJson(saved.toJson());

      expect(restored.gameId, saved.gameId);
      expect(restored.savedAt, saved.savedAt);
      expect(restored.gameDate, saved.gameDate);
      expect(restored.teamNameTop, saved.teamNameTop);
      expect(restored.teamNameBottom, saved.teamNameBottom);
      expect(restored.nextEventId, saved.nextEventId);
      expect(restored.playersTop.single.id, 't1');
      expect(restored.playersBottom.single.id, 'b1');
      expect(restored.gameEvents.single.batterId, 't1');

      final replay = restored.replay();
      expect(replay.statsOf('t1').hits, 1);
    });

    test('gameDate フィールドが無い旧データは savedAt を代わりに使う', () {
      final json = {
        'gameId': 'game-1',
        'savedAt': DateTime.utc(2026, 9, 13, 10, 30).toIso8601String(),
        'teamNameTop': '自チーム',
        'teamNameBottom': '相手チーム',
        'totalInningsConfig': 7,
        'inning': 1,
        'isTop': true,
        'batterIndexTop': 0,
        'batterIndexBottom': 0,
        'cycleIndexTop': 0,
        'cycleIndexBottom': 0,
        'currentPitcherIdTop': 't1',
        'currentPitcherIdBottom': 'b1',
        'nextEventId': 1,
        'playersTop': <Map<String, dynamic>>[],
        'playersBottom': <Map<String, dynamic>>[],
        'gameEvents': <Map<String, dynamic>>[],
      };

      final restored = SavedGame.fromJson(json);

      expect(restored.gameDate, DateTime.utc(2026, 9, 13, 10, 30));
    });
  });
}
