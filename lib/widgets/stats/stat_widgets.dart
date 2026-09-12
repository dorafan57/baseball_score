import 'package:flutter/material.dart';

/// 成績テーブルの見出しセル。
class StatsHeaderCell extends StatelessWidget {
  final String text;

  const StatsHeaderCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// 成績テーブルのデータセル。
class StatsDataCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const StatsDataCell(this.text, {super.key, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// 横スクロール可能な表をCard＋Scrollbarで囲む。
///
/// `Scrollbar` は明示的な `ScrollController` を渡さないと
/// `PrimaryScrollController` へ接続しようとするが、デスクトップ/Web環境では
/// `ScrollView.primary` の既定値がモバイル限定のため何も接続されず
/// 例外になる。専用の `ScrollController` を作って確実に接続する。
class HorizontalScrollTable extends StatefulWidget {
  final Widget table;

  const HorizontalScrollTable({super.key, required this.table});

  @override
  State<HorizontalScrollTable> createState() => _HorizontalScrollTableState();
}

class _HorizontalScrollTableState extends State<HorizontalScrollTable> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          child: widget.table,
        ),
      ),
    );
  }
}

/// 選手カード内に横並びで表示する「項目名＋値」1組。
class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const StatItem(this.label, this.value, {super.key, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
