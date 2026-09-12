import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../providers/game_provider.dart';

/// 打者の氏名・守備位置を編集するダイアログを表示する。
///
/// 得点や失策はイベントの再生結果から自動集計されるため、ここでは編集しない。
void showEditBatterDialog(
  BuildContext context, {
  required GameNotifier notifier,
  required Player player,
  required int index,
}) {
  showDialog(
    context: context,
    builder: (ctx) =>
        _EditBatterDialog(notifier: notifier, player: player, index: index),
  );
}

/// [TextEditingController] の寿命をダイアログのウィジェットに合わせるため、
/// StatefulWidget として実装する。
///
/// `showDialog(...).whenComplete()` で dispose すると、保存時の再描画と
/// 閉じるアニメーションが競合して「破棄済みのコントローラを使った」という
/// エラーになることがあった。
class _EditBatterDialog extends StatefulWidget {
  final GameNotifier notifier;
  final Player player;
  final int index;

  const _EditBatterDialog({
    required this.notifier,
    required this.player,
    required this.index,
  });

  @override
  State<_EditBatterDialog> createState() => _EditBatterDialogState();
}

class _EditBatterDialogState extends State<_EditBatterDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _posCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.player.name);
    _posCtrl = TextEditingController(text: widget.player.position);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.index + 1}番打者の編集'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '選手名'),
          ),
          TextField(
            controller: _posCtrl,
            decoration: const InputDecoration(labelText: '守備位置'),
          ),
          const SizedBox(height: 12),
          const Text(
            '得点・失策は打席結果から自動で集計されます。',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.notifier.editPlayer(
              widget.player,
              name: _nameCtrl.text,
              position: _posCtrl.text,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
