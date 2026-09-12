import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_game.dart';
import '../providers/game_provider.dart';
import '../services/game_sync_service.dart';
import '../widgets/dialogs/edit_key_gate_dialog.dart';
import '../widgets/dialogs/new_game_dialog.dart';
import 'score_input_screen.dart';

// ==========================================
// 試合一覧・管理画面 (ホーム画面)
// ==========================================
class GameListScreen extends ConsumerStatefulWidget {
  const GameListScreen({super.key});

  @override
  ConsumerState<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends ConsumerState<GameListScreen> {
  GameSyncService get _sync => ref.read(gameSyncServiceProvider);
  List<SavedGame>? _savedGames;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final games = await _sync.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedGames = games;
    });
  }

  Future<void> _createNewGame() async {
    final input = await showNewGameDialog(context);
    if (input == null) {
      return;
    }
    final notifier = ref.read(gameProvider.notifier);
    notifier.startNewGame();
    notifier.updateTeamNames(
      top: input.teamNameTop,
      bottom: input.teamNameBottom,
    );
    final gameId = DateTime.now().millisecondsSinceEpoch.toString();
    await _sync.createGame(notifier.toSavedGame(gameId), input.editKey);
    notifier.setCanEdit(true);
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScoreInputScreen(gameId: gameId)),
    );
    _loadGames();
  }

  /// まだ編集権限を持っていなければ、鍵入力ダイアログで編集権限を得るか
  /// 閲覧のみで続けるかを確認する。戻り値は最終的な編集可否。
  Future<bool> _resolveCanEdit(String gameId) async {
    if (await _sync.isEditor(gameId)) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    final result = await showEditKeyGateDialog(
      context,
      sync: _sync,
      gameId: gameId,
    );
    return result ?? false;
  }

  Future<void> _openGame(SavedGame game) async {
    final canEdit = await _resolveCanEdit(game.gameId);
    if (!mounted) {
      return;
    }
    final notifier = ref.read(gameProvider.notifier);
    notifier.loadGame(game);
    notifier.setCanEdit(canEdit);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreInputScreen(gameId: game.gameId),
      ),
    );
    _loadGames();
  }

  Future<void> _confirmDeleteGame(SavedGame game) async {
    final canEdit = await _resolveCanEdit(game.gameId);
    if (!mounted || !canEdit) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('試合データの削除'),
        content: Text(
          '${game.teamNameTop} vs ${game.teamNameBottom} を削除しますか？\n'
          'この試合はオンラインで共有されており、削除するとこの試合を開いている'
          '全員から見えなくなります。取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _sync.deleteGame(game.gameId);
      _loadGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _savedGames;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '草野球スコア - 試合一覧',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: games == null
          ? const Center(child: CircularProgressIndicator())
          : games.isEmpty
          ? const Center(
              child: Text(
                '保存された試合がありません。\n右下のボタンから新規試合を作成してください。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                final replay = game.replay();
                final savedAt = game.savedAt;
                final dateLabel =
                    '${savedAt.year}/${savedAt.month.toString().padLeft(2, '0')}/'
                    '${savedAt.day.toString().padLeft(2, '0')}';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.sports_baseball, color: Colors.white),
                    ),
                    title: Text(
                      '${game.teamNameTop} vs ${game.teamNameBottom}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$dateLabel | 結果: ${replay.totalScoreTop} - ${replay.totalScoreBottom}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openGame(game),
                    onLongPress: () => _confirmDeleteGame(game),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewGame,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('新規試合'),
      ),
    );
  }
}
