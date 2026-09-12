import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/game_event.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../services/game_storage_service.dart';
import '../widgets/board/input_tab.dart';
import '../widgets/dialogs/game_history_dialog.dart';
import '../widgets/dialogs/settings_dialog.dart';
import '../widgets/stats/score_stats_tab.dart';

class ScoreInputScreen extends ConsumerStatefulWidget {
  final String gameId;

  const ScoreInputScreen({super.key, required this.gameId});

  @override
  ConsumerState<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends ConsumerState<ScoreInputScreen> {
  int _selectedTabIndex = 0;
  int _scoreTabTeamIndex = 0;

  // --- 以下は GameNotifier（lib/providers/game_provider.dart）が保持する
  //     進行状態への読み取り専用の窓口。試合の「事実」や打順・イニングなど
  //     の状態そのものは GameNotifier に一元化されている。
  //
  //     再描画の購読は build() 先頭の ref.watch(gameProvider) 1箇所だけで行い、
  //     各タブ・ダイアログへはそのスナップショットを引数として渡す。

  GameSessionState get _session => ref.read(gameProvider);
  GameNotifier get _notifier => ref.read(gameProvider.notifier);

  String get teamNameTop => _session.teamNameTop;
  String get teamNameBottom => _session.teamNameBottom;

  /// 記録された全イベント。この配列だけが試合の「事実」であり、
  /// スコアも個人成績もすべて [_state] を通じてここから導出される。
  List<GameEvent> get _gameEvents => _session.gameEvents;

  /// [_gameEvents] を再生した結果。
  GameState get _state => _session.replay;

  // --- 以下は再生結果 [_state] から導出される読み取り専用の値 ---

  List<int> get scoresTop => _session.scoresTop;
  List<int> get scoresBottom => _session.scoresBottom;
  int get errorsTop => _session.errorsTop;
  int get errorsBottom => _session.errorsBottom;
  int get totalScoreTop => _session.totalScoreTop;
  int get totalScoreBottom => _session.totalScoreBottom;

  int get totalHitsTop => _session.totalHitsTop;
  int get totalHitsBottom => _session.totalHitsBottom;

  // =====================================
  // 各タブ・ダイアログへコールバックとして渡すアクション
  // =====================================

  void _undo() => _notifier.undo();

  void _deleteEvent(int eventId) {
    _notifier.deleteEvent(eventId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('イベントを削除し、成績を再計算しました。'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteCurrentPlateEvent() => _notifier.deleteCurrentPlateEvent();

  void _jumpToInning(int targetInn, bool targetIsTop) =>
      _notifier.jumpToInning(targetInn, targetIsTop);

  /// スコア一覧からイニングを選んだときは、あわせて盤面入力タブへ切り替える。
  void _jumpToInningAndShowBoard(int targetInn, bool targetIsTop) {
    _notifier.jumpToInning(targetInn, targetIsTop);
    _showBoardTab();
  }

  void _jumpToBatter(int targetIdx) => _notifier.jumpToBatter(targetIdx);

  void _showBoardTab() {
    setState(() {
      _selectedTabIndex = 0;
    });
  }

  // =====================================
  // シェア用テキストの生成処理
  // =====================================

  /// チーム略称の表示幅（全角2文字分）。
  static const int _teamCodeWidth = 4;

  /// 全角文字を2、半角文字を1として文字列の表示幅を数える。
  static int _visualWidth(String s) {
    int width = 0;
    for (final rune in s.runes) {
      width += _isWideRune(rune) ? 2 : 1;
    }
    return width;
  }

  static bool _isWideRune(int rune) {
    return (rune >= 0x1100 && rune <= 0x115F) || // ハングル字母
        (rune >= 0x2E80 && rune <= 0xA4CF) || // CJK 部首・仮名・ハングル音節等
        (rune >= 0xAC00 && rune <= 0xD7A3) || // ハングル音節
        (rune >= 0xF900 && rune <= 0xFAFF) || // CJK互換漢字
        (rune >= 0xFF00 && rune <= 0xFF60) || // 全角英数・記号
        (rune >= 0xFFE0 && rune <= 0xFFE6);
  }

  /// 表示幅が [maxWidth] を超えないよう、文字を途中で分割せずに切り詰める。
  static String _visualTruncate(String s, int maxWidth) {
    final buffer = StringBuffer();
    int width = 0;
    for (final rune in s.runes) {
      final charWidth = _isWideRune(rune) ? 2 : 1;
      if (width + charWidth > maxWidth) {
        break;
      }
      buffer.writeCharCode(rune);
      width += charWidth;
    }
    return buffer.toString();
  }

  /// 表示幅が [targetWidth] になるよう半角スペースで埋める。
  static String _padToVisualWidth(String s, int targetWidth) {
    final padding = targetWidth - _visualWidth(s);
    return padding > 0 ? s + ' ' * padding : s;
  }

  String _generateShareText() {
    int maxInn = scoresTop.length;
    String header = ' ' * (_teamCodeWidth + 1);
    for (int i = 1; i <= maxInn; i++) {
      header += '$i ';
    }
    header += '| R H E';

    String topNameShort = _visualTruncate(teamNameTop, _teamCodeWidth);
    String topRow = '${_padToVisualWidth(topNameShort, _teamCodeWidth)} ';
    for (int s in scoresTop) {
      topRow += '$s ';
    }
    topRow += '| $totalScoreTop $totalHitsTop $errorsTop';

    String btmNameShort = _visualTruncate(teamNameBottom, _teamCodeWidth);
    String btmRow = '${_padToVisualWidth(btmNameShort, _teamCodeWidth)} ';
    for (int s in scoresBottom) {
      btmRow += '$s ';
    }
    btmRow += '| $totalScoreBottom $totalHitsBottom $errorsBottom';

    StringBuffer sb = StringBuffer();
    sb.writeln('⚾ 試合スコア速報 ⚾');
    sb.writeln(
      '$teamNameTop $totalScoreTop - $totalScoreBottom $teamNameBottom\n',
    );
    sb.writeln(header);
    sb.writeln(topRow);
    sb.writeln(btmRow);
    sb.writeln('');
    sb.writeln('#草野球スコア #野球');
    return sb.toString();
  }

  void _shareResult() {
    final text = _generateShareText();
    Share.share(text);
  }

  Future<void> _saveAndExit() async {
    final saved = _notifier.toSavedGame(widget.gameId);
    await GameStorageService().saveGame(saved);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 進行状態が変わるたびにこの画面を再描画するための購読。
    final session = ref.watch(gameProvider);
    final notifier = _notifier;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '草野球スコア記録',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '試合イベント履歴・取消',
            onPressed: () => showGameHistoryDialog(
              context,
              state: _state,
              onDeleteEvent: _deleteEvent,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '1手戻す',
            onPressed: _gameEvents.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '試合結果をシェア',
            onPressed: _shareResult,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'チーム名・試合設定',
            onPressed: () => showSettingsDialog(
              context,
              session: _session,
              notifier: notifier,
            ),
          ),
        ],
      ),
      body: _selectedTabIndex == 0
          ? InputTab(
              session: session,
              notifier: notifier,
              onJumpToInning: _jumpToInning,
              onJumpToBatter: _jumpToBatter,
              onDeleteCurrentPlateEvent: _deleteCurrentPlateEvent,
              onSaveAndExit: _saveAndExit,
            )
          : ScoreStatsTab(
              session: session,
              notifier: notifier,
              teamIndex: _scoreTabTeamIndex,
              onTeamChanged: (idx) {
                setState(() {
                  _scoreTabTeamIndex = idx;
                });
              },
              onJumpToInning: _jumpToInningAndShowBoard,
              onShowBoardTab: _showBoardTab,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _selectedTabIndex = idx;
          });
        },
        indicatorColor: Colors.green.shade200,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_baseball),
            label: '盤面入力',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart),
            label: 'スコア・成績一覧',
          ),
        ],
      ),
    );
  }
}
