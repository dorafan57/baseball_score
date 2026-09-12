import 'package:flutter/material.dart';

/// スコアボード上部の「チーム名＋合計得点」表示。
///
/// [isAttacking] が true のチーム（攻撃中）は矢印と色で強調する。
class BoardTeam extends StatelessWidget {
  final String teamName;
  final int score;
  final bool isAttacking;

  const BoardTeam(this.teamName, this.score, this.isAttacking, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (isAttacking)
              const Icon(
                Icons.arrow_right,
                color: Colors.yellowAccent,
                size: 20,
              ),
            Text(
              teamName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$score',
          style: TextStyle(
            color: isAttacking ? Colors.amberAccent : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// アウトカウントのランプ1個分。
///
/// [outs] が [targetOut] 以上のときに点灯する。[onTap] を渡すとタップに反応する。
class OutLamp extends StatelessWidget {
  final int targetOut;
  final int outs;
  final VoidCallback? onTap;

  const OutLamp({
    super.key,
    required this.targetOut,
    required this.outs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFilled = outs >= targetOut;
    final lamp = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isFilled ? Colors.redAccent : Colors.grey.shade300,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
    if (onTap == null) {
      return lamp;
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: lamp,
    );
  }
}
