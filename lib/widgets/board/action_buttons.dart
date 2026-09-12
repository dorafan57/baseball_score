import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../providers/game_provider.dart';
import '../dialogs/direction_dialog.dart';
import '../dialogs/error_dialog.dart';
import '../dialogs/ground_out_dialog.dart';
import '../dialogs/sacrifice_fly_dialog.dart';
import '../dialogs/sacrifice_hit_dialog.dart';
import '../dialogs/strikeout_dialog.dart';

/// 打席結果ボタン群の小見出し（左端の色帯＋カテゴリ名）。
class CategoryHeader extends StatelessWidget {
  final String title;
  final Color color;

  const CategoryHeader(this.title, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: color),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 打席結果を入力するためのボタン1個分。
class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const ActionButton(this.label, this.color, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 1,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// 打席結果を入力するボタンをカテゴリごとにまとめたブロック。
class CategorizedActionButtons extends StatelessWidget {
  final GameSessionState session;
  final GameNotifier notifier;

  const CategorizedActionButtons({
    super.key,
    required this.session,
    required this.notifier,
  });

  /// 打球方向の選択を経由して打席結果を記録する。
  void _record(BuildContext context, AtBatResult result) {
    promptDirectionAndRecord(
      context,
      session: session,
      notifier: notifier,
      result: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryHeader('安打', Colors.green.shade800),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                '単打 (1H)',
                Colors.white,
                () => _record(context, AtBatResult.singleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ActionButton(
                '二塁打 (2B)',
                Colors.white,
                () => _record(context, AtBatResult.doubleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ActionButton(
                '三塁打 (3B)',
                Colors.white,
                () => _record(context, AtBatResult.tripleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ActionButton(
                '本塁打 (HR)',
                Colors.white,
                () => _record(context, AtBatResult.homeRun),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        CategoryHeader('四死球・出塁', Colors.teal.shade800),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                '四球 (BB)',
                Colors.white,
                () => _record(context, AtBatResult.walk),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ActionButton(
                '死球 (HBP)',
                Colors.white,
                () => _record(context, AtBatResult.hitByPitch),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ActionButton(
                '敵失 (エラー)',
                Colors.white,
                () => showErrorDialog(
                  context,
                  session: session,
                  notifier: notifier,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        CategoryHeader('犠打・犠飛・進塁', Colors.indigo.shade800),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                '犠打 (バント)',
                Colors.white,
                () => showSacrificeHitDialog(
                  context,
                  session: session,
                  notifier: notifier,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ActionButton(
                session.runners.runner3rd != null ? '犠飛 (犠牲フライ)' : 'フライ進塁',
                Colors.white,
                () => showSacrificeFlyDialog(
                  context,
                  session: session,
                  notifier: notifier,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        CategoryHeader('凡退・アウト', Colors.red.shade800),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                'ゴロ凡退',
                Colors.white,
                () => showGroundOutDialog(
                  context,
                  session: session,
                  notifier: notifier,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ActionButton(
                '飛球凡退',
                Colors.white,
                () => _record(context, AtBatResult.flyOut),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ActionButton(
                '邪飛',
                Colors.white,
                () => _record(context, AtBatResult.foulFlyOut),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ActionButton(
                '三振',
                Colors.white,
                () => showStrikeoutDialog(
                  context,
                  session: session,
                  notifier: notifier,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ActionButton(
                '併殺 (DP)',
                Colors.white,
                () => _record(context, AtBatResult.doublePlay),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
