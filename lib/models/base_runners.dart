import 'package:flutter/foundation.dart';

/// 各塁の走者を選手IDで保持する不変オブジェクト。
///
/// `null` は空塁を表す。イベントに保存した走者状況が後から書き換わらないよう、
/// 意図的に不変（immutable）にしている。状況を変えるときは新しいインスタンスを生成する。
@immutable
class BaseRunners {
  final String? runner1st;
  final String? runner2nd;
  final String? runner3rd;

  const BaseRunners({this.runner1st, this.runner2nd, this.runner3rd});

  /// 走者なしの状態。
  static const BaseRunners empty = BaseRunners();

  bool get isEmpty =>
      runner1st == null && runner2nd == null && runner3rd == null;

  bool get isNotEmpty => !isEmpty;

  /// 塁上の走者数（0〜3）。
  int get count =>
      (runner1st != null ? 1 : 0) +
      (runner2nd != null ? 1 : 0) +
      (runner3rd != null ? 1 : 0);

  /// 指定した走者を塁上から取り除いた状態を返す。
  ///
  /// 走塁死・牽制死など、特定の走者だけが消える場面で用いる。
  BaseRunners without(String runnerId) => BaseRunners(
    runner1st: runner1st == runnerId ? null : runner1st,
    runner2nd: runner2nd == runnerId ? null : runner2nd,
    runner3rd: runner3rd == runnerId ? null : runner3rd,
  );

  @override
  bool operator ==(Object other) =>
      other is BaseRunners &&
      other.runner1st == runner1st &&
      other.runner2nd == runner2nd &&
      other.runner3rd == runner3rd;

  @override
  int get hashCode => Object.hash(runner1st, runner2nd, runner3rd);

  @override
  String toString() =>
      'BaseRunners(1st: $runner1st, 2nd: $runner2nd, 3rd: $runner3rd)';
}
