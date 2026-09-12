import 'at_bat_result.dart';
import 'resolved_event.dart';

/// 打率・出塁率・長打率・OPS等の率を、打率表記に合わせて整形する。
///
/// `null`（分母0）は `.---`。1.000未満は先頭の`0`を落とす（`.350`）。
/// OPS等で1.000以上になる場合は`1.024`のようにそのまま表示する。
String _formatRate(double? value) {
  if (value == null) {
    return '.---';
  }
  if (value >= 1.0) {
    return value.toStringAsFixed(3);
  }
  return value.toStringAsFixed(3).substring(1);
}

/// 投手成績。
class PitcherStats {
  /// 奪ったアウト数（投球回の分子）。
  final int outsRecorded;

  /// 対戦打者数。
  final int battersFaced;
  final int hitsAllowed;
  final int hrAllowed;
  final int strikeouts;
  final int walks;
  final int hitByPitch;
  final int runsAllowed;
  final int earnedRuns;

  const PitcherStats({
    this.outsRecorded = 0,
    this.battersFaced = 0,
    this.hitsAllowed = 0,
    this.hrAllowed = 0,
    this.strikeouts = 0,
    this.walks = 0,
    this.hitByPitch = 0,
    this.runsAllowed = 0,
    this.earnedRuns = 0,
  });

  /// 「5 2/3」形式の投球回表記。
  String get inningsPitched {
    final full = outsRecorded ~/ 3;
    final rem = outsRecorded % 3;
    return rem == 0 ? '$full' : '$full $rem/3';
  }

  /// 防御率。
  ///
  /// [regulationInnings] は1試合あたりのイニング数。草野球では7回制が多いため
  /// 既定値を7としている。
  String era({int regulationInnings = 7}) {
    if (outsRecorded == 0) {
      return '.---';
    }
    final innings = outsRecorded / 3.0;
    return (earnedRuns * regulationInnings / innings).toStringAsFixed(2);
  }
}

/// 1選手分の集計済み成績。
///
/// `replayGame()` がイベント列を再生して生成する。UI からは読み取り専用として扱う。
class PlayerStats {
  /// この選手の打席イベント（走塁イベントは含まない）。
  final List<ResolvedEvent> appearances;

  /// この選手が走者として関与した走塁イベント（盗塁・走塁死など）。
  final List<ResolvedEvent> baserunningEvents;

  /// この選手が投手として登板中に発生したイベント。
  final List<ResolvedEvent> pitchingEvents;

  /// 得点（ホームインした回数）。
  int runsScored;

  /// 守備での失策数。
  int errorsCommitted;

  PlayerStats({
    List<ResolvedEvent>? appearances,
    List<ResolvedEvent>? baserunningEvents,
    List<ResolvedEvent>? pitchingEvents,
    this.runsScored = 0,
    this.errorsCommitted = 0,
  }) : appearances = appearances ?? [],
       baserunningEvents = baserunningEvents ?? [],
       pitchingEvents = pitchingEvents ?? [];

  /// 成績が一切ない状態。
  factory PlayerStats.empty() => PlayerStats();

  int _countWhere(bool Function(ResolvedEvent) test) =>
      appearances.where(test).length;

  /// 打席数。
  int get pa => _countWhere((e) => e.result != null);

  /// 打数。
  int get ab => _countWhere((e) => e.result?.isAtBat ?? false);

  /// 安打数。
  int get hits => _countWhere((e) => e.result?.isHit ?? false);

  int get doubles => _countWhere((e) => e.result == AtBatResult.doubleHit);
  int get triples => _countWhere((e) => e.result == AtBatResult.tripleHit);
  int get hr => _countWhere((e) => e.result == AtBatResult.homeRun);
  int get bb => _countWhere((e) => e.result == AtBatResult.walk);
  int get hbp => _countWhere((e) => e.result == AtBatResult.hitByPitch);
  int get sh => _countWhere((e) => e.result == AtBatResult.sacrificeHit);
  int get sf => _countWhere((e) => e.result == AtBatResult.sacrificeFly);

  /// 三振数（振り逃げを含む）。
  int get so => _countWhere((e) => e.result?.isStrikeout ?? false);

  /// 敵失による出塁数（振り逃げ出塁を含む）。
  int get roe => _countWhere(
    (e) =>
        e.result == AtBatResult.error || e.result == AtBatResult.strikeoutSafe,
  );

  /// 打点。
  int get rbi => appearances.fold(0, (sum, e) => sum + e.rbi);

  /// 盗塁数。
  int get sb => baserunningEvents.where((e) => e.isSteal).length;

  /// 塁打数（安打の `AtBatResult.bases` 合計）。
  int get totalBases =>
      appearances.fold(0, (sum, e) => sum + (e.result?.bases ?? 0));

  /// 得点圏（2塁または3塁に走者）での打席のうち、打数にあたるもの。
  List<ResolvedEvent> get _rispAtBats => appearances
      .where(
        (e) =>
            (e.result?.isAtBat ?? false) &&
            e.runnersBefore.hasRunnerInScoringPosition,
      )
      .toList();

  double? get _battingAverageValue => ab == 0 ? null : hits / ab;

  double? get _onBasePercentageValue {
    final denom = ab + bb + hbp + sf;
    return denom == 0 ? null : (hits + bb + hbp) / denom;
  }

  double? get _sluggingPercentageValue =>
      ab == 0 ? null : totalBases / ab;

  /// 打率。打数0のときは `.---` を返す。
  String get battingAverage => _formatRate(_battingAverageValue);

  /// 出塁率。(安打+四球+死球)/(打数+四球+死球+犠飛)。
  String get onBasePercentage => _formatRate(_onBasePercentageValue);

  /// 長打率。塁打数/打数。
  String get sluggingPercentage => _formatRate(_sluggingPercentageValue);

  /// OPS（出塁率+長打率）。
  String get ops {
    final obp = _onBasePercentageValue;
    final slg = _sluggingPercentageValue;
    if (obp == null || slg == null) {
      return '.---';
    }
    return _formatRate(obp + slg);
  }

  /// 得点圏打率。走者が2塁または3塁にいた打席のみを対象にした打率。
  String get rispBattingAverage {
    final atBats = _rispAtBats;
    if (atBats.isEmpty) {
      return '.---';
    }
    final hits = atBats.where((e) => e.result?.isHit ?? false).length;
    return _formatRate(hits / atBats.length);
  }

  /// 投手成績を集計して返す。
  PitcherStats get pitching {
    int outsRecorded = 0;
    int battersFaced = 0;
    int hitsAllowed = 0;
    int hrAllowed = 0;
    int strikeouts = 0;
    int walks = 0;
    int hitByPitch = 0;
    int runsAllowed = 0;
    int earnedRuns = 0;

    for (final e in pitchingEvents) {
      if (e.addedOuts > 0) {
        outsRecorded += e.addedOuts;
      }

      final result = e.result;
      if (result != null) {
        battersFaced++;
        if (result.isHit) {
          hitsAllowed++;
        }
        if (result == AtBatResult.homeRun) {
          hrAllowed++;
        }
        if (result.isStrikeout) {
          strikeouts++;
        }
        if (result == AtBatResult.walk) {
          walks++;
        }
        if (result == AtBatResult.hitByPitch) {
          hitByPitch++;
        }
      }
      runsAllowed += e.runs;
      earnedRuns += e.earnedRuns;
    }

    return PitcherStats(
      outsRecorded: outsRecorded,
      battersFaced: battersFaced,
      hitsAllowed: hitsAllowed,
      hrAllowed: hrAllowed,
      strikeouts: strikeouts,
      walks: walks,
      hitByPitch: hitByPitch,
      runsAllowed: runsAllowed,
      earnedRuns: earnedRuns,
    );
  }
}
