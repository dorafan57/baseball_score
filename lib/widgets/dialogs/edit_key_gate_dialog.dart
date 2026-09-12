import 'package:flutter/material.dart';

import '../../services/game_sync_service.dart';

/// 既存試合を開く際、編集キーを入力して編集権限を取得するか、
/// 閲覧のみで開くかを選ぶダイアログを表示する。
///
/// 戻り値: 編集権限を得られたら `true`、閲覧のみを選んだら `false`、
/// ダイアログを閉じた場合は `null`。
Future<bool?> showEditKeyGateDialog(
  BuildContext context, {
  required GameSyncService sync,
  required String gameId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _EditKeyGateDialog(sync: sync, gameId: gameId),
  );
}

class _EditKeyGateDialog extends StatefulWidget {
  final GameSyncService sync;
  final String gameId;

  const _EditKeyGateDialog({required this.sync, required this.gameId});

  @override
  State<_EditKeyGateDialog> createState() => _EditKeyGateDialogState();
}

class _EditKeyGateDialogState extends State<_EditKeyGateDialog> {
  late final TextEditingController _keyCtrl;
  bool _obscureKey = true;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_keyCtrl.text.isEmpty) {
      setState(() => _error = '編集キーを入力してください');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await widget.sync.tryUnlockEditor(widget.gameId, _keyCtrl.text);
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _checking = false;
        _error = 'キーが違います';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('編集キーを入力'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'この試合を編集するには、作成者が設定した編集キーが必要です。'
            'キーが分からない場合は閲覧のみで開けます。',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscureKey,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '編集キー',
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            onSubmitted: (_) => _unlock(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('閲覧のみで続ける'),
        ),
        ElevatedButton(
          onPressed: _checking ? null : _unlock,
          child: Text(_checking ? '確認中…' : '確定'),
        ),
      ],
    );
  }
}
