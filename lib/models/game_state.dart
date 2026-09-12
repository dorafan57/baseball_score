import 'package:flutter/foundation.dart';

import 'player_stats.dart';
import 'resolved_event.dart';

/// イベント列を再生して得られた試合状況のスナップショット。
///
/// `replayGame()` の戻り値。UI はこのオブジェクトだけを読めば
/// ラインスコアも個人成績も描画できる。
@immutable
class GameState {
  /// 正規化された順序（回 → 表裏 → 記録順）に並べ替え済みのイベント。
  final List<ResolvedEvent> events;

  /// 先攻チームのイニングごとの得点。
  final List<int> scoresTop;

  /// 後攻チームのイニングごとの得点。
  final List<int> scoresBottom;

  /// 先攻チームの失策数。
  final int errorsTop;

  /// 後攻チームの失策数。
  final int errorsBottom;

  /// 選手IDごとの成績。
  final Map<String, PlayerStats> statsByPlayerId;

  GameState({
    required List<ResolvedEvent> events,
    required List<int> scoresTop,
    required List<int> scoresBottom,
    required this.errorsTop,
    required this.errorsBottom,
    required this.statsByPlayerId,
  }) : events = List.unmodifiable(events),
       scoresTop = List.unmodifiable(scoresTop),
       scoresBottom = List.unmodifiable(scoresBottom);

  /// イベントが1件もない初期状態。
  factory GameState.initial({int innings = 7}) => GameState(
    events: const [],
    scoresTop: List<int>.filled(innings, 0),
    scoresBottom: List<int>.filled(innings, 0),
    errorsTop: 0,
    errorsBottom: 0,
    statsByPlayerId: const {},
  );

  int get totalScoreTop => scoresTop.fold(0, (a, b) => a + b);
  int get totalScoreBottom => scoresBottom.fold(0, (a, b) => a + b);

  /// ラインスコアのイニング数。
  int get inningCount => scoresTop.length;

  /// 指定選手の成績。記録がない場合は空の成績を返す。
  PlayerStats statsOf(String playerId) =>
      statsByPlayerId[playerId] ?? PlayerStats.empty();

  /// 指定した半イニングのイベントを記録順に返す。
  ///
  /// [includeIgnored] を false にすると、3アウト成立後に記録され
  /// 集計対象外となったイベントを除外する。
  List<ResolvedEvent> eventsInHalfInning(
    int inning,
    bool isTop, {
    bool includeIgnored = true,
  }) => events
      .where(
        (e) =>
            e.inning == inning &&
            e.isTop == isTop &&
            (includeIgnored || !e.isIgnored),
      )
      .toList();
}
