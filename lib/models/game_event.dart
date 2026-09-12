import 'package:flutter/foundation.dart';

import 'at_bat_result.dart';
import 'base_runners.dart';

/// 試合中に発生した1つの出来事（打席結果、または走塁イベント）。
///
/// このクラスが保持するのは **入力された事実だけ** で、アウトカウントや
/// イベント直前の走者状況といった導出値は持たない。導出値は
/// `replayGame()` がイベント列を先頭から再生して算出し、`ResolvedEvent` に格納する。
///
/// 全フィールドを `final` にしているため、記録済みイベントを書き換える場合は
/// 新しいインスタンスを生成して差し替える。
@immutable
class GameEvent {
  /// イベントの一意な識別子。試合内で単調増加する。
  final int eventId;

  /// 何回に発生したか（1始まり）。
  final int inning;

  /// 表の攻撃中か（true = 表 = 先攻チームの攻撃）。
  final bool isTop;

  /// 履歴表示用の説明文。
  final String description;

  /// 打席に立っていた打者の選手ID。
  final String? batterId;

  /// 打順（0始まり）。
  final int batterIndex;

  /// 同一イニング内で打順が何巡目かを表すインデックス（0始まり）。
  final int cycleIndex;

  /// このとき投げていた投手の選手ID。
  final String? pitcherId;

  /// 打席結果。走塁イベントの場合は null。
  final AtBatResult? result;

  /// 打球方向（「左」「遊」など）。併殺の場合は経路（「遊→二→一」）。
  final String direction;

  /// このイベントで打者に記録される打点。
  final int rbi;

  /// このイベントで入った得点。
  final int runs;

  /// このイベントで投手に記録される自責点。
  final int earnedRuns;

  /// 生還した走者の選手IDの一覧。
  final List<String> scoredPlayerIds;

  /// 失策を記録された守備側選手の選手ID。
  final String? errorPlayerId;

  /// 走塁イベントの主体となる走者の選手ID（盗塁した走者など）。
  final String? runnerId;

  /// イベント **直後** の走者状況。
  final BaseRunners runnersAfter;

  /// 打席以外の走塁イベント（盗塁・WP・PB・走塁死など）かどうか。
  final bool isBaserunningEvent;

  /// 盗塁成功かどうか。
  final bool isSteal;

  /// このイベントで増えたアウト数。
  ///
  /// 走者の増減からの逆算ではなく、記録時点で確定している値を
  /// そのまま持たせる（何塁で誰がアウトになったかは UI 側が把握しているため）。
  final int outsAdded;

  GameEvent({
    required this.eventId,
    required this.inning,
    required this.isTop,
    required this.description,
    required this.runnersAfter,
    required this.outsAdded,
    this.batterId,
    this.batterIndex = 0,
    this.pitcherId,
    this.cycleIndex = 0,
    this.result,
    this.direction = '',
    this.rbi = 0,
    this.runs = 0,
    this.earnedRuns = 0,
    List<String>? scoredPlayerIds,
    this.errorPlayerId,
    this.runnerId,
    this.isBaserunningEvent = false,
    this.isSteal = false,
  }) : scoredPlayerIds = List.unmodifiable(scoredPlayerIds ?? const []);

  /// スコアブックのマス目に表示する省略表記。
  ///
  /// 打球方向を持つ結果は「遊ゴ」「左安」のように方向を前置する。
  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'inning': inning,
    'isTop': isTop,
    'description': description,
    'batterId': batterId,
    'batterIndex': batterIndex,
    'cycleIndex': cycleIndex,
    'pitcherId': pitcherId,
    'result': result?.name,
    'direction': direction,
    'rbi': rbi,
    'runs': runs,
    'earnedRuns': earnedRuns,
    'scoredPlayerIds': scoredPlayerIds,
    'errorPlayerId': errorPlayerId,
    'runnerId': runnerId,
    'runnersAfter': runnersAfter.toJson(),
    'isBaserunningEvent': isBaserunningEvent,
    'isSteal': isSteal,
    'outsAdded': outsAdded,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    eventId: json['eventId'] as int,
    inning: json['inning'] as int,
    isTop: json['isTop'] as bool,
    description: json['description'] as String,
    batterId: json['batterId'] as String?,
    batterIndex: json['batterIndex'] as int? ?? 0,
    cycleIndex: json['cycleIndex'] as int? ?? 0,
    pitcherId: json['pitcherId'] as String?,
    result: json['result'] != null
        ? AtBatResult.values.byName(json['result'] as String)
        : null,
    direction: json['direction'] as String? ?? '',
    rbi: json['rbi'] as int? ?? 0,
    runs: json['runs'] as int? ?? 0,
    earnedRuns: json['earnedRuns'] as int? ?? 0,
    scoredPlayerIds: (json['scoredPlayerIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    errorPlayerId: json['errorPlayerId'] as String?,
    runnerId: json['runnerId'] as String?,
    runnersAfter: BaseRunners.fromJson(
      json['runnersAfter'] as Map<String, dynamic>,
    ),
    isBaserunningEvent: json['isBaserunningEvent'] as bool? ?? false,
    isSteal: json['isSteal'] as bool? ?? false,
    outsAdded: json['outsAdded'] as int? ?? 0,
  );

  String get displayShortLabel {
    final r = result;
    if (r == null) {
      return description;
    }
    if (r == AtBatResult.doublePlay) {
      return direction == '併殺' || direction.isEmpty ? '併殺' : '$direction併殺';
    }
    if (r.needsDirection) {
      return '$direction${r.shortLabel}';
    }
    return r.shortLabel;
  }
}
