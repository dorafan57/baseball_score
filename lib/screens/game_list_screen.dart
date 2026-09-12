import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_game.dart';
import '../providers/game_provider.dart';
import '../services/game_storage_service.dart';
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
  final _storage = GameStorageService();
  List<SavedGame>? _savedGames;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final games = await _storage.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedGames = games;
    });
  }

  Future<void> _createNewGame() async {
    ref.read(gameProvider.notifier).startNewGame();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreInputScreen(
          gameId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ),
    );
    _loadGames();
  }

  Future<void> _openGame(SavedGame game) async {
    ref.read(gameProvider.notifier).loadGame(game);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreInputScreen(gameId: game.gameId),
      ),
    );
    _loadGames();
  }

  Future<void> _confirmDeleteGame(SavedGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('試合データの削除'),
        content: Text(
          '${game.teamNameTop} vs ${game.teamNameBottom} を削除しますか？\nこの操作は取り消せません。',
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
      await _storage.deleteGame(game.gameId);
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
