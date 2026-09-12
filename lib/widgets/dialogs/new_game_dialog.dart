import 'package:flutter/material.dart';

/// 新規試合作成時に入力する内容。
typedef NewGameInput = ({
  String teamNameTop,
  String teamNameBottom,
  String editKey,
});

/// 新規試合作成ダイアログを表示する。
///
/// キャンセルされた場合は `null` を返す。
Future<NewGameInput?> showNewGameDialog(BuildContext context) {
  return showDialog<NewGameInput>(
    context: context,
    builder: (ctx) => const _NewGameDialog(),
  );
}

/// [TextEditingController] を dispose するため、StatefulWidget として実装する。
class _NewGameDialog extends StatefulWidget {
  const _NewGameDialog();

  @override
  State<_NewGameDialog> createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<_NewGameDialog> {
  late final TextEditingController _topCtrl;
  late final TextEditingController _btmCtrl;
  late final TextEditingController _keyCtrl;
  bool _obscureKey = true;
  String? _keyError;

  @override
  void initState() {
    super.initState();
    _topCtrl = TextEditingController(text: '自チーム (先)');
    _btmCtrl = TextEditingController(text: '対戦相手 (後)');
    _keyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _topCtrl.dispose();
    _btmCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_keyCtrl.text.isEmpty) {
      setState(() {
        _keyError = '編集キーを入力してください';
      });
      return;
    }
    Navigator.pop(context, (
      teamNameTop: _topCtrl.text.isEmpty ? '先攻チーム' : _topCtrl.text,
      teamNameBottom: _btmCtrl.text.isEmpty ? '後攻チーム' : _btmCtrl.text,
      editKey: _keyCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新規試合を作成'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _topCtrl,
            decoration: const InputDecoration(labelText: '先攻チーム名'),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _btmCtrl,
            decoration: const InputDecoration(labelText: '後攻チーム名'),
          ),
          const Divider(height: 24),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: '編集キー',
              helperText: 'この試合を編集する人に共有してください',
              errorText: _keyError,
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            onChanged: (_) {
              if (_keyError != null) {
                setState(() => _keyError = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('作成')),
      ],
    );
  }
}
