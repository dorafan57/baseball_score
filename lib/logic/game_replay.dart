import '../models/base_runners.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';
import '../models/player_stats.dart';
import '../models/resolved_event.dart';

/// イベント列を先頭から再生し、スコアと全選手の成績を導出する。
///
/// 副作用を持たない純粋関数で、引数の [events] も変更しない。
/// アプリの成績表示はすべてこの関数の戻り値から組み立てる。
///
/// [minInnings] はラインスコアに最低限確保するイニング数。実際に記録された
/// イニングがこれを超える場合は、そちらに合わせて拡張する。
GameState replayGame({
  required List<GameEvent> events,
  int minInnings = 7,
}) {
  final ordered = _ordered(events);

  var inningCount = minInnings < 1 ? 1 : minInnings;
  for (final event in ordered) {
    if (event.inning > inningCount) {
      inningCount = event.inning;
    }
  }

  final scoresTop = List<int>.filled(inningCount, 0);
  final scoresBottom = List<int>.filled(inningCount, 0);
  final statsByPlayerId = <String, PlayerStats>{};
  int errorsTop = 0;
  int errorsBottom = 0;

  PlayerStats statsFor(String playerId) =>
      statsByPlayerId.putIfAbsent(playerId, PlayerStats.empty);

  final resolved = <ResolvedEvent>[];

  // 半イニングごとの進行状況。イニングまたは表裏が変わったらリセットする。
  var simRunners = BaseRunners.empty;
  var simOuts = 0;
  var currentInning = -1;
  var currentIsTop = true;

  for (final event in ordered) {
    if (event.inning != currentInning || event.isTop != currentIsTop) {
      currentInning = event.inning;
      currentIsTop = event.isTop;
      simRunners = BaseRunners.empty;
      simOuts = 0;
    }

    // すでに3アウトに達した半イニングに残っているイベントは集計対象外にする。
    if (simOuts >= 3) {
      resolved.add(
        ResolvedEvent(
          event: event,
          runnersBefore: simRunners,
          outsBefore: simOuts,
          outsAfter: simOuts,
          causedInningEnd: true,
          isIgnored: true,
        ),
      );
      continue;
    }

    final runnersBefore = simRunners;
    final outsBefore = simOuts;

    simOuts += _estimateAddedOuts(event, runnersBefore);
    simRunners = event.runnersAfter;

    final current = ResolvedEvent(
      event: event,
      runnersBefore: runnersBefore,
      outsBefore: outsBefore,
      outsAfter: simOuts,
      causedInningEnd: simOuts >= 3,
    );
    resolved.add(current);

    // --- 集計 ---
    final inningIndex = event.inning - 1;
    if (event.isTop) {
      scoresTop[inningIndex] += event.runs;
    } else {
      scoresBottom[inningIndex] += event.runs;
    }

    for (final playerId in event.scoredPlayerIds) {
      statsFor(playerId).runsScored++;
    }

    final errorPlayerId = event.errorPlayerId;
    if (errorPlayerId != null) {
      statsFor(errorPlayerId).errorsCommitted++;
      // 表の攻撃中の失策は後攻（守備側）チームのもの。
      if (event.isTop) {
        errorsBottom++;
      } else {
        errorsTop++;
      }
    }

    final batterId = event.batterId;
    if (batterId != null && !event.isBaserunningEvent) {
      statsFor(batterId).appearances.add(current);
    }

    final runnerId = event.runnerId;
    if (runnerId != null && event.isBaserunningEvent) {
      statsFor(runnerId).baserunningEvents.add(current);
    }

    final pitcherId = event.pitcherId;
    if (pitcherId != null) {
      statsFor(pitcherId).pitchingEvents.add(current);
    }
  }

  return GameState(
    events: resolved,
    scoresTop: scoresTop,
    scoresBottom: scoresBottom,
    errorsTop: errorsTop,
    errorsBottom: errorsBottom,
    statsByPlayerId: statsByPlayerId,
  );
}

/// イベントを「回 → 表裏 → 記録順」に並べ替える。
///
/// 記録順（eventId 順）だけで並べると、あとから前のイニングに戻って
/// 追記した場合に同じ半イニングがリストの離れた位置に分断され、
/// 再生時に走者とアウトがリセットされてしまう。必ず半イニング単位で
/// まとまるよう並べ替えてから再生する。
List<GameEvent> _ordered(List<GameEvent> events) {
  final ordered = [...events];
  ordered.sort((a, b) {
    final byInning = a.inning.compareTo(b.inning);
    if (byInning != 0) {
      return byInning;
    }
    if (a.isTop != b.isTop) {
      // 表が先、裏があと。
      return a.isTop ? -1 : 1;
    }
    return a.eventId.compareTo(b.eventId);
  });
  return ordered;
}

/// このイベントで増えたアウト数を求める。
///
/// 「イベント前に塁上にいた人数（＋打者）」から「イベント後に塁上に残った人数
/// ＋生還した人数」を差し引いた残りがアウトになった人数、という考え方で逆算する。
/// そのうえで、三振やゴロのように必ずアウトが発生する結果については
/// [AtBatResult.guaranteedOuts] を下限として補正する。
int _estimateAddedOuts(GameEvent event, BaseRunners runnersBefore) {
  final before = runnersBefore.count + (event.isBaserunningEvent ? 0 : 1);
  final after = event.runnersAfter.count + event.runs;

  var added = before - after;
  if (added < 0) {
    added = 0;
  }

  final minimum = event.result?.guaranteedOuts ?? 0;
  return added < minimum ? minimum : added;
}
