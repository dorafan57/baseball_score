import 'package:flutter/material.dart';

import '../../providers/game_provider.dart';
import 'reset_confirm_dialog.dart';

/// チーム名の変更と試合スコアのリセットを行うダイアログを表示する。
void showSettingsDialog(
  BuildContext context, {
  required GameSessionState session,
  required GameNotifier notifier,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _SettingsDialog(session: session, notifier: notifier),
  );
}

/// [TextEditingController] を dispose するため、StatefulWidget として実装する。
class _SettingsDialog extends StatefulWidget {
  final GameSessionState session;
  final GameNotifier notifier;

  const _SettingsDialog({required this.session, required this.notifier});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late final TextEditingController _topCtrl;
  late final TextEditingController _btmCtrl;

  @override
  void initState() {
    super.initState();
    _topCtrl = TextEditingController(text: widget.session.teamNameTop);
    _btmCtrl = TextEditingController(text: widget.session.teamNameBottom);
  }

  @override
  void dispose() {
    _topCtrl.dispose();
    _btmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('チーム設定・試合管理'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _topCtrl,
            decoration: const InputDecoration(labelText: '先攻チーム名'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _btmCtrl,
            decoration: const InputDecoration(labelText: '後攻チーム名'),
          ),
          const Divider(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
            ),
            onPressed: () {
              Navigator.pop(context);
              showResetConfirmDialog(context, notifier: widget.notifier);
            },
            icon: const Icon(Icons.refresh, color: Colors.red),
            label: const Text(
              '試合スコアを全リセット',
              style: TextStyle(color: Colors.red),
            ),
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
            widget.notifier.updateTeamNames(
              top: _topCtrl.text.isEmpty ? '先攻チーム' : _topCtrl.text,
              bottom: _btmCtrl.text.isEmpty ? '後攻チーム' : _btmCtrl.text,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
