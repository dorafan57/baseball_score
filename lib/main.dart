import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'logic/advance_calculator.dart';
import 'logic/game_replay.dart';
import 'models/at_bat_result.dart';
import 'models/base_runners.dart';
import 'models/game_event.dart';
import 'models/game_state.dart';
import 'models/player.dart';
import 'models/resolved_event.dart';

void main() {
  runApp(const BaseballScoreApp());
}

class BaseballScoreApp extends StatelessWidget {
  const BaseballScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '草野球スコア',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F4),
        useMaterial3: true,
      ),
      home: const GameListScreen(),
    );
  }
}

// ==========================================
// 試合一覧・管理画面 (ホーム画面)
// ==========================================
class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  final List<Map<String, dynamic>> _savedGames = [];

  void _createNewGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreInputScreen(
          gameId: DateTime.now().millisecondsSinceEpoch.toString(),
          onSave: (gameData) {
            setState(() {
              _savedGames.insert(0, gameData);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '草野球スコア - 試合一覧',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: _savedGames.isEmpty
          ? const Center(
              child: Text(
                '保存された試合がありません。\n右下のボタンから新規試合を作成してください。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _savedGames.length,
              itemBuilder: (context, index) {
                final game = _savedGames[index];
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
                      '${game['topTeam']} vs ${game['bottomTeam']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${game['date']} | 結果: ${game['topScore']} - ${game['bottomScore']}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('過去の試合データの読み込みは次回以降の実装で対応します！'),
                        ),
                      );
                    },
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

class ScoreInputScreen extends StatefulWidget {
  final String gameId;
  final Function(Map<String, dynamic>) onSave;

  const ScoreInputScreen({
    super.key,
    required this.gameId,
    required this.onSave,
  });

  @override
  State<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends State<ScoreInputScreen> {
  int _selectedTabIndex = 0;

  String teamNameTop = '自チーム (先)';
  String teamNameBottom = '対戦相手 (後)';

  int totalInningsConfig = 7;
  int inning = 1;
  bool isTop = true;

  int outs = 0;
  BaseRunners runners = BaseRunners.empty;

  int batterIndexTop = 0;
  int batterIndexBottom = 0;
  int cycleIndexTop = 0;
  int cycleIndexBottom = 0;

  List<Player> playersTop = [
    Player(id: 't1', name: '佐藤', position: '遊'),
    Player(id: 't2', name: '鈴木', position: '中'),
    Player(id: 't3', name: '高橋', position: '右'),
    Player(id: 't4', name: '田中', position: '一'),
    Player(id: 't5', name: '渡辺', position: '三'),
    Player(id: 't6', name: '伊藤', position: '左'),
    Player(id: 't7', name: '山本', position: '捕'),
    Player(id: 't8', name: '中村', position: '二'),
    Player(id: 't9', name: '小林', position: '投'),
  ];

  List<Player> playersBottom = [
    Player(id: 'b1', name: '大谷', position: '中'),
    Player(id: 'b2', name: 'イチロー', position: '右'),
    Player(id: 'b3', name: '松井', position: '左'),
    Player(id: 'b4', name: '王', position: '一'),
    Player(id: 'b5', name: '長嶋', position: '三'),
    Player(id: 'b6', name: '野村', position: '捕'),
    Player(id: 'b7', name: '落合', position: '二'),
    Player(id: 'b8', name: '坂本', position: '遊'),
    Player(id: 'b9', name: 'ダルビッシュ', position: '投'),
  ];

  late String currentPitcherIdTop;
  late String currentPitcherIdBottom;

  /// 記録された全イベント。この配列だけが試合の「事実」であり、
  /// スコアも個人成績もすべて [_state] を通じてここから導出される。
  final List<GameEvent> _gameEvents = [];

  /// 次に発行するイベントID。
  ///
  /// 途中のイベントを削除してもIDが重複しないよう、単調増加のカウンタで管理する。
  int _nextEventId = 1;

  /// [_gameEvents] を再生した結果。
  GameState _state = GameState.initial();

  int _scoreTabTeamIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPitcherIdTop = playersTop
        .firstWhere((p) => p.position == '投', orElse: () => playersTop.last)
        .id;
    currentPitcherIdBottom = playersBottom
        .firstWhere((p) => p.position == '投', orElse: () => playersBottom.last)
        .id;
    _rebuildGameState();
  }

  List<Player> get currentBatters => isTop ? playersTop : playersBottom;
  List<Player> get defendingPlayers => isTop ? playersBottom : playersTop;

  Player get activePitcher {
    String pId = isTop ? currentPitcherIdBottom : currentPitcherIdTop;
    return _findPlayer(pId) ?? defendingPlayers.first;
  }

  int get currentBatterIndex => isTop ? batterIndexTop : batterIndexBottom;
  set currentBatterIndex(int val) {
    if (isTop) {
      batterIndexTop = val;
    } else {
      batterIndexBottom = val;
    }
  }

  int get _currentCycle => isTop ? cycleIndexTop : cycleIndexBottom;
  set _currentCycle(int val) {
    if (isTop) {
      cycleIndexTop = val;
    } else {
      cycleIndexBottom = val;
    }
  }

  // --- 以下は再生結果 [_state] から導出される読み取り専用の値 ---

  List<int> get scoresTop => _state.scoresTop;
  List<int> get scoresBottom => _state.scoresBottom;
  int get errorsTop => _state.errorsTop;
  int get errorsBottom => _state.errorsBottom;
  int get totalScoreTop => _state.totalScoreTop;
  int get totalScoreBottom => _state.totalScoreBottom;

  int get totalHitsTop => playersTop.fold(0, (sum, b) => sum + b.stats.hits);
  int get totalHitsBottom =>
      playersBottom.fold(0, (sum, b) => sum + b.stats.hits);

  Iterable<Player> get _allPlayers => [...playersTop, ...playersBottom];

  Player? _findPlayer(String? id) {
    if (id == null) {
      return null;
    }
    for (final p in playersTop) {
      if (p.id == id) {
        return p;
      }
    }
    for (final p in playersBottom) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  int get maxCycleInCurrentInning {
    final evs = _state.events.where(
      (e) => e.inning == inning && e.isTop == isTop && !e.isBaserunningEvent,
    );
    if (evs.isEmpty) {
      return 0;
    }
    return evs.map((e) => e.cycleIndex).reduce((a, b) => a > b ? a : b);
  }

  /// 現在選択中の打席（回・表裏・巡目・打順が一致するイベント）。
  ///
  /// 既に結果が入力済みの打席を選び直しているときは非 null になり、
  /// このとき新たな入力は「上書き」として扱われる。
  ResolvedEvent? get activeEvent {
    return _state.events
        .where(
          (e) =>
              !e.isBaserunningEvent &&
              e.inning == inning &&
              e.isTop == isTop &&
              e.cycleIndex == _currentCycle &&
              e.batterIndex == currentBatterIndex,
        )
        .firstOrNull;
  }

  void _showRuleWarning(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.brown.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _promptChangePitcherDialog() {
    final teamPlayers = defendingPlayers;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${isTop ? teamNameBottom : teamNameTop} 投手交代（継投）'),
        children: teamPlayers.map((p) {
          bool isCurrent = p.id == activePitcher.id;
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                if (isTop) {
                  currentPitcherIdBottom = p.id;
                } else {
                  currentPitcherIdTop = p.id;
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('投手を [${p.name}] に交代しました。')),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrent
                      ? Colors.amber.shade800
                      : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  child: const Text('投', style: TextStyle(fontSize: 10)),
                ),
                const SizedBox(width: 10),
                Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${p.position})',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                if (isCurrent)
                  const Text(
                    '登板中',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// イベント列を再生し、スコア・個人成績・盤面表示を作り直す。
  ///
  /// 集計ロジックそのものは `replayGame()` に切り出してあり、ここでは
  /// その結果を画面の状態へ反映するだけにしている。
  void _rebuildGameState() {
    _state = replayGame(
      events: _gameEvents,
      minInnings: totalInningsConfig > inning ? totalInningsConfig : inning,
    );
    for (final player in _allPlayers) {
      player.stats = _state.statsOf(player.id);
    }
    _syncCurrentView();
  }

  /// 盤面（走者・アウトカウント）の表示を、選択中の打席に合わせて更新する。
  void _syncCurrentView() {
    final current = activeEvent;
    if (current != null) {
      // 入力済みの打席を選び直している場合は、その打席の開始時点を表示する。
      runners = current.runnersBefore;
      outs = current.outsBefore;
      return;
    }

    final inningEvents = _state.eventsInHalfInning(
      inning,
      isTop,
      includeIgnored: false,
    );
    if (inningEvents.isNotEmpty) {
      runners = inningEvents.last.runnersAfter;
      outs = inningEvents.last.outsAfter;
    } else {
      runners = BaseRunners.empty;
      outs = 0;
    }
  }

  void _undo() {
    if (_gameEvents.isEmpty) {
      return;
    }
    setState(() {
      final last = _gameEvents.removeLast();
      inning = last.inning;
      isTop = last.isTop;
      if (last.batterIndex >= 0 && !last.isBaserunningEvent) {
        currentBatterIndex = last.batterIndex;
      }
      _currentCycle = last.cycleIndex;
      _rebuildGameState();
    });
  }

  void _deleteEvent(int eventId) {
    setState(() {
      _gameEvents.removeWhere((e) => e.eventId == eventId);
      _rebuildGameState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('イベントを削除し、成績を再計算しました。'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteCurrentPlateEvent() {
    final ev = activeEvent;
    if (ev == null) {
      return;
    }
    _deleteEvent(ev.eventId);
  }

  void _changeInning() {
    outs = 0;
    runners = BaseRunners.empty;
    if (!isTop) {
      inning++;
    }
    isTop = !isTop;
    _currentCycle = 0;
    currentBatterIndex = 0;
    _rebuildGameState();
  }

  void _nextBatter() {
    int nextIdx = currentBatterIndex + 1;
    if (nextIdx >= currentBatters.length) {
      nextIdx = 0;
      _currentCycle++;
    }
    currentBatterIndex = nextIdx;
    _syncCurrentView();

    if (outs >= 3) {
      _changeInning();
    }
  }

  void _jumpToInning(int targetInn, bool targetIsTop) {
    setState(() {
      inning = targetInn;
      isTop = targetIsTop;
      _currentCycle = 0;
      currentBatterIndex = 0;
      _rebuildGameState();
    });
  }

  void _jumpToBatter(int targetIdx) {
    setState(() {
      currentBatterIndex = targetIdx;
      _syncCurrentView();
    });
  }

  /// 走塁イベント（盗塁・WP・PB・走塁死など）を記録する。
  ///
  /// [runnerId] にはイベントの主体となる走者を渡す。盗塁数はこの走者に記録される。
  void _recordBaserunningEvent(
    String desc,
    BaseRunners newRunners, {
    bool isSteal = false,
    String? batterId,
    String? runnerId,
    int runs = 0,
    List<String>? scoredIds,
  }) {
    setState(() {
      _gameEvents.add(
        GameEvent(
          eventId: _nextEventId++,
          inning: inning,
          isTop: isTop,
          description: desc,
          batterId: batterId,
          batterIndex: currentBatterIndex,
          pitcherId: activePitcher.id,
          cycleIndex: _currentCycle,
          runs: runs,
          earnedRuns: runs,
          scoredPlayerIds: scoredIds,
          runnerId: runnerId,
          runnersAfter: newRunners,
          isBaserunningEvent: true,
          isSteal: isSteal,
        ),
      );
      _rebuildGameState();
      _changeInningIfCompleted();
    });
  }

  /// 打席結果を、標準的な進塁ルールにしたがって記録する。
  void _recordOrUpdateAtBat(
    AtBatResult result, {
    required String direction,
    String? errorPlayerId,
  }) {
    final batter = currentBatters[currentBatterIndex];
    final advance = calculateDefaultAdvance(
      result: result,
      runners: runners,
      batterId: batter.id,
    );
    _commitAtBat(
      result: result,
      direction: direction,
      runnersAfter: advance.runners,
      runs: advance.runs,
      rbi: advance.rbi,
      scoredPlayerIds: advance.scoredPlayerIds,
      errorPlayerId: errorPlayerId,
    );
  }

  /// 走者ごとの行き先をダイアログで指定した打席結果を記録する。
  void _applyCustomHitResult(
    AtBatResult result,
    String direction,
    BaseRunners customRunners,
    int runs,
    int rbi,
    List<String> scoredIds, {
    String? errorPlayerId,
  }) {
    _commitAtBat(
      result: result,
      direction: direction,
      runnersAfter: customRunners,
      runs: runs,
      rbi: rbi,
      scoredPlayerIds: scoredIds,
      errorPlayerId: errorPlayerId,
    );
  }

  /// 打席結果をイベントとして確定させる。
  ///
  /// 現在の打席にすでに結果が入力されている場合は、同じイベントIDのまま
  /// 新しい内容で差し替える（＝上書き入力）。
  void _commitAtBat({
    required AtBatResult result,
    required String direction,
    required BaseRunners runnersAfter,
    required int runs,
    required int rbi,
    required List<String> scoredPlayerIds,
    String? errorPlayerId,
  }) {
    setState(() {
      final batter = currentBatters[currentBatterIndex];
      final target = activeEvent;
      final isUpdate = target != null;

      final event = GameEvent(
        eventId: isUpdate ? target.eventId : _nextEventId++,
        inning: inning,
        isTop: isTop,
        description: '',
        batterId: batter.id,
        batterIndex: currentBatterIndex,
        pitcherId: isUpdate ? target.pitcherId : activePitcher.id,
        cycleIndex: _currentCycle,
        result: result,
        direction: direction,
        errorPlayerId: errorPlayerId,
        rbi: rbi,
        runs: runs,
        // 失策がからむ得点は自責点に含めない。
        earnedRuns: (result == AtBatResult.error || errorPlayerId != null)
            ? 0
            : runs,
        scoredPlayerIds: scoredPlayerIds,
        runnersAfter: runnersAfter,
      );

      // 説明文は displayShortLabel を使うため、確定後のイベントから組み立てる。
      final described = _withDescription(
        event,
        '${currentBatterIndex + 1}番 ${batter.name}: ${event.displayShortLabel}',
      );

      if (isUpdate) {
        final index = _gameEvents.indexWhere((e) => e.eventId == event.eventId);
        _gameEvents[index] = described;
      } else {
        _gameEvents.add(described);
      }

      _rebuildGameState();

      if (!_changeInningIfCompleted() && !isUpdate) {
        _nextBatter();
      }
    });
  }

  /// [event] の説明文だけを差し替えた新しいイベントを返す。
  GameEvent _withDescription(GameEvent event, String description) => GameEvent(
    eventId: event.eventId,
    inning: event.inning,
    isTop: event.isTop,
    description: description,
    batterId: event.batterId,
    batterIndex: event.batterIndex,
    pitcherId: event.pitcherId,
    cycleIndex: event.cycleIndex,
    result: event.result,
    direction: event.direction,
    rbi: event.rbi,
    runs: event.runs,
    earnedRuns: event.earnedRuns,
    scoredPlayerIds: event.scoredPlayerIds,
    errorPlayerId: event.errorPlayerId,
    runnerId: event.runnerId,
    runnersAfter: event.runnersAfter,
    isBaserunningEvent: event.isBaserunningEvent,
    isSteal: event.isSteal,
  );

  /// 現在の半イニングが3アウトに達していれば攻守交代する。
  ///
  /// 交代した場合は true を返す。
  bool _changeInningIfCompleted() {
    final events = _state.eventsInHalfInning(
      inning,
      isTop,
      includeIgnored: false,
    );
    if (events.isEmpty || events.last.outsAfter < 3) {
      return false;
    }
    _changeInning();
    return true;
  }

  // =====================================
  // シェア用テキストの生成処理
  // =====================================
  String _generateShareText() {
    int maxInn = scoresTop.length;
    String header = '   ';
    for (int i = 1; i <= maxInn; i++) {
      header += '$i ';
    }
    header += '| R H E';

    String topNameShort = teamNameTop.length > 2
        ? teamNameTop.substring(0, 2)
        : teamNameTop;
    String topRow = '${topNameShort.padRight(2, ' ')} ';
    for (int s in scoresTop) {
      topRow += '$s ';
    }
    topRow += '| $totalScoreTop $totalHitsTop $errorsTop';

    String btmNameShort = teamNameBottom.length > 2
        ? teamNameBottom.substring(0, 2)
        : teamNameBottom;
    String btmRow = '${btmNameShort.padRight(2, ' ')} ';
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

  void _saveAndExit() {
    widget.onSave({
      'id': widget.gameId,
      'date': DateTime.now().toString().substring(0, 10),
      'topTeam': teamNameTop,
      'bottomTeam': teamNameBottom,
      'topScore': totalScoreTop,
      'bottomScore': totalScoreBottom,
    });
    Navigator.pop(context);
  }

  void _promptDoublePlayRoute({String? errorPlayerId}) {
    List<String> route = [];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text('併殺の経路を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.infinity,
                child: Text(
                  route.isEmpty ? "(未選択)" : route.join(" → "),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'].map((
                  pos,
                ) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () {
                      setDState(() {
                        route.add(pos);
                      });
                    },
                    child: Text(pos),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  setDState(() {
                    route.clear();
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('クリア'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                String direction = route.join('→');
                if (direction.isEmpty) {
                  direction = '併殺';
                }
                _recordOrUpdateAtBat(
                  AtBatResult.doublePlay,
                  direction: direction,
                  errorPlayerId: errorPlayerId,
                );
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _promptWalkOrErrorRunnersDialog(
    AtBatResult result, {
    String? errorPlayerId,
    String direction = '',
  }) {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }

    String batterId = currentBatters[currentBatterIndex].id;

    if (runners.isEmpty) {
      _recordOrUpdateAtBat(
        result,
        direction: direction,
        errorPlayerId: errorPlayerId,
      );
      return;
    }

    int r3Choice = 1;
    int r2Choice = 2;
    int r1Choice = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: Text('${result.label}時の走者・打者の進塁確認'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '打者 [${currentBatters[currentBatterIndex].name}] の${result.label}です。各走者および打者の進塁先を選んでください：',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                if (runners.runner3rd != null)
                  _runnerChoiceTile(
                    '3塁: ${_findPlayer(runners.runner3rd)?.name}',
                    ['本塁生還 (得点 ※打点なし)', '3塁そのまま'],
                    (val) {
                      setDState(() {
                        r3Choice = val;
                      });
                    },
                    r3Choice,
                  ),
                if (runners.runner2nd != null)
                  _runnerChoiceTile(
                    '2塁: ${_findPlayer(runners.runner2nd)?.name}',
                    ['3塁へ進塁', '本塁生還 (得点 ※打点なし)', '2塁そのまま'],
                    (val) {
                      setDState(() {
                        r2Choice = val;
                      });
                    },
                    r2Choice,
                  ),
                if (runners.runner1st != null)
                  _runnerChoiceTile(
                    '1塁: ${_findPlayer(runners.runner1st)?.name}',
                    ['2塁へ進塁', '1塁そのまま'],
                    (val) {
                      setDState(() {
                        r1Choice = val;
                      });
                    },
                    r1Choice,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);

                int calcRuns = 0;
                List<String> scoredIds = [];
                String? final3rd;
                String? final2nd;
                String? final1st = batterId;

                if (runners.runner1st != null) {
                  if (r1Choice == 0) {
                    final2nd = runners.runner1st;
                  } else {
                    final1st = runners.runner1st;
                  }
                }

                if (runners.runner2nd != null) {
                  if (r2Choice == 0) {
                    final3rd = runners.runner2nd;
                  } else if (r2Choice == 1) {
                    calcRuns++;
                    scoredIds.add(runners.runner2nd!);
                  } else {
                    if (final2nd == null) {
                      final2nd = runners.runner2nd;
                    } else {
                      final3rd = runners.runner2nd;
                    }
                  }
                }

                if (runners.runner3rd != null) {
                  if (r3Choice == 0) {
                    calcRuns++;
                    scoredIds.add(runners.runner3rd!);
                  } else {
                    if (final3rd == null) {
                      final3rd = runners.runner3rd;
                    } else if (final2nd == null) {
                      final2nd = final3rd;
                      final3rd = runners.runner3rd;
                    } else {
                      final1st = final2nd;
                      final2nd = final3rd;
                      final3rd = runners.runner3rd;
                    }
                  }
                }

                BaseRunners customRunners = BaseRunners(
                  runner1st: final1st,
                  runner2nd: final2nd,
                  runner3rd: final3rd,
                );
                _applyCustomHitResult(
                  result,
                  direction,
                  customRunners,
                  calcRuns,
                  0,
                  scoredIds,
                  errorPlayerId: errorPlayerId,
                );
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _promptHitWithRunnersDialog(AtBatResult result, String direction) {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }

    if (result == AtBatResult.homeRun) {
      _recordOrUpdateAtBat(result, direction: direction);
      return;
    }

    if (runners.isEmpty) {
      if (result == AtBatResult.error) {
        _promptErrorPlayerSelectionAndRecord(
          result,
          direction,
          BaseRunners(runner1st: currentBatters[currentBatterIndex].id),
          0,
          0,
          [],
        );
      } else {
        _recordOrUpdateAtBat(result, direction: direction);
      }
      return;
    }

    String batterId = currentBatters[currentBatterIndex].id;
    int r3Choice = 0;
    int r2Choice = 0;
    int r1Choice = 0;
    int batterChoice = 0;
    bool isErrorExtraAdvance = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: Text('${result.label}時の走者・打者の進塁確認'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '打者 [${currentBatters[currentBatterIndex].name}] は${result.label}です。\n各走者・打者の進塁先を選んでください：',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),

                if (runners.runner3rd != null)
                  _runnerChoiceTile(
                    '3塁: ${_findPlayer(runners.runner3rd)?.name}',
                    ['本塁生還 (得点)', '3塁で止まる'],
                    (val) {
                      setDState(() {
                        r3Choice = val;
                      });
                    },
                    r3Choice,
                  ),

                if (runners.runner2nd != null)
                  _runnerChoiceTile(
                    '2塁: ${_findPlayer(runners.runner2nd)?.name}',
                    result == AtBatResult.singleHit
                        ? ['3塁へ進塁', '2塁で止まる', '本塁生還 (追加進塁)']
                        : ['本塁生還 (得点)', '2塁で止まる', '3塁で止まる'],
                    (val) {
                      setDState(() {
                        r2Choice = val;
                      });
                    },
                    r2Choice,
                  ),

                if (runners.runner1st != null)
                  _runnerChoiceTile(
                    '1塁: ${_findPlayer(runners.runner1st)?.name}',
                    result == AtBatResult.singleHit
                        ? ['2塁へ進塁', '1塁で止まる', '3塁へ (追加進塁)']
                        : ['3塁へ進塁', '2塁で止まる', '本塁生還 (追加進塁)'],
                    (val) {
                      setDState(() {
                        r1Choice = val;
                      });
                    },
                    r1Choice,
                  ),

                _runnerChoiceTile(
                  '打者: ${currentBatters[currentBatterIndex].name}',
                  result == AtBatResult.singleHit
                      ? ['1塁へ (標準)', '2塁へ (追加進塁)']
                      : result == AtBatResult.doubleHit
                      ? ['2塁へ (標準)', '3塁へ (追加進塁)']
                      : ['3塁へ (標準)', '本塁へ (追加進塁)'],
                  (val) {
                    setDState(() {
                      batterChoice = val;
                    });
                  },
                  batterChoice,
                ),

                const Divider(height: 20),
                CheckboxListTile(
                  title: const Text(
                    '追加進塁は守備側のエラー(敵失)によるもの',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  value: isErrorExtraAdvance,
                  onChanged: (val) {
                    setDState(() {
                      isErrorExtraAdvance = val ?? false;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);

                int calcRuns = 0;
                int calcRbi = 0;
                List<String> scoredIds = [];
                String? final3rd;
                String? final2nd;
                String? final1st;

                int baseRbi = 0;
                if (result == AtBatResult.singleHit) {
                  if (runners.runner3rd != null) {
                    baseRbi++;
                  }
                } else if (result == AtBatResult.doubleHit) {
                  if (runners.runner3rd != null) {
                    baseRbi++;
                  }
                  if (runners.runner2nd != null) {
                    baseRbi++;
                  }
                } else if (result == AtBatResult.tripleHit) {
                  if (runners.runner3rd != null) {
                    baseRbi++;
                  }
                  if (runners.runner2nd != null) {
                    baseRbi++;
                  }
                  if (runners.runner1st != null) {
                    baseRbi++;
                  }
                }
                calcRbi = baseRbi;

                String? bDest = batterChoice == 0
                    ? (result == AtBatResult.singleHit
                          ? '1st'
                          : result == AtBatResult.doubleHit
                          ? '2nd'
                          : '3rd')
                    : (result == AtBatResult.singleHit
                          ? '2nd'
                          : result == AtBatResult.doubleHit
                          ? '3rd'
                          : 'home');

                if (bDest == '1st') {
                  final1st = batterId;
                }
                if (bDest == '2nd') {
                  final2nd = batterId;
                }
                if (bDest == '3rd') {
                  final3rd = batterId;
                }
                if (bDest == 'home') {
                  calcRuns++;
                  scoredIds.add(batterId);
                  if (!isErrorExtraAdvance) {
                    calcRbi++;
                  }
                }

                if (runners.runner1st != null) {
                  if (r1Choice == 0) {
                    String target = result == AtBatResult.singleHit
                        ? '2nd'
                        : '3rd';
                    if (target == '2nd') {
                      final2nd ??= runners.runner1st;
                    } else if (target == '3rd') {
                      final3rd ??= runners.runner1st;
                    }
                  } else if (r1Choice == 1) {
                    String target = result == AtBatResult.singleHit
                        ? '1st'
                        : '2nd';
                    if (target == '1st') {
                      final1st ??= runners.runner1st;
                    } else if (target == '2nd') {
                      final2nd ??= runners.runner1st;
                    }
                  } else {
                    String target = result == AtBatResult.singleHit
                        ? '3rd'
                        : 'home';
                    if (target == '3rd') {
                      final3rd ??= runners.runner1st;
                    } else if (target == 'home') {
                      calcRuns++;
                      scoredIds.add(runners.runner1st!);
                      if (!isErrorExtraAdvance) {
                        calcRbi++;
                      }
                    }
                  }
                }

                if (runners.runner2nd != null) {
                  if (r2Choice == 0) {
                    if (result == AtBatResult.singleHit) {
                      final3rd ??= runners.runner2nd;
                    } else {
                      calcRuns++;
                      scoredIds.add(runners.runner2nd!);
                    }
                  } else if (r2Choice == 1) {
                    final2nd ??= runners.runner2nd;
                  } else {
                    if (result == AtBatResult.singleHit) {
                      calcRuns++;
                      scoredIds.add(runners.runner2nd!);
                      if (!isErrorExtraAdvance) {
                        calcRbi++;
                      }
                    } else {
                      final3rd ??= runners.runner2nd;
                    }
                  }
                }

                if (runners.runner3rd != null) {
                  if (r3Choice == 0) {
                    calcRuns++;
                    scoredIds.add(runners.runner3rd!);
                  } else {
                    if (final3rd == null) {
                      final3rd = runners.runner3rd;
                    } else if (final2nd == null) {
                      final2nd = final3rd;
                      final3rd = runners.runner3rd;
                    } else {
                      final1st = final2nd;
                      final2nd = final3rd;
                      final3rd = runners.runner3rd;
                    }
                  }
                }

                BaseRunners customRunners = BaseRunners(
                  runner1st: final1st,
                  runner2nd: final2nd,
                  runner3rd: final3rd,
                );

                if (isErrorExtraAdvance) {
                  _promptErrorPlayerSelectionAndRecord(
                    result,
                    direction,
                    customRunners,
                    calcRuns,
                    calcRbi,
                    scoredIds,
                  );
                } else {
                  _applyCustomHitResult(
                    result,
                    direction,
                    customRunners,
                    calcRuns,
                    calcRbi,
                    scoredIds,
                  );
                }
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _promptErrorPlayerSelectionAndRecord(
    AtBatResult result,
    String direction,
    BaseRunners customRunners,
    int runs,
    int rbi,
    List<String> scoredIds,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('追加進塁エラーを起こした野手を選択'),
        children: defendingPlayers.map((p) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _applyCustomHitResult(
                result,
                direction,
                customRunners,
                runs,
                rbi,
                scoredIds,
                errorPlayerId: p.id,
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.position,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _promptDirectionAndRecord(AtBatResult result, {String? errorPlayerId}) {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。これ以上アウトになる打席は入力できません。');
      return;
    }

    if (result == AtBatResult.doublePlay) {
      if (outs >= 2) {
        _showRuleWarning('⚠️ 2アウトの場面で併殺打（ダブルプレイ）は選択できません。');
        return;
      }
      _promptDoublePlayRoute(errorPlayerId: errorPlayerId);
      return;
    }

    if (result == AtBatResult.walk || result == AtBatResult.hitByPitch) {
      _recordOrUpdateAtBat(result, direction: '');
      return;
    }

    if (result == AtBatResult.error) {
      if (runners.isNotEmpty) {
        _promptWalkOrErrorRunnersDialog(
          result,
          errorPlayerId: errorPlayerId,
          direction: errorPlayerId != null
              ? defendingPlayers
                    .firstWhere((p) => p.id == errorPlayerId)
                    .position
              : '',
        );
        return;
      }
    }

    bool needsDirection = [
      AtBatResult.singleHit,
      AtBatResult.doubleHit,
      AtBatResult.tripleHit,
      AtBatResult.homeRun,
      AtBatResult.groundOut,
      AtBatResult.flyOut,
      AtBatResult.foulFlyOut,
    ].contains(result);

    if (!needsDirection) {
      String defaultDir = '';
      _recordOrUpdateAtBat(
        result,
        direction: defaultDir,
        errorPlayerId: errorPlayerId,
      );
      return;
    }

    List<String> directions = [];
    String titleText = '';

    if (result == AtBatResult.singleHit ||
        result == AtBatResult.doubleHit ||
        result == AtBatResult.tripleHit) {
      directions = ['左', '中', '右', '投', '捕', '一', '二', '三', '遊'];
      titleText = '打球方向（外野／内野安打）を選択';
    } else if (result == AtBatResult.homeRun) {
      directions = ['左', '左中間', '中', '右中間', '右'];
      titleText = '本塁打の方向を選択';
    } else if (result == AtBatResult.groundOut) {
      directions = ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'];
      titleText = 'ゴロの方向を選択';
    } else if (result == AtBatResult.flyOut ||
        result == AtBatResult.foulFlyOut) {
      directions = ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'];
      titleText = result == AtBatResult.foulFlyOut
          ? 'ファウルフライ（邪飛）の捕球位置'
          : 'フライ・ライナーの捕球位置';
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(titleText, style: const TextStyle(fontSize: 16)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: directions.map((dir) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade900,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if ((result == AtBatResult.singleHit ||
                            result == AtBatResult.doubleHit ||
                            result == AtBatResult.tripleHit ||
                            result == AtBatResult.homeRun) &&
                        runners.isNotEmpty) {
                      _promptHitWithRunnersDialog(result, dir);
                    } else {
                      _recordOrUpdateAtBat(
                        result,
                        direction: dir,
                        errorPlayerId: errorPlayerId,
                      );
                    }
                  },
                  child: Text(
                    dir,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _promptStrikeoutDialog() {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('三振の種別を選択'),
        content: const Text('この三振は通常の三振（アウト）ですか？それとも振り逃げ（出塁）ですか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _recordOrUpdateAtBat(AtBatResult.strikeoutSafe, direction: '');
            },
            child: const Text(
              '振り逃げ (出塁)',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _recordOrUpdateAtBat(AtBatResult.strikeout, direction: '');
            },
            child: const Text('通常の三振 (1アウト)'),
          ),
        ],
      ),
    );
  }

  void _handleGroundOut() {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。これ以上アウトになる打席は入力できません。');
      return;
    }

    if (runners.isEmpty) {
      _promptDirectionAndRecord(AtBatResult.groundOut);
      return;
    }

    String? new1st;
    String? new2nd = runners.runner1st;
    String? new3rd = runners.runner2nd;
    int runs = (runners.runner3rd != null) ? 1 : 0;
    int rbi = runs;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.sports_baseball, color: Colors.brown),
              SizedBox(width: 8),
              Text('ゴロアウト時の走者状況'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '打者はアウト（1アウト加算）。走者の進塁・生還を選択してください：',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text(
                        '走者進塁なし (残塁)',
                        style: TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      onPressed: () {
                        setDState(() {
                          runs = 0;
                          rbi = 0;
                          new1st = runners.runner1st;
                          new2nd = runners.runner2nd;
                          new3rd = runners.runner3rd;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text(
                        '進塁打 (全走者1つ進む)',
                        style: TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.brown.shade50,
                      onPressed: () {
                        setDState(() {
                          runs = (runners.runner3rd != null) ? 1 : 0;
                          rbi = runs;
                          new3rd = runners.runner2nd;
                          new2nd = runners.runner1st;
                          new1st = null;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 18),
                if (runners.runner3rd != null)
                  _runnerChoiceTile(
                    '3塁: ${_findPlayer(runners.runner3rd)?.name}',
                    ['本塁生還 (得点・打点1)', '3塁そのまま', '本塁憤死 (アウト)'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          runs = 1;
                          rbi = 1;
                          new3rd = runners.runner2nd;
                        } else if (val == 1) {
                          runs = 0;
                          rbi = 0;
                          new3rd = runners.runner3rd;
                        } else {
                          runs = 0;
                          rbi = 0;
                          new3rd = runners.runner2nd;
                        }
                      });
                    },
                    runs > 0 ? 0 : (new3rd == runners.runner3rd ? 1 : 2),
                  ),
                if (runners.runner2nd != null)
                  _runnerChoiceTile(
                    '2塁: ${_findPlayer(runners.runner2nd)?.name}',
                    ['3塁へ進塁', '2塁そのまま', '走塁死'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          new3rd = runners.runner2nd;
                        } else if (val == 1) {
                          new2nd = runners.runner2nd;
                          if (new3rd == runners.runner2nd) {
                            new3rd = null;
                          }
                        } else {
                          if (new3rd == runners.runner2nd) {
                            new3rd = null;
                          }
                          if (new2nd == runners.runner2nd) {
                            new2nd = null;
                          }
                        }
                      });
                    },
                    new3rd == runners.runner2nd
                        ? 0
                        : (new2nd == runners.runner2nd ? 1 : 2),
                  ),
                if (runners.runner1st != null)
                  _runnerChoiceTile(
                    '1塁: ${_findPlayer(runners.runner1st)?.name}',
                    ['2塁へ進塁', '1塁そのまま', '2塁封殺 (フォースアウト)'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          new2nd = runners.runner1st;
                        } else if (val == 1) {
                          new1st = runners.runner1st;
                          if (new2nd == runners.runner1st) {
                            new2nd = null;
                          }
                        } else {
                          if (new2nd == runners.runner1st) {
                            new2nd = null;
                          }
                          if (new1st == runners.runner1st) {
                            new1st = null;
                          }
                        }
                      });
                    },
                    new2nd == runners.runner1st
                        ? 0
                        : (new1st == runners.runner1st ? 1 : 2),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                final hasAdvanced =
                    (runs > 0) ||
                    (new3rd == runners.runner2nd) ||
                    (new2nd == runners.runner1st);
                final finalResult = hasAdvanced
                    ? AtBatResult.groundAdvance
                    : AtBatResult.groundOut;

                showDialog(
                  context: context,
                  builder: (dirCtx) => SimpleDialog(
                    title: const Text('ゴロの方向を選択'),
                    children: ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'].map(
                      (dir) {
                        return SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(dirCtx);
                            List<String> scoredIds = [];
                            if (runs > 0 && runners.runner3rd != null) {
                              scoredIds.add(runners.runner3rd!);
                            }
                            _applyCustomHitResult(
                              finalResult,
                              dir,
                              BaseRunners(
                                runner1st: new1st,
                                runner2nd: new2nd,
                                runner3rd: new3rd,
                              ),
                              runs,
                              rbi,
                              scoredIds,
                            );
                          },
                          child: Text(
                            dir,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                );
              },
              child: Text('確定 (1アウト${runs > 0 ? "・$runs点" : ""})'),
            ),
          ],
        ),
      ),
    );
  }

  void _promptErrorDialog() {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('エラー（敵失）した守備選手を選択'),
        children: [
          ...defendingPlayers.map((b) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                _promptDirectionAndRecord(
                  AtBatResult.error,
                  errorPlayerId: b.id,
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      b.position,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    b.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _promptDirectionAndRecord(AtBatResult.error);
            },
            child: const Text(
              '選手を指定せずに記録',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _promptPickoffDialog() {
    if (outs >= 3) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }
    if (runners.isEmpty) {
      _showRuleWarning('⚠️ 走者がいないため、牽制死・走塁死は発生しません。');
      return;
    }

    List<MapEntry<String, String>> onBase = [];
    if (runners.runner1st != null) {
      onBase.add(MapEntry('1塁', runners.runner1st!));
    }
    if (runners.runner2nd != null) {
      onBase.add(MapEntry('2塁', runners.runner2nd!));
    }
    if (runners.runner3rd != null) {
      onBase.add(MapEntry('3塁', runners.runner3rd!));
    }

    if (onBase.length == 1) {
      _applyPickoff(onBase.first.key, onBase.first.value);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('アウトになった走者を選択'),
        children: onBase.map((entry) {
          final b = _findPlayer(entry.value);
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _applyPickoff(entry.key, entry.value);
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${b?.name} (${b?.position})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _applyPickoff(String base, String runnerId) {
    if (outs >= 3) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }
    final player = _findPlayer(runnerId);
    _recordBaserunningEvent(
      '走塁死 (${player?.name ?? ""} $base)',
      runners.without(runnerId),
      batterId: currentBatters[currentBatterIndex].id,
      runnerId: runnerId,
    );
  }

  void _promptSacrificeHit() {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('すでに3アウトです。');
      return;
    }
    if (runners.isEmpty) {
      _showRuleWarning('⚠️ 走者がいない場面での犠打（送りバント）は記録できません。');
      return;
    }

    String? new1st;
    String? new2nd = runners.runner1st;
    String? new3rd = runners.runner2nd;
    int runs = (runners.runner3rd != null) ? 1 : 0;
    int rbi = runs;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text('犠打（バント）の進塁確認'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '打者はアウトになります。各走者の進塁先を選んでください：',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                if (runners.runner3rd != null)
                  _runnerChoiceTile(
                    '3塁: ${_findPlayer(runners.runner3rd)?.name}',
                    ['本塁生還 (得点)', '3塁そのまま', '走塁死'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          runs = 1;
                          rbi = 1;
                          new3rd = null;
                        } else if (val == 1) {
                          runs = 0;
                          rbi = 0;
                          new3rd = runners.runner3rd;
                        } else {
                          runs = 0;
                          rbi = 0;
                          new3rd = null;
                        }
                      });
                    },
                    runs > 0 ? 0 : (new3rd != null ? 1 : 2),
                  ),
                if (runners.runner2nd != null)
                  _runnerChoiceTile(
                    '2塁: ${_findPlayer(runners.runner2nd)?.name}',
                    ['3塁へ進塁', '2塁そのまま', '走塁死'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          new3rd = runners.runner2nd;
                        } else if (val == 1) {
                          new2nd = runners.runner2nd;
                          if (new3rd == runners.runner2nd) {
                            new3rd = null;
                          }
                        } else {
                          if (new3rd == runners.runner2nd) {
                            new3rd = null;
                          }
                          new2nd = null;
                        }
                      });
                    },
                    new3rd == runners.runner2nd
                        ? 0
                        : (new2nd == runners.runner2nd ? 1 : 2),
                  ),
                if (runners.runner1st != null)
                  _runnerChoiceTile(
                    '1塁: ${_findPlayer(runners.runner1st)?.name}',
                    ['2塁へ進塁', '1塁そのまま', '走塁死'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          new2nd = runners.runner1st;
                        } else if (val == 1) {
                          new1st = runners.runner1st;
                          if (new2nd == runners.runner1st) {
                            new2nd = null;
                          }
                        } else {
                          if (new2nd == runners.runner1st) {
                            new2nd = null;
                          }
                          new1st = null;
                        }
                      });
                    },
                    new2nd == runners.runner1st
                        ? 0
                        : (new1st == runners.runner1st ? 1 : 2),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                List<String> scoredIds = [];
                if (runs > 0 && runners.runner3rd != null) {
                  scoredIds.add(runners.runner3rd!);
                }
                _applyCustomHitResult(
                  AtBatResult.sacrificeHit,
                  '投',
                  BaseRunners(
                    runner1st: new1st,
                    runner2nd: new2nd,
                    runner3rd: new3rd,
                  ),
                  runs,
                  rbi,
                  scoredIds,
                );
              },
              child: const Text('確定 (1アウト)'),
            ),
          ],
        ),
      ),
    );
  }

  void _promptSacrificeFly() {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }
    if (outs >= 2 && activeEvent == null) {
      _showRuleWarning('2アウトの場面で犠牲フライ・フライ進塁は記録できません。');
      return;
    }
    if (runners.isEmpty) {
      _showRuleWarning('⚠️ 走者がいない場面でのフライ進塁は発生しません。');
      return;
    }

    int runs = (runners.runner3rd != null) ? 1 : 0;
    int rbi = runs;
    String? new3rd = runners.runner2nd;
    String? new2nd = runners.runner1st;
    String? new1st;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.flight_takeoff, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                runners.runner3rd != null ? '犠飛（犠牲フライ）の確認' : 'フライ進塁（タッチアップ）の確認',
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: runs > 0
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        runs > 0 ? Icons.check_circle : Icons.info_outline,
                        color: runs > 0 ? Colors.green : Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          runs > 0
                              ? '3塁走者生還により【犠牲フライ】（打点1・打数免除）として記録されます。'
                              : '生還走者がいないため【飛球進塁打】（打数カウントあり）として記録されます。',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: runs > 0
                                ? Colors.green.shade900
                                : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '各走者の進塁・残塁状況：',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                if (runners.runner3rd != null)
                  _runnerChoiceTile(
                    '3塁: ${_findPlayer(runners.runner3rd)?.name}',
                    ['本塁生還 (得点)', '3塁そのまま', '走塁死'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          runs = 1;
                          rbi = 1;
                          new3rd = runners.runner2nd;
                        } else if (val == 1) {
                          runs = 0;
                          rbi = 0;
                          new3rd = runners.runner3rd;
                        } else {
                          runs = 0;
                          rbi = 0;
                          new3rd = runners.runner2nd;
                        }
                      });
                    },
                    runs > 0 ? 0 : (new3rd == runners.runner3rd ? 1 : 2),
                  ),
                if (runners.runner2nd != null)
                  _runnerChoiceTile(
                    '2塁: ${_findPlayer(runners.runner2nd)?.name}',
                    ['3塁へタッチアップ', '2塁そのまま', '走塁死'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          new3rd = runners.runner2nd;
                        } else if (val == 1) {
                          new2nd = runners.runner2nd;
                          if (new3rd == runners.runner2nd) {
                            new3rd = null;
                          }
                        } else {
                          if (new3rd == runners.runner2nd) {
                            new3rd = null;
                          }
                          if (new2nd == runners.runner2nd) {
                            new2nd = null;
                          }
                        }
                      });
                    },
                    new3rd == runners.runner2nd
                        ? 0
                        : (new2nd == runners.runner2nd ? 1 : 2),
                  ),
                if (runners.runner1st != null)
                  _runnerChoiceTile(
                    '1塁: ${_findPlayer(runners.runner1st)?.name}',
                    ['2塁へタッチアップ', '1塁そのまま', '走塁死'],
                    (val) {
                      setDState(() {
                        if (val == 0) {
                          new2nd = runners.runner1st;
                        } else if (val == 1) {
                          new1st = runners.runner1st;
                          if (new2nd == runners.runner1st) {
                            new2nd = null;
                          }
                        } else {
                          if (new2nd == runners.runner1st) {
                            new2nd = null;
                          }
                          if (new1st == runners.runner1st) {
                            new1st = null;
                          }
                        }
                      });
                    },
                    new2nd == runners.runner1st
                        ? 0
                        : (new1st == runners.runner1st ? 1 : 2),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                final finalResult = (runs > 0)
                    ? AtBatResult.sacrificeFly
                    : AtBatResult.flyAdvance;

                showDialog(
                  context: context,
                  builder: (dirCtx) => SimpleDialog(
                    title: const Text('フライの方向を選択'),
                    children: ['左', '中', '右'].map((dir) {
                      return SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(dirCtx);
                          List<String> scoredIds = [];
                          if (runs > 0 && runners.runner3rd != null) {
                            scoredIds.add(runners.runner3rd!);
                          }
                          _applyCustomHitResult(
                            finalResult,
                            dir,
                            BaseRunners(
                              runner1st: new1st,
                              runner2nd: new2nd,
                              runner3rd: new3rd,
                            ),
                            runs,
                            rbi,
                            scoredIds,
                          );
                        },
                        child: Text(
                          dir,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              child: Text('確定 (1アウト${runs > 0 ? "・$runs得点" : ""})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _runnerChoiceTile(
    String title,
    List<String> options,
    Function(int) onSelected,
    int currentIdx,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SegmentedButton<int>(
            segments: options
                .asMap()
                .entries
                .map(
                  (e) => ButtonSegment(
                    value: e.key,
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
            selected: {currentIdx},
            onSelectionChanged: (selectedSet) {
              onSelected(selectedSet.first);
            },
          ),
        ],
      ),
    );
  }

  void _handleSteal() {
    if (runners.isEmpty) {
      _showRuleWarning('⚠️ 走者がいないため、盗塁はできません。');
      return;
    }
    List<MapEntry<String, String>> onBase = [];
    if (runners.runner1st != null) {
      onBase.add(
        MapEntry(
          '1塁走者 (${_findPlayer(runners.runner1st)?.name})',
          runners.runner1st!,
        ),
      );
    }
    if (runners.runner2nd != null) {
      onBase.add(
        MapEntry(
          '2塁走者 (${_findPlayer(runners.runner2nd)?.name})',
          runners.runner2nd!,
        ),
      );
    }
    if (runners.runner3rd != null) {
      onBase.add(
        MapEntry(
          '3塁走者 (${_findPlayer(runners.runner3rd)?.name})',
          runners.runner3rd!,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('盗塁した走者を選択'),
        children: onBase.map((entry) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _executeStealForRunner(entry.value);
            },
            child: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 盗塁成功を記録する。
  ///
  /// 盗塁した走者と、その後ろにいる走者がそれぞれ1つずつ進塁する
  /// （重盗を想定した挙動）ものとして扱う。
  void _executeStealForRunner(String runnerId) {
    final runnerName = _findPlayer(runnerId)?.name ?? '';
    BaseRunners nextRunners;
    int calcRuns = 0;
    final scoredIds = <String>[];

    if (runnerId == runners.runner3rd) {
      // 本盗。3塁走者が生還し、後続はひとつずつ進む。
      calcRuns++;
      scoredIds.add(runnerId);
      nextRunners = BaseRunners(
        runner2nd: runners.runner1st,
        runner3rd: runners.runner2nd,
      );
    } else if (runnerId == runners.runner2nd) {
      nextRunners = BaseRunners(
        runner2nd: runners.runner1st,
        runner3rd: runners.runner2nd,
      );
    } else {
      nextRunners = BaseRunners(
        runner2nd: runners.runner1st,
        runner3rd: runners.runner3rd,
      );
    }

    _recordBaserunningEvent(
      '盗塁成功 ($runnerName)',
      nextRunners,
      isSteal: true,
      batterId: currentBatters[currentBatterIndex].id,
      runnerId: runnerId,
      runs: calcRuns,
      scoredIds: scoredIds,
    );
  }

  void _promptAdvanceRunnersDialog(String eventName) {
    if (runners.isEmpty) {
      _showRuleWarning('⚠️ 走者がいないため発生しません。');
      return;
    }

    int r3Choice = 1;
    int r2Choice = 2;
    int r1Choice = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: Text('$eventName 時の各走者の進塁先設定'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '各走者の進塁先を個別に選んでください：',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                if (runners.runner3rd != null)
                  _runnerChoiceTile(
                    '3塁: ${_findPlayer(runners.runner3rd)?.name}',
                    ['本塁生還 (得点)', '3塁そのまま'],
                    (val) {
                      setDState(() {
                        r3Choice = val;
                      });
                    },
                    r3Choice,
                  ),
                if (runners.runner2nd != null)
                  _runnerChoiceTile(
                    '2塁: ${_findPlayer(runners.runner2nd)?.name}',
                    ['3塁へ進塁', '2塁そのまま'],
                    (val) {
                      setDState(() {
                        r2Choice = val;
                      });
                    },
                    r2Choice,
                  ),
                if (runners.runner1st != null)
                  _runnerChoiceTile(
                    '1塁: ${_findPlayer(runners.runner1st)?.name}',
                    ['2塁へ進塁', '1塁そのまま'],
                    (val) {
                      setDState(() {
                        r1Choice = val;
                      });
                    },
                    r1Choice,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);

                int calcRuns = 0;
                List<String> scoredIds = [];
                String? original1st = runners.runner1st;
                String? original2nd = runners.runner2nd;
                String? original3rd = runners.runner3rd;

                String? next3rd;
                String? next2nd;
                String? next1st;

                if (original1st != null) {
                  if (r1Choice == 0) {
                    next2nd = original1st;
                  } else {
                    next1st = original1st;
                  }
                }

                if (original2nd != null) {
                  if (r2Choice == 0) {
                    next3rd = original2nd;
                  } else {
                    if (next2nd == null) {
                      next2nd = original2nd;
                    } else {
                      next3rd = original2nd;
                    }
                  }
                }

                if (original3rd != null) {
                  if (r3Choice == 0) {
                    calcRuns++;
                    scoredIds.add(original3rd);
                  } else {
                    if (next3rd == null) {
                      next3rd = original3rd;
                    } else if (next2nd == null) {
                      next2nd = next3rd;
                      next3rd = original3rd;
                    } else {
                      next1st ??= next2nd;
                      next2nd = next3rd;
                      next3rd = original3rd;
                    }
                  }
                }

                BaseRunners nextR = BaseRunners(
                  runner1st: next1st,
                  runner2nd: next2nd,
                  runner3rd: next3rd,
                );
                _recordBaserunningEvent(
                  eventName,
                  nextR,
                  runs: calcRuns,
                  scoredIds: scoredIds,
                );
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleWildPitch() {
    _promptAdvanceRunnersDialog('ワイルドピッチ (WP)');
  }

  void _handlePassedBall() {
    _promptAdvanceRunnersDialog('パスボール (PB)');
  }

  Player? _getPlayerByPosition(String pos) {
    return defendingPlayers.where((p) => p.position == pos).firstOrNull;
  }

  void _showGameHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.green),
            SizedBox(width: 8),
            Text('試合イベント履歴（タイムライン）'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _state.events.isEmpty
              ? const Text(
                  'まだイベントが記録されていません。',
                  style: TextStyle(color: Colors.grey),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _state.events.length,
                  itemBuilder: (context, idx) {
                    final ev = _state.events[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: ev.isTop
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                          child: Text(
                            '${ev.inning}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        title: Text(
                          '${ev.isTop ? "表" : "裏"} | ${ev.description}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '得点: ${ev.runs}点 | アウト増: ${ev.addedOuts}'
                          '${ev.isIgnored ? " ※3アウト後のため集計対象外" : ""}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                          tooltip: 'このイベントを削除',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteEvent(ev.eventId);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _showGameHistoryDialog,
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
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _selectedTabIndex == 0
          ? _buildInputTab()
          : _buildUnifiedScoreAndStatsTab(),
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

  // ================= 1. 盤面入力タブ =================
  Widget _buildInputTab() {
    int displayInnings = scoresTop.length > totalInningsConfig
        ? scoresTop.length
        : totalInningsConfig;
    String currentAttackingTeamName = isTop ? teamNameTop : teamNameBottom;
    final currentEv = activeEvent;
    int maxCycle = maxCycleInCurrentInning;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2E14),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _boardTeam(teamNameTop, totalScoreTop, isTop),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _boardTeam(teamNameBottom, totalScoreBottom, !isTop),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 4),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: const Text(
                          '回移動▶',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...List.generate(displayInnings, (i) {
                        int inn = i + 1;
                        bool isCurrentTop = (inning == inn && isTop);
                        bool isCurrentBottom = (inning == inn && !isTop);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: (inning == inn)
                                  ? Colors.amberAccent
                                  : Colors.white24,
                              width: (inning == inn) ? 1.5 : 0.8,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                color: Colors.black26,
                                alignment: Alignment.center,
                                child: Text(
                                  '$inn回',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _jumpToInning(inn, true);
                                },
                                child: Container(
                                  width: 32,
                                  height: 22,
                                  color: isCurrentTop
                                      ? Colors.amber.shade700
                                      : Colors.white12,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${scoresTop.length > i ? scoresTop[i] : 0}',
                                    style: TextStyle(
                                      color: isCurrentTop
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: isCurrentTop
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _jumpToInning(inn, false);
                                },
                                child: Container(
                                  width: 32,
                                  height: 22,
                                  color: isCurrentBottom
                                      ? Colors.amber.shade700
                                      : Colors.black12,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${scoresBottom.length > i ? scoresBottom[i] : 0}',
                                    style: TextStyle(
                                      color: isCurrentBottom
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: isCurrentBottom
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: currentEv != null
                  ? Colors.blue.shade50
                  : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: currentEv != null
                    ? Colors.blue.shade300
                    : Colors.amber.shade400,
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$inning回 ${isTop ? "表" : "裏"} ($currentAttackingTeamName 攻)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currentBatterIndex + 1}番 [${currentBatters[currentBatterIndex].position}] ${currentBatters[currentBatterIndex].name}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (currentEv != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'この打席を削除',
                            onPressed: _deleteCurrentPlateEvent,
                          ),
                        TextButton.icon(
                          onPressed: _showJumpBatterDialog,
                          icon: const Icon(Icons.touch_app, size: 14),
                          label: const Text(
                            '打者一覧',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.sports, size: 13, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      '対戦投手: [${activePitcher.position}] ${activePitcher.name}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${activePitcher.stats.pitching.inningsPitched}回 ${activePitcher.stats.pitching.strikeouts}K ${activePitcher.stats.pitching.runsAllowed}失点)',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _promptChangePitcherDialog,
                      icon: const Icon(Icons.swap_calls, size: 12),
                      label: const Text('投手交代', style: TextStyle(fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ),
                        minimumSize: const Size(50, 24),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'イニング巡目:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...List.generate(maxCycle + 1, (cIdx) {
                        bool isCur = _currentCycle == cIdx;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ChoiceChip(
                            label: Text(
                              '第${cIdx + 1}巡目',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCur
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isCur,
                            selectedColor: Colors.blue.shade200,
                            onSelected: (_) {
                              setState(() {
                                _currentCycle = cIdx;
                                _syncCurrentView();
                              });
                            },
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 12),
                        label: Text(
                          '第${maxCycle + 2}巡目を新設',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.purple.shade50,
                        onPressed: () {
                          setState(() {
                            _currentCycle = maxCycle + 1;
                            currentBatterIndex = 0;
                            _syncCurrentView();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: currentBatters.asMap().entries.map((entry) {
                int idx = entry.key;
                Player b = entry.value;
                bool isCurrent = idx == currentBatterIndex;
                final evInThisCycle = _gameEvents
                    .where(
                      (e) =>
                          !e.isBaserunningEvent &&
                          e.inning == inning &&
                          e.isTop == isTop &&
                          e.cycleIndex == _currentCycle &&
                          e.batterIndex == idx,
                    )
                    .firstOrNull;

                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: ChoiceChip(
                    avatar: evInThisCycle != null
                        ? CircleAvatar(
                            radius: 7,
                            backgroundColor:
                                evInThisCycle.result != null &&
                                    evInThisCycle.result!.isHit
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            child: const Text(
                              '✓',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                    label: Text(
                      '${idx + 1}.${b.name}${evInThisCycle != null ? " [${evInThisCycle.displayShortLabel}]" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isCurrent,
                    selectedColor: Colors.amber.shade300,
                    onSelected: (_) {
                      _jumpToBatter(idx);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OUT カウント',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _clickableOutLamp(1),
                          const SizedBox(width: 8),
                          _clickableOutLamp(2),
                        ],
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _changeInning();
                          });
                        },
                        icon: const Icon(Icons.swap_horiz, size: 14),
                        label: const Text(
                          'チェンジ',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                          minimumSize: const Size(50, 24),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 175,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white70,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          left: 10,
                          child: _posTag('左', _getPlayerByPosition('左')),
                        ),
                        Positioned(
                          top: 2,
                          child: _posTag('中', _getPlayerByPosition('中')),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: _posTag('右', _getPlayerByPosition('右')),
                        ),
                        Positioned(
                          top: 36,
                          left: 26,
                          child: _posTag('遊', _getPlayerByPosition('遊')),
                        ),
                        Positioned(
                          top: 36,
                          right: 26,
                          child: _posTag('二', _getPlayerByPosition('二')),
                        ),
                        Positioned(
                          bottom: 24,
                          left: 8,
                          child: _posTag('三', _getPlayerByPosition('三')),
                        ),
                        Positioned(
                          bottom: 24,
                          right: 8,
                          child: _posTag('一', _getPlayerByPosition('一')),
                        ),
                        Positioned(child: _posTag('投', activePitcher)),
                        Positioned(
                          bottom: 2,
                          child: _posTag('捕', _getPlayerByPosition('捕')),
                        ),

                        Positioned(
                          top: 14,
                          child: _baseNode('2塁', runners.runner2nd, () {}),
                        ),
                        Positioned(
                          left: 14,
                          child: _baseNode('3塁', runners.runner3rd, () {}),
                        ),
                        Positioned(
                          right: 14,
                          child: _baseNode('1塁', runners.runner1st, () {}),
                        ),
                        const Positioned(
                          bottom: 14,
                          child: Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_run,
                  size: 15,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                const Text(
                  '走塁:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSteal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      '盗塁',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleWildPitch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      'WP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handlePassedBall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      'PB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _promptPickoffDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.red.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      '走塁死',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          _buildCategorizedActionButtons(),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: _saveAndExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.save),
              label: const Text(
                '保存して一覧に戻る',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _posTag(String posLabel, Player? player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$posLabel:${player?.name ?? ""}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategorizedActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryHeader('安打', Colors.green.shade800),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                '単打 (1H)',
                Colors.white,
                () => _promptDirectionAndRecord(AtBatResult.singleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '二塁打 (2B)',
                Colors.white,
                () => _promptDirectionAndRecord(AtBatResult.doubleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '三塁打 (3B)',
                Colors.white,
                () => _promptDirectionAndRecord(AtBatResult.tripleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '本塁打 (HR)',
                Colors.green.shade50,
                () => _promptDirectionAndRecord(AtBatResult.homeRun),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _categoryHeader('四死球・出塁', Colors.teal.shade800),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                '四球 (BB)',
                Colors.white,
                () => _promptDirectionAndRecord(AtBatResult.walk),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '死球 (HBP)',
                Colors.white,
                () => _promptDirectionAndRecord(AtBatResult.hitByPitch),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn('敵失 (エラー)', Colors.white, _promptErrorDialog),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _categoryHeader('犠打・犠飛・進塁', Colors.indigo.shade800),
        Row(
          children: [
            Expanded(
              child: _actionBtn('犠打 (バント)', Colors.white, _promptSacrificeHit),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                runners.runner3rd != null ? '犠飛 (犠牲フライ)' : 'フライ進塁',
                Colors.white,
                _promptSacrificeFly,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _categoryHeader('凡退・アウト', Colors.red.shade800),
        Row(
          children: [
            Expanded(child: _actionBtn('ゴロ凡退', Colors.white, _handleGroundOut)),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn(
                '飛球凡退',
                Colors.white,
                () => _promptDirectionAndRecord(AtBatResult.flyOut),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn(
                '邪飛',
                Colors.white,
                () => _promptDirectionAndRecord(AtBatResult.foulFlyOut),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn('三振', Colors.white, _promptStrikeoutDialog),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn(
                '併殺 (DP)',
                Colors.red.shade50,
                () => _promptDirectionAndRecord(AtBatResult.doublePlay),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryHeader(String title, Color color) {
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

  void _showJumpBatterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${isTop ? teamNameTop : teamNameBottom} 打者選択'),
        children: currentBatters.asMap().entries.map((entry) {
          int idx = entry.key;
          Player b = entry.value;
          bool isSelected = idx == currentBatterIndex;
          final matchEvs = b.stats.appearances
              .where((p) => p.inning == inning && p.isTop == isTop)
              .toList();

          return SimpleDialogOption(
            onPressed: () {
              _jumpToBatter(idx);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected
                      ? Colors.amber.shade800
                      : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  b.name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${b.position})',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (matchEvs.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${matchEvs.length}打席',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.green, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= 2. スコア・個人成績タブ =================
  Widget _buildUnifiedScoreAndStatsTab() {
    int displayInnings = scoresTop.length > totalInningsConfig
        ? scoresTop.length
        : totalInningsConfig;
    List<Player> activeBatters = (_scoreTabTeamIndex == 0)
        ? playersTop
        : playersBottom;
    List<Player> activePitchers = (_scoreTabTeamIndex == 0)
        ? playersTop
        : playersBottom;
    String activeTeamName = (_scoreTabTeamIndex == 0)
        ? teamNameTop
        : teamNameBottom;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ラインスコア',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<int>(
                value: totalInningsConfig,
                underline: const SizedBox(),
                items: [5, 7, 9]
                    .map(
                      (val) =>
                          DropdownMenuItem(value: val, child: Text('$val回制')),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      totalInningsConfig = val;
                      _rebuildGameState();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(32),
                columnWidths: const {0: FixedColumnWidth(110)},
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.8,
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFF0D2E14)),
                    children: [
                      _th('チーム (移動)'),
                      ...List.generate(displayInnings, (i) => _th('${i + 1}')),
                      _th('R', isAccent: true),
                      _th('H'),
                      _th('E'),
                    ],
                  ),
                  TableRow(
                    decoration: BoxDecoration(
                      color: isTop ? Colors.green.shade50 : Colors.white,
                    ),
                    children: [
                      _td(teamNameTop, isBold: true),
                      ...List.generate(displayInnings, (i) {
                        int inn = i + 1;
                        bool isCurrent = (inning == inn && isTop);
                        return InkWell(
                          onTap: () {
                            _jumpToInning(inn, true);
                            setState(() => _selectedTabIndex = 0);
                          },
                          child: Container(
                            color: isCurrent
                                ? Colors.amber.shade200
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: Text(
                              '${scoresTop.length > i ? scoresTop[i] : 0}',
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                      _td(
                        '$totalScoreTop',
                        isBold: true,
                        textColor: Colors.green.shade900,
                      ),
                      _td('$totalHitsTop', isBold: true),
                      _td('$errorsTop'),
                    ],
                  ),
                  TableRow(
                    decoration: BoxDecoration(
                      color: !isTop ? Colors.green.shade50 : Colors.white,
                    ),
                    children: [
                      _td(teamNameBottom, isBold: true),
                      ...List.generate(displayInnings, (i) {
                        int inn = i + 1;
                        bool isCurrent = (inning == inn && !isTop);
                        return InkWell(
                          onTap: () {
                            _jumpToInning(inn, false);
                            setState(() => _selectedTabIndex = 0);
                          },
                          child: Container(
                            color: isCurrent
                                ? Colors.amber.shade200
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: Text(
                              '${scoresBottom.length > i ? scoresBottom[i] : 0}',
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                      _td(
                        '$totalScoreBottom',
                        isBold: true,
                        textColor: Colors.green.shade900,
                      ),
                      _td('$totalHitsBottom', isBold: true),
                      _td('$errorsBottom'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(teamNameTop)),
                ButtonSegment(value: 1, label: Text(teamNameBottom)),
              ],
              selected: {_scoreTabTeamIndex},
              onSelectionChanged: (set) =>
                  setState(() => _scoreTabTeamIndex = set.first),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeTeamName 打者成績',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '安打計: ${activeBatters.fold(0, (s, b) => s + b.stats.hits)}本',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(38),
                columnWidths: const {
                  0: FixedColumnWidth(28),
                  1: FixedColumnWidth(80),
                },
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.8,
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: (_scoreTabTeamIndex == 0)
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF2E7D32),
                    ),
                    children: [
                      _th('順'),
                      _th('選手名'),
                      ...List.generate(displayInnings, (i) => _th('${i + 1}回')),
                      _th('打席'),
                      _th('打数'),
                      _th('安打', isAccent: true),
                      _th('２塁'),
                      _th('３塁'),
                      _th('本塁', isAccent: true),
                      _th('打点', isAccent: true),
                      _th('得点'),
                      _th('盗塁', isAccent: true),
                      _th('四球'),
                      _th('死球'),
                      _th('犠打'),
                      _th('犠飛'),
                      _th('三振'),
                      _th('敵失'),
                      _th('打率', isAccent: true),
                      _th('失策', isAccent: true),
                    ],
                  ),
                  ...activeBatters.asMap().entries.map((entry) {
                    int bIdx = entry.key;
                    Player b = entry.value;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: (bIdx % 2 == 0)
                            ? Colors.white
                            : Colors.grey.shade50,
                      ),
                      children: [
                        _td('${bIdx + 1}', isBold: true),
                        _td('${b.name} (${b.position})', isBold: true),
                        ...List.generate(displayInnings, (innIdx) {
                          int currentInn = innIdx + 1;
                          final pas = b.stats.appearances
                              .where((p) => p.inning == currentInn)
                              .toList();
                          if (pas.isEmpty) {
                            return _td('-');
                          }
                          bool hasHit = pas.any(
                            (p) => p.result != null && p.result!.isHit,
                          );
                          String text = pas
                              .map(
                                (p) =>
                                    '${p.displayShortLabel}${p.rbi > 0 ? " [${p.rbi}]" : ""}',
                              )
                              .join('\n');

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            color: hasHit
                                ? Colors.blue.shade50
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: hasHit
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: hasHit
                                    ? Colors.blue.shade900
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }),
                        _td('${b.stats.pa}'),
                        _td('${b.stats.ab}'),
                        _td(
                          '${b.stats.hits}',
                          isBold: true,
                          textColor: Colors.blue.shade900,
                        ),
                        _td('${b.stats.doubles}'),
                        _td('${b.stats.triples}'),
                        _td(
                          '${b.stats.hr}',
                          isBold: b.stats.hr > 0,
                          textColor: b.stats.hr > 0 ? Colors.purple.shade800 : null,
                        ),
                        _td(
                          '${b.stats.rbi}',
                          isBold: b.stats.rbi > 0,
                          textColor: b.stats.rbi > 0 ? Colors.red.shade800 : null,
                        ),
                        _td('${b.stats.runsScored}'),
                        _td(
                          '${b.stats.sb}',
                          isBold: b.stats.sb > 0,
                          textColor: Colors.teal.shade800,
                        ),
                        _td('${b.stats.bb}'),
                        _td('${b.stats.hbp}'),
                        _td('${b.stats.sh}'),
                        _td('${b.stats.sf}'),
                        _td('${b.stats.so}'),
                        _td('${b.stats.roe}'),
                        _td(
                          b.stats.battingAverage,
                          isBold: true,
                          textColor: Colors.green.shade900,
                        ),
                        _td(
                          '${b.stats.errorsCommitted}',
                          textColor: b.stats.errorsCommitted > 0
                              ? Colors.red.shade800
                              : null,
                        ),
                      ],
                    );
                  }),
                  // チーム合計行
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFE8F5E9)),
                    children: [
                      _td('計', isBold: true),
                      _td('-', isBold: true),
                      ...List.generate(displayInnings, (innIdx) {
                        int currentInn = innIdx + 1;
                        int innRuns = isTop
                            ? (scoresTop.length >= currentInn
                                  ? scoresTop[currentInn - 1]
                                  : 0)
                            : (scoresBottom.length >= currentInn
                                  ? scoresBottom[currentInn - 1]
                                  : 0);
                        return _td(
                          innRuns > 0 ? '$innRuns' : '-',
                          isBold: true,
                        );
                      }),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.pa)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.ab)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.hits)}',
                        isBold: true,
                        textColor: Colors.blue.shade900,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.doubles)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.triples)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.hr)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.rbi)}',
                        isBold: true,
                        textColor: Colors.red.shade800,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.runsScored)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.sb)}',
                        isBold: true,
                        textColor: Colors.teal.shade800,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.bb)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.hbp)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.sh)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.sf)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.so)}',
                        isBold: true,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.roe)}',
                        isBold: true,
                      ),
                      _td(
                        _calculateTeamBattingAverage(activeBatters),
                        isBold: true,
                        textColor: Colors.green.shade900,
                      ),
                      _td(
                        '${activeBatters.fold(0, (s, b) => s + b.stats.errorsCommitted)}',
                        isBold: true,
                        textColor: Colors.red.shade800,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeTeamName 投手成績',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '※7回制防御率換算',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(44),
                columnWidths: const {0: FixedColumnWidth(90)},
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 0.8,
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: (_scoreTabTeamIndex == 0)
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF2E7D32),
                    ),
                    children: [
                      _th('投手名'),
                      _th('回数', isAccent: true),
                      _th('打者'),
                      _th('安打'),
                      _th('本塁'),
                      _th('三振', isAccent: true),
                      _th('四球'),
                      _th('死球'),
                      _th('失点'),
                      _th('自責', isAccent: true),
                      _th('防御率', isAccent: true),
                    ],
                  ),
                  ...activePitchers
                      .where(
                        (p) => p.stats.pitchingEvents.isNotEmpty || p.position == '投',
                      )
                      .map((p) {
                        final pStats = p.stats.pitching;
                        return TableRow(
                          children: [
                            _td('${p.name} (${p.position})', isBold: true),
                            _td(
                              pStats.inningsPitched,
                              isBold: true,
                              textColor: Colors.blue.shade900,
                            ),
                            _td('${pStats.battersFaced}'),
                            _td('${pStats.hitsAllowed}'),
                            _td('${pStats.hrAllowed}'),
                            _td(
                              '${pStats.strikeouts}',
                              isBold: true,
                              textColor: Colors.green.shade900,
                            ),
                            _td('${pStats.walks}'),
                            _td('${pStats.hitByPitch}'),
                            _td('${pStats.runsAllowed}'),
                            _td(
                              '${pStats.earnedRuns}',
                              isBold: true,
                              textColor: pStats.earnedRuns > 0
                                  ? Colors.red.shade800
                                  : null,
                            ),
                            _td(
                              pStats.era(),
                              isBold: true,
                              textColor: Colors.brown.shade900,
                            ),
                          ],
                        );
                      }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          ...activeBatters.asMap().entries.map((entry) {
            int idx = entry.key;
            Player b = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          b.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${b.position})',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '打率 ${b.stats.battingAverage}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () =>
                              _editBatterInfoDialog(activeBatters, idx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _statItem('打席', '${b.stats.pa}'),
                            _statItem('打数', '${b.stats.ab}'),
                            _statItem('安打', '${b.stats.hits}', isBold: true),
                            _statItem('2塁打', '${b.stats.doubles}'),
                            _statItem('3塁打', '${b.stats.triples}'),
                            _statItem('本塁打', '${b.stats.hr}', isBold: true),
                            _statItem(
                              '打点',
                              '${b.stats.rbi}',
                              textColor: Colors.red.shade800,
                            ),
                            _statItem('得点', '${b.stats.runsScored}'),
                            _statItem(
                              '盗塁',
                              '${b.stats.sb}',
                              isBold: b.stats.sb > 0,
                              textColor: Colors.teal.shade800,
                            ),
                            _statItem('四球', '${b.stats.bb}'),
                            _statItem('死球', '${b.stats.hbp}'),
                            _statItem('犠打', '${b.stats.sh}'),
                            _statItem('犠飛', '${b.stats.sf}'),
                            _statItem('三振', '${b.stats.so}'),
                            _statItem('敵失出塁', '${b.stats.roe}'),
                            _statItem(
                              '守備エラー',
                              '${b.stats.errorsCommitted}',
                              textColor: b.stats.errorsCommitted > 0
                                  ? Colors.red
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (b.stats.appearances.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: b.stats.appearances
                              .asMap()
                              .entries
                              .map((pEntry) {
                                final paIdx = pEntry.key;
                                final ResolvedEvent pa = pEntry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: ActionChip(
                                    avatar: CircleAvatar(
                                      radius: 7,
                                      backgroundColor:
                                          pa.result != null && pa.result!.isHit
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade600,
                                      child: Text(
                                        '${paIdx + 1}',
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    label: Text(
                                      '${pa.inning}回(${pa.displayShortLabel})${pa.rbi > 0 ? " [${pa.rbi}点]" : ""}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            pa.result != null &&
                                                pa.result!.isHit
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color:
                                            pa.result != null &&
                                                pa.result!.isHit
                                            ? Colors.blue.shade900
                                            : Colors.black87,
                                      ),
                                    ),
                                    backgroundColor:
                                        pa.result != null && pa.result!.isHit
                                        ? Colors.blue.shade50
                                        : Colors.grey.shade100,
                                    onPressed: () {
                                      _jumpToInning(pa.inning, pa.isTop);
                                      setState(() {
                                        _currentCycle = pa.cycleIndex;
                                        currentBatterIndex = pa.batterIndex;
                                        _selectedTabIndex = 0;
                                        _syncCurrentView();
                                      });
                                    },
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),

          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  activeBatters.add(
                    Player(
                      id: '${_scoreTabTeamIndex == 0 ? "t" : "b"}${activeBatters.length + 1}',
                      name: '選手${activeBatters.length + 1}',
                      position: '指',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: Text('$activeTeamName の打順を追加'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _calculateTeamBattingAverage(List<Player> batters) {
    int totalAb = batters.fold(0, (s, b) => s + b.stats.ab);
    int totalHits = batters.fold(0, (s, b) => s + b.stats.hits);
    if (totalAb == 0) {
      return '.---';
    }
    double avg = totalHits / totalAb;
    if (avg >= 1.0) {
      return '1.000';
    }
    return avg.toStringAsFixed(3).substring(1);
  }

  Widget _statItem(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 打者の氏名・守備位置を編集する。
  ///
  /// 得点や失策はイベントの再生結果から自動集計されるため、ここでは編集しない。
  void _editBatterInfoDialog(List<Player> list, int index) {
    final player = list[index];
    final nameCtrl = TextEditingController(text: player.name);
    final posCtrl = TextEditingController(text: player.position);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${index + 1}番打者の編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '選手名'),
            ),
            TextField(
              controller: posCtrl,
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
              Navigator.pop(ctx);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (nameCtrl.text.isNotEmpty) {
                  player.name = nameCtrl.text;
                }
                if (posCtrl.text.isNotEmpty) {
                  player.position = posCtrl.text;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      posCtrl.dispose();
    });
  }

  void _showSettingsDialog() {
    final topCtrl = TextEditingController(text: teamNameTop);
    final btmCtrl = TextEditingController(text: teamNameBottom);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('チーム設定・試合管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: topCtrl,
              decoration: const InputDecoration(labelText: '先攻チーム名'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: btmCtrl,
              decoration: const InputDecoration(labelText: '後攻チーム名'),
            ),
            const Divider(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showResetConfirmDialog();
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
              Navigator.pop(ctx);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                teamNameTop = topCtrl.text.isEmpty ? '先攻チーム' : topCtrl.text;
                teamNameBottom = btmCtrl.text.isEmpty ? '後攻チーム' : btmCtrl.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('リセットの確認'),
        content: const Text('現在のスコア、両チームの全打席結果、走者状況をすべて初期化しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                // イベントを消せば、成績はすべて再生結果として初期化される。
                _gameEvents.clear();
                _nextEventId = 1;
                inning = 1;
                isTop = true;
                outs = 0;
                runners = BaseRunners.empty;
                batterIndexTop = 0;
                batterIndexBottom = 0;
                cycleIndexTop = 0;
                cycleIndexBottom = 0;
                _rebuildGameState();
              });
              Navigator.pop(ctx);
            },
            child: const Text('リセット実行', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _boardTeam(String teamName, int score, bool isAttacking) {
    return Column(
      children: [
        Row(
          children: [
            if (isAttacking)
              const Icon(
                Icons.arrow_right,
                color: Colors.yellowAccent,
                size: 20,
              ),
            Text(
              teamName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$score',
          style: TextStyle(
            color: isAttacking ? Colors.amberAccent : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _clickableOutLamp(int targetOut) {
    bool isFilled = outs >= targetOut;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isFilled ? Colors.redAccent : Colors.grey.shade300,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }

  Widget _baseNode(String baseName, String? runnerId, VoidCallback onTap) {
    final runner = _findPlayer(runnerId);
    final isOn = runner != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isOn ? Colors.amberAccent : const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            baseName,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isOn ? Colors.black87 : Colors.black45,
            ),
          ),
          if (isOn)
            Text(
              runner.name,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed) {
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

  Widget _th(String text, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: isAccent ? Colors.amberAccent : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _td(String text, {bool isBold = false, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? Colors.black87,
        ),
      ),
    );
  }
}
