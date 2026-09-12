/// 打席結果の種別。
///
/// - [isAtBat] : 打数にカウントするか（犠打・犠飛・四死球は打数に含めない）
/// - [isHit]   : 安打として記録するか
/// - [bases]   : 安打の塁打数（長打率の算出などに用いる）
enum AtBatResult {
  singleHit('単打', '安', true, true, 1),
  doubleHit('二塁打', '２', true, true, 2),
  tripleHit('三塁打', '３', true, true, 3),
  homeRun('本塁打', '本', true, true, 4),
  walk('四球', '四球', false, false, 0),
  hitByPitch('死球', '死球', false, false, 0),
  error('敵失', '失', true, false, 0),
  strikeout('三振', '三振', true, false, 0),
  strikeoutSafe('振逃出塁', '振逃', true, false, 0),
  groundOut('ゴロ', 'ゴ', true, false, 0),
  groundAdvance('ゴロ進塁', 'ゴ進', true, false, 0),
  flyOut('飛球', '飛', true, false, 0),
  foulFlyOut('邪飛', '邪飛', true, false, 0),
  flyAdvance('飛球進塁', '飛進', true, false, 0),
  sacrificeHit('犠打', '犠打', false, false, 0),
  sacrificeFly('犠飛', '犠飛', false, false, 0),
  doublePlay('併殺打', '併殺', true, false, 0);

  /// ダイアログなどに表示する正式名称。
  final String label;

  /// スコアブックのマス目に表示する省略表記。
  final String shortLabel;

  /// 打数にカウントするか。
  final bool isAtBat;

  /// 安打として記録するか。
  final bool isHit;

  /// 塁打数。
  final int bases;

  const AtBatResult(
    this.label,
    this.shortLabel,
    this.isAtBat,
    this.isHit,
    this.bases,
  );

  /// 三振（通常の三振・振り逃げの双方）かどうか。
  bool get isStrikeout =>
      this == AtBatResult.strikeout || this == AtBatResult.strikeoutSafe;

  /// 打球方向の入力が必要な結果かどうか。
  bool get needsDirection => const {
    AtBatResult.singleHit,
    AtBatResult.doubleHit,
    AtBatResult.tripleHit,
    AtBatResult.homeRun,
    AtBatResult.groundOut,
    AtBatResult.flyOut,
    AtBatResult.foulFlyOut,
  }.contains(this);

  /// この結果によって必ず発生するアウト数。
  ///
  /// 走者の増減からアウト数を逆算する際の下限値として用いる。
  int get guaranteedOuts {
    switch (this) {
      case AtBatResult.doublePlay:
        return 2;
      case AtBatResult.groundOut:
      case AtBatResult.flyOut:
      case AtBatResult.foulFlyOut:
      case AtBatResult.strikeout:
      case AtBatResult.sacrificeHit:
      case AtBatResult.sacrificeFly:
      case AtBatResult.groundAdvance:
      case AtBatResult.flyAdvance:
        return 1;
      default:
        return 0;
    }
  }
}
