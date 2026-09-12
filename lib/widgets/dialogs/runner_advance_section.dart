import 'package:flutter/material.dart';

import '../../models/base_runners.dart';
import '../../models/player.dart';

/// 走者1人分の進塁先を選ぶ行（見出し＋ SegmentedButton）。
class RunnerChoiceTile extends StatelessWidget {
  final String title;
  final List<String> options;
  final ValueChanged<int> onSelected;
  final int currentIndex;

  const RunnerChoiceTile(
    this.title,
    this.options,
    this.onSelected,
    this.currentIndex, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SegmentedButton<int>(
            segments: options
                .asMap()
                .entries
                .map(
                  (e) => ButtonSegment(
                    value: e.key,
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
            selected: {currentIndex},
            onSelectionChanged: (selectedSet) {
              onSelected(selectedSet.first);
            },
          ),
        ],
      ),
    );
  }
}

/// 走者の進塁先を選ぶダイアログ群に共通する「塁ごとの選択肢セクション」。
///
/// 3塁→2塁→1塁の順に、走者がいる塁だけ [RunnerChoiceTile] を並べる。
/// 選択肢の文言・選択中インデックスの導出・確定時の得点／アウト計算は
/// ダイアログごとに異なるため、すべて呼び出し側が受け持つ。
/// ここで共通化するのは並べ方と見出しの組み立てだけ。
class RunnerAdvanceSection extends StatelessWidget {
  final BaseRunners runners;

  /// 走者IDから選手を引くための関数（名前の表示に使う）。
  final Player? Function(String? id) findPlayer;

  final List<String> options3rd;
  final int selected3rd;
  final ValueChanged<int> onSelected3rd;

  final List<String> options2nd;
  final int selected2nd;
  final ValueChanged<int> onSelected2nd;

  final List<String> options1st;
  final int selected1st;
  final ValueChanged<int> onSelected1st;

  const RunnerAdvanceSection({
    super.key,
    required this.runners,
    required this.findPlayer,
    required this.options3rd,
    required this.selected3rd,
    required this.onSelected3rd,
    required this.options2nd,
    required this.selected2nd,
    required this.onSelected2nd,
    required this.options1st,
    required this.selected1st,
    required this.onSelected1st,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (runners.runner3rd != null)
          RunnerChoiceTile(
            '3塁: ${findPlayer(runners.runner3rd)?.name}',
            options3rd,
            onSelected3rd,
            selected3rd,
          ),
        if (runners.runner2nd != null)
          RunnerChoiceTile(
            '2塁: ${findPlayer(runners.runner2nd)?.name}',
            options2nd,
            onSelected2nd,
            selected2nd,
          ),
        if (runners.runner1st != null)
          RunnerChoiceTile(
            '1塁: ${findPlayer(runners.runner1st)?.name}',
            options1st,
            onSelected1st,
            selected1st,
          ),
      ],
    );
  }
}
