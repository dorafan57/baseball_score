import 'package:flutter/foundation.dart';

import '../logic/game_replay.dart';
import 'game_event.dart';
import 'game_state.dart';
import 'player.dart';

/// 保存された試合1件分のスナップショット。
///
/// 保持するのはイベント列（試合の「事実」）と名簿・チーム名・進行状況のみ。
/// スコアや個人成績は保存せず、読込のたびに [replay] で再現する。
@immutable
class SavedGame {
  final String gameId;
  final DateTime savedAt;

  /// 試合が実際に行われた日付（保存日時とは別）。
  final DateTime gameDate;
  final String teamNameTop;
  final String teamNameBottom;
  final int totalInningsConfig;
  final int inning;
  final bool isTop;
  final int batterIndexTop;
  final int batterIndexBottom;
  final int cycleIndexTop;
  final int cycleIndexBottom;
  final String currentPitcherIdTop;
  final String currentPitcherIdBottom;
  final int nextEventId;
  final List<Player> playersTop;
  final List<Player> playersBottom;
  final List<GameEvent> gameEvents;

  const SavedGame({
    required this.gameId,
    required this.savedAt,
    required this.gameDate,
    required this.teamNameTop,
    required this.teamNameBottom,
    required this.totalInningsConfig,
    required this.inning,
    required this.isTop,
    required this.batterIndexTop,
    required this.batterIndexBottom,
    required this.cycleIndexTop,
    required this.cycleIndexBottom,
    required this.currentPitcherIdTop,
    required this.currentPitcherIdBottom,
    required this.nextEventId,
    required this.playersTop,
    required this.playersBottom,
    required this.gameEvents,
  });

  /// イベント列を再生した試合状況。ラインスコアや成績の表示に用いる。
  GameState replay() => replayGame(
    events: gameEvents,
    minInnings: totalInningsConfig > inning ? totalInningsConfig : inning,
  );

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'savedAt': savedAt.toIso8601String(),
    'gameDate': gameDate.toIso8601String(),
    'teamNameTop': teamNameTop,
    'teamNameBottom': teamNameBottom,
    'totalInningsConfig': totalInningsConfig,
    'inning': inning,
    'isTop': isTop,
    'batterIndexTop': batterIndexTop,
    'batterIndexBottom': batterIndexBottom,
    'cycleIndexTop': cycleIndexTop,
    'cycleIndexBottom': cycleIndexBottom,
    'currentPitcherIdTop': currentPitcherIdTop,
    'currentPitcherIdBottom': currentPitcherIdBottom,
    'nextEventId': nextEventId,
    'playersTop': playersTop.map((p) => p.toJson()).toList(),
    'playersBottom': playersBottom.map((p) => p.toJson()).toList(),
    'gameEvents': gameEvents.map((e) => e.toJson()).toList(),
  };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
    gameId: json['gameId'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
    // 開催日フィールド追加前に保存された試合には存在しないため、
    // その場合は保存日時の日付を代わりに使う。
    gameDate: json['gameDate'] != null
        ? DateTime.parse(json['gameDate'] as String)
        : DateTime.parse(json['savedAt'] as String),
    teamNameTop: json['teamNameTop'] as String,
    teamNameBottom: json['teamNameBottom'] as String,
    totalInningsConfig: json['totalInningsConfig'] as int,
    inning: json['inning'] as int,
    isTop: json['isTop'] as bool,
    batterIndexTop: json['batterIndexTop'] as int,
    batterIndexBottom: json['batterIndexBottom'] as int,
    cycleIndexTop: json['cycleIndexTop'] as int,
    cycleIndexBottom: json['cycleIndexBottom'] as int,
    currentPitcherIdTop: json['currentPitcherIdTop'] as String,
    currentPitcherIdBottom: json['currentPitcherIdBottom'] as String,
    nextEventId: json['nextEventId'] as int,
    playersTop: (json['playersTop'] as List<dynamic>)
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList(),
    playersBottom: (json['playersBottom'] as List<dynamic>)
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList(),
    gameEvents: (json['gameEvents'] as List<dynamic>)
        .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
