import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_version.dart';
import '../../providers/game_provider.dart';
import '../../providers/theme_mode_provider.dart';
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

/// [TextEditingController] を dispose するため、ConsumerStatefulWidget として実装する。
class _SettingsDialog extends ConsumerStatefulWidget {
  final GameSessionState session;
  final GameNotifier notifier;

  const _SettingsDialog({required this.session, required this.notifier});

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
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
    final themeMode = ref.watch(themeModeProvider);
    return AlertDialog(
      title: const Text('チーム設定・試合管理'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topCtrl,
              enabled: widget.session.canEdit,
              decoration: const InputDecoration(labelText: '先攻チーム名'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _btmCtrl,
              enabled: widget.session.canEdit,
              decoration: const InputDecoration(labelText: '後攻チーム名'),
            ),
            const Divider(height: 24),
            const Text(
              '表示テーマ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('端末設定'),
                  icon: Icon(Icons.smartphone, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('ライト'),
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('ダーク'),
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selected) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selected.first);
              },
            ),
            if (widget.session.canEdit) ...[
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
            const Divider(height: 24),
            Text(
              kBuildInfo.isEmpty
                  ? 'バージョン: $kAppVersion'
                  : 'バージョン: $kAppVersion ($kBuildInfo)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('キャンセル'),
        ),
        if (widget.session.canEdit)
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
