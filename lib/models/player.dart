import 'player_stats.dart';

/// 選手（名簿上の1人）。
///
/// このクラスが持つのは名簿情報（ID・氏名・守備位置）だけで、成績は持たない。
/// 成績はイベント列の再生結果として [stats] に差し込まれる。
class Player {
  /// 試合内で一意な選手ID。
  final String id;

  String name;

  /// 守備位置（「投」「捕」「遊」など）。
  String position;

  /// 直近の再生で算出された成績。`replayGame()` の結果を反映して更新される。
  PlayerStats stats;

  Player({
    required this.id,
    required this.name,
    required this.position,
    PlayerStats? stats,
  }) : stats = stats ?? PlayerStats.empty();

  /// 名簿情報のみを保存する（成績は replayGame() で再現するため含めない）。
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'position': position};

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    position: json['position'] as String,
  );
}

/// 守備位置が未入力の選手を表示する際のラベル。
extension PlayerDisplay on Player {
  String get positionLabel => position.isEmpty ? '－' : position;
}
