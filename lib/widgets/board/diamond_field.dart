import 'package:flutter/material.dart';

import '../../models/player.dart';

/// ダイヤモンド上に重ねて表示する守備位置ラベル。
class PosTag extends StatelessWidget {
  final String posLabel;
  final Player? player;

  const PosTag(this.posLabel, this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$posLabel:${player?.name ?? ""}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 各塁の走者表示。[runner] が null のときは空塁として描画する。
///
/// [onTap] を渡した場合のみタップに反応する。
class BaseNode extends StatelessWidget {
  final String baseName;
  final Player? runner;
  final VoidCallback? onTap;

  const BaseNode({
    super.key,
    required this.baseName,
    required this.runner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = runner != null;

    final node = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isOn ? Colors.amberAccent : const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            baseName,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isOn ? Colors.black87 : Colors.black45,
            ),
          ),
          if (isOn)
            Text(
              runner!.name,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return node;
    }
    return GestureDetector(onTap: onTap, child: node);
  }
}
