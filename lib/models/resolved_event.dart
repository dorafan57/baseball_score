import 'package:flutter/foundation.dart';

import 'at_bat_result.dart';
import 'base_runners.dart';
import 'game_event.dart';

/// [GameEvent] に、再生（リプレイ）によって導出した値を付与したもの。
///
/// アウトカウントやイベント直前の走者状況は、イベント単体では決まらず
/// 「その半イニングを先頭から再生した結果」として初めて確定する。
/// そのためこれらの値は [GameEvent] ではなくこちらが保持する。
@immutable
class ResolvedEvent {
  /// 元になった入力イベント。
  final GameEvent event;

  /// イベント **直前** の走者状況。
  final BaseRunners runnersBefore;

  /// イベント直前のアウトカウント。
  final int outsBefore;

  /// イベント直後のアウトカウント。
  final int outsAfter;

  /// このイベントでその半イニングが終了したか（3アウト到達）。
  final bool causedInningEnd;

  /// 3アウト成立後に記録された余剰イベントで、集計対象外になったか。
  final bool isIgnored;

  const ResolvedEvent({
    required this.event,
    required this.runnersBefore,
    required this.outsBefore,
    required this.outsAfter,
    required this.causedInningEnd,
    this.isIgnored = false,
  });

  /// このイベントで増えたアウト数。
  int get addedOuts => outsAfter - outsBefore;

  // --- 以下は event への委譲。呼び出し側の記述を簡潔にするためのもの ---

  int get eventId => event.eventId;
  int get inning => event.inning;
  bool get isTop => event.isTop;
  String get description => event.description;
  String? get batterId => event.batterId;
  int get batterIndex => event.batterIndex;
  String? get pitcherId => event.pitcherId;
  int get cycleIndex => event.cycleIndex;
  AtBatResult? get result => event.result;
  String get direction => event.direction;
  int get rbi => event.rbi;
  int get runs => event.runs;
  int get earnedRuns => event.earnedRuns;
  List<String> get scoredPlayerIds => event.scoredPlayerIds;
  String? get errorPlayerId => event.errorPlayerId;
  String? get runnerId => event.runnerId;
  BaseRunners get runnersAfter => event.runnersAfter;
  bool get isBaserunningEvent => event.isBaserunningEvent;
  bool get isSteal => event.isSteal;
  String get displayShortLabel => event.displayShortLabel;
}
