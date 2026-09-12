import 'package:flutter/material.dart';

import '../../services/game_sync_service.dart';

/// 管理者キーを入力し、全試合共通の管理者権限を取得するダイアログを表示する。
///
/// 戻り値: 取得できたら `true`、失敗またはキャンセルなら `false`/`null`。
Future<bool?> showAdminKeyDialog(
  BuildContext context, {
  required GameSyncService sync,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _AdminKeyDialog(sync: sync),
  );
}

class _AdminKeyDialog extends StatefulWidget {
  final GameSyncService sync;

  const _AdminKeyDialog({required this.sync});

  @override
  State<_AdminKeyDialog> createState() => _AdminKeyDialogState();
}

class _AdminKeyDialogState extends State<_AdminKeyDialog> {
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
      setState(() => _error = '管理者キーを入力してください');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await widget.sync.tryUnlockAdmin(_keyCtrl.text);
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
      title: const Text('管理者キーを入力'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '管理者キーを入力すると、このブラウザではすべての試合を'
            '編集キーなしで編集できるようになります。',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscureKey,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '管理者キー',
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey ? Icons.visibility : Icons.visibility_off,
                ),
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
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _checking ? null : _unlock,
          child: Text(_checking ? '確認中…' : '確定'),
        ),
      ],
    );
  }
}
