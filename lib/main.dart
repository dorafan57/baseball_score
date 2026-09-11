import 'package:flutter/material.dart';

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
      home: const MainScreen(),
    );
  }
}

enum AtBatResult {
  singleHit('単打', '安', true, true, 1),
  doubleHit('二塁打', '２', true, true, 2),
  tripleHit('三塁打', '３', true, true, 3),
  homeRun('本塁打', '本', true, true, 4),
  walk('四球', '四球', false, false, 0),
  hitByPitch('死球', '死球', false, false, 0),
  error('敵失', '失', true, false, 0),
  strikeout('三振', '三振', true, false, 0),
  strikeoutSafe('振逃出塁', '振逃', true, false, 0),
  groundOut('ゴロ', 'ゴ', true, false, 0),
  groundAdvance('ゴロ進塁', 'ゴ進', true, false, 0),
  flyOut('飛球', '飛', true, false, 0),
  foulFlyOut('邪飛', '邪飛', true, false, 0),
  flyAdvance('飛球進塁', '飛進', true, false, 0),
  sacrificeHit('犠打', '犠打', false, false, 0),
  sacrificeFly('犠飛', '犠飛', false, false, 0),
  doublePlay('併殺打', '併殺', true, false, 0);

  final String label;
  final String shortLabel;
  final bool isAtBat;
  final bool isHit;
  final int bases;
  const AtBatResult(
    this.label,
    this.shortLabel,
    this.isAtBat,
    this.isHit,
    this.bases,
  );
}

class BaseRunners {
  String? runner1st;
  String? runner2nd;
  String? runner3rd;

  BaseRunners({this.runner1st, this.runner2nd, this.runner3rd});

  bool get isEmpty =>
      runner1st == null && runner2nd == null && runner3rd == null;

  BaseRunners copy() => BaseRunners(
    runner1st: runner1st,
    runner2nd: runner2nd,
    runner3rd: runner3rd,
  );

  void removeRunner(String id) {
    if (runner1st == id) {
      runner1st = null;
    }
    if (runner2nd == id) {
      runner2nd = null;
    }
    if (runner3rd == id) {
      runner3rd = null;
    }
  }
}

class PlateEvent {
  int eventId;
  final String batterId;
  final int batterIndex;
  final String pitcherId;
  final int inning;
  final bool isTop;
  final int cycleIndex;
  AtBatResult result;
  String direction;
  int rbi;
  int runs;
  int earnedRuns;
  String? errorPlayerId;
  BaseRunners runnersBefore;
  int outsBefore;
  BaseRunners runnersAfter;
  int outsAfter;
  bool causedInningEnd;

  PlateEvent({
    required this.eventId,
    required this.batterId,
    required this.batterIndex,
    required this.pitcherId,
    required this.inning,
    required this.isTop,
    required this.cycleIndex,
    required this.result,
    required this.direction,
    required this.rbi,
    required this.runs,
    this.earnedRuns = 0,
    this.errorPlayerId,
    required this.runnersBefore,
    required this.outsBefore,
    required this.runnersAfter,
    required this.outsAfter,
    required this.causedInningEnd,
  });

  String get displayShortLabel {
    if (result == AtBatResult.singleHit ||
        result == AtBatResult.doubleHit ||
        result == AtBatResult.tripleHit) {
      return '$direction${result.shortLabel}';
    }
    if (result == AtBatResult.groundOut ||
        result == AtBatResult.flyOut ||
        result == AtBatResult.foulFlyOut) {
      return '$direction${result.shortLabel}';
    }
    return result.shortLabel;
  }
}

class PitcherStats {
  int outsRecorded = 0;
  int battersFaced = 0;
  int hitsAllowed = 0;
  int hrAllowed = 0;
  int strikeouts = 0;
  int walks = 0;
  int hitByPitch = 0;
  int runsAllowed = 0;
  int earnedRuns = 0;

  String get inningsPitched {
    int full = outsRecorded ~/ 3;
    int rem = outsRecorded % 3;
    if (rem == 0) {
      return '$full';
    }
    return '$full $rem/3';
  }

  String get era {
    if (outsRecorded == 0) {
      return '.---';
    }
    double innings = outsRecorded / 3.0;
    double val = (earnedRuns * 7.0) / innings;
    return val.toStringAsFixed(2);
  }
}

class Player {
  String id;
  String name;
  String position;
  int runsScored;
  int errorsCommitted;
  List<PlateEvent> appearances;
  List<PlateEvent> pitchingEvents;

  Player({
    required this.id,
    required this.name,
    required this.position,
    this.runsScored = 0,
    this.errorsCommitted = 0,
    List<PlateEvent>? appearances,
    List<PlateEvent>? pitchingEvents,
  }) : appearances = appearances ?? [],
       pitchingEvents = pitchingEvents ?? [];

  int get pa => appearances.length;
  int get ab => appearances.where((p) => p.result.isAtBat).length;
  int get hits => appearances.where((p) => p.result.isHit).length;
  int get doubles =>
      appearances.where((p) => p.result == AtBatResult.doubleHit).length;
  int get triples =>
      appearances.where((p) => p.result == AtBatResult.tripleHit).length;
  int get hr =>
      appearances.where((p) => p.result == AtBatResult.homeRun).length;
  int get rbi => appearances.fold(0, (sum, p) => sum + p.rbi);
  int get bb => appearances.where((p) => p.result == AtBatResult.walk).length;
  int get hbp =>
      appearances.where((p) => p.result == AtBatResult.hitByPitch).length;
  int get so => appearances
      .where(
        (p) =>
            p.result == AtBatResult.strikeout ||
            p.result == AtBatResult.strikeoutSafe,
      )
      .length;
  int get roe => appearances
      .where(
        (p) =>
            p.result == AtBatResult.error ||
            p.result == AtBatResult.strikeoutSafe,
      )
      .length;
  int get sh =>
      appearances.where((p) => p.result == AtBatResult.sacrificeHit).length;
  int get sf =>
      appearances.where((p) => p.result == AtBatResult.sacrificeFly).length;

  String get battingAverage {
    if (ab == 0) {
      return '.---';
    }
    double avg = hits / ab;
    if (avg >= 1.0) {
      return '1.000';
    }
    return avg.toStringAsFixed(3).substring(1);
  }

  PitcherStats get pitcherStats {
    final stats = PitcherStats();
    for (var ev in pitchingEvents) {
      stats.battersFaced++;
      int outsInPlay = ev.outsAfter - ev.outsBefore;
      if (outsInPlay > 0) {
        stats.outsRecorded += outsInPlay;
      }

      if (ev.result.isHit) {
        stats.hitsAllowed++;
      }
      if (ev.result == AtBatResult.homeRun) {
        stats.hrAllowed++;
      }
      if (ev.result == AtBatResult.strikeout ||
          ev.result == AtBatResult.strikeoutSafe) {
        stats.strikeouts++;
      }
      if (ev.result == AtBatResult.walk) {
        stats.walks++;
      }
      if (ev.result == AtBatResult.hitByPitch) {
        stats.hitByPitch++;
      }
      stats.runsAllowed += ev.runs;
      stats.earnedRuns += ev.earnedRuns;
    }
    return stats;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTabIndex = 0;

  String teamNameTop = '自チーム (先)';
  String teamNameBottom = '対戦相手 (後)';

  int totalInningsConfig = 7;
  int inning = 1;
  bool isTop = true;

  late List<int> scoresTop;
  late List<int> scoresBottom;
  int errorsTop = 0;
  int errorsBottom = 0;

  int outs = 0;
  BaseRunners runners = BaseRunners();

  int batterIndexTop = 0;
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

  int batterIndexBottom = 0;
  List<Player> playersBottom = [
    Player(id: 'b1', name: '大谷', position: '指'),
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

  final List<PlateEvent> _gameEvents = [];
  int _currentCycle = 0;
  int _scoreTabTeamIndex = 0;

  @override
  void initState() {
    super.initState();
    _initInnings(totalInningsConfig);
    currentPitcherIdTop = playersTop
        .firstWhere((p) => p.position == '投', orElse: () => playersTop.last)
        .id;
    currentPitcherIdBottom = playersBottom
        .firstWhere((p) => p.position == '投', orElse: () => playersBottom.last)
        .id;
  }

  void _initInnings(int count) {
    scoresTop = List.filled(count, 0);
    scoresBottom = List.filled(count, 0);
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

  int get totalHitsTop => playersTop.fold(0, (sum, b) => sum + b.hits);
  int get totalHitsBottom => playersBottom.fold(0, (sum, b) => sum + b.hits);
  int get totalScoreTop => scoresTop.fold(0, (a, b) => a + b);
  int get totalScoreBottom => scoresBottom.fold(0, (a, b) => a + b);

  Player? _findPlayer(String? id) {
    if (id == null) {
      return null;
    }
    try {
      return [...playersTop, ...playersBottom].firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  int get maxCycleInCurrentInning {
    final evs = _gameEvents
        .where((e) => e.inning == inning && e.isTop == isTop)
        .toList();
    if (evs.isEmpty) {
      return 0;
    }
    return evs.map((e) => e.cycleIndex).reduce((a, b) => a > b ? a : b);
  }

  PlateEvent? get activeEvent {
    return _gameEvents
        .where(
          (e) =>
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

  void _ensureInningCapacity(int inn) {
    while (scoresTop.length < inn) {
      scoresTop.add(0);
      scoresBottom.add(0);
    }
  }

  void _addRuns(int runs) {
    if (runs <= 0) {
      return;
    }
    int idx = inning - 1;
    _ensureInningCapacity(inning);
    setState(() {
      if (isTop) {
        scoresTop[idx] += runs;
      } else {
        scoresBottom[idx] += runs;
      }
    });
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

  void _rebuildGameState() {
    _ensureInningCapacity(inning);
    for (int i = 0; i < scoresTop.length; i++) {
      scoresTop[i] = 0;
      scoresBottom[i] = 0;
    }
    errorsTop = 0;
    errorsBottom = 0;

    for (var b in [...playersTop, ...playersBottom]) {
      b.runsScored = 0;
      b.errorsCommitted = 0;
      b.appearances.clear();
      b.pitchingEvents.clear();
    }

    _gameEvents.sort((a, b) {
      if (a.inning != b.inning) {
        return a.inning.compareTo(b.inning);
      }
      if (a.isTop != b.isTop) {
        return a.isTop ? -1 : 1;
      }
      if (a.cycleIndex != b.cycleIndex) {
        return a.cycleIndex.compareTo(b.cycleIndex);
      }
      return a.batterIndex.compareTo(b.batterIndex);
    });

    BaseRunners simRunners = BaseRunners();
    int simOuts = 0;
    int curInn = -1;
    bool curTop = true;

    for (int i = 0; i < _gameEvents.length; i++) {
      final ev = _gameEvents[i];
      ev.eventId = i + 1;

      if (ev.inning != curInn || ev.isTop != curTop) {
        curInn = ev.inning;
        curTop = ev.isTop;
        simRunners = BaseRunners();
        simOuts = 0;
      }

      simRunners.removeRunner(ev.batterId);

      ev.runnersBefore = simRunners.copy();
      ev.outsBefore = simOuts;

      BaseRunners nextRunners = simRunners.copy();
      int runs = 0;
      int rbi = 0;
      int nextOuts = simOuts;

      void scoreRunner(String? runnerId) {
        if (runnerId != null) {
          runs++;
          rbi++;
          final r = _findPlayer(runnerId);
          if (r != null) {
            r.runsScored++;
          }
        }
      }

      switch (ev.result) {
        case AtBatResult.singleHit:
          scoreRunner(simRunners.runner3rd);
          nextRunners.runner3rd = simRunners.runner2nd;
          nextRunners.runner2nd = simRunners.runner1st;
          nextRunners.runner1st = ev.batterId;
          break;

        case AtBatResult.doubleHit:
          scoreRunner(simRunners.runner3rd);
          scoreRunner(simRunners.runner2nd);
          nextRunners.runner3rd = simRunners.runner1st;
          nextRunners.runner2nd = ev.batterId;
          nextRunners.runner1st = null;
          break;

        case AtBatResult.tripleHit:
          scoreRunner(simRunners.runner3rd);
          scoreRunner(simRunners.runner2nd);
          scoreRunner(simRunners.runner1st);
          nextRunners.runner3rd = ev.batterId;
          nextRunners.runner2nd = null;
          nextRunners.runner1st = null;
          break;

        case AtBatResult.homeRun:
          scoreRunner(simRunners.runner3rd);
          scoreRunner(simRunners.runner2nd);
          scoreRunner(simRunners.runner1st);
          runs++;
          rbi++;
          final b = _findPlayer(ev.batterId);
          if (b != null) {
            b.runsScored++;
          }
          nextRunners = BaseRunners();
          break;

        case AtBatResult.walk:
        case AtBatResult.hitByPitch:
        case AtBatResult.strikeoutSafe:
          if (simRunners.runner1st != null &&
              simRunners.runner2nd != null &&
              simRunners.runner3rd != null) {
            scoreRunner(simRunners.runner3rd);
          }
          if (simRunners.runner1st != null && simRunners.runner2nd != null) {
            nextRunners.runner3rd = simRunners.runner2nd;
          }
          if (simRunners.runner1st != null) {
            nextRunners.runner2nd = simRunners.runner1st;
          }
          nextRunners.runner1st = ev.batterId;
          break;

        case AtBatResult.error:
          scoreRunner(simRunners.runner3rd);
          nextRunners.runner3rd = simRunners.runner2nd;
          nextRunners.runner2nd = simRunners.runner1st;
          nextRunners.runner1st = ev.batterId;
          break;

        case AtBatResult.strikeout:
        case AtBatResult.groundOut:
        case AtBatResult.flyOut:
        case AtBatResult.foulFlyOut:
          nextOuts++;
          break;

        case AtBatResult.doublePlay:
          nextOuts += 2;
          nextRunners.runner1st = null;
          break;

        case AtBatResult.groundAdvance:
        case AtBatResult.flyAdvance:
        case AtBatResult.sacrificeHit:
        case AtBatResult.sacrificeFly:
          runs = ev.runs;
          rbi = ev.rbi;
          nextOuts = ev.outsAfter;
          nextRunners = ev.runnersAfter.copy();
          break;
      }

      ev.runs = runs;
      ev.rbi = rbi;
      if (ev.result != AtBatResult.error) {
        ev.earnedRuns = runs;
      }

      ev.runnersAfter = nextRunners.copy();
      ev.outsAfter = nextOuts;
      ev.causedInningEnd = nextOuts >= 3;

      simRunners = nextRunners.copy();
      simOuts = nextOuts;

      final b = _findPlayer(ev.batterId);
      if (b != null) {
        b.appearances.add(ev);
      }

      final p = _findPlayer(ev.pitcherId);
      if (p != null) {
        p.pitchingEvents.add(ev);
      }

      int innIdx = ev.inning - 1;
      while (scoresTop.length <= innIdx) {
        scoresTop.add(0);
        scoresBottom.add(0);
      }

      if (ev.isTop) {
        scoresTop[innIdx] += ev.runs;
      } else {
        scoresBottom[innIdx] += ev.runs;
      }

      if (ev.errorPlayerId != null) {
        final defB = _findPlayer(ev.errorPlayerId);
        if (defB != null) {
          defB.errorsCommitted++;
        }
        if (ev.isTop) {
          errorsBottom++;
        } else {
          errorsTop++;
        }
      }
    }

    _syncCurrentView();
  }

  void _syncCurrentView() {
    final curEv = activeEvent;
    if (curEv != null) {
      runners = curEv.runnersBefore.copy();
      outs = curEv.outsBefore;
      return;
    }

    final prevEvents = _gameEvents
        .where(
          (e) =>
              e.inning == inning &&
              e.isTop == isTop &&
              (e.cycleIndex < _currentCycle ||
                  (e.cycleIndex == _currentCycle &&
                      e.batterIndex < currentBatterIndex)),
        )
        .toList();

    if (prevEvents.isNotEmpty) {
      final last = prevEvents.last;
      runners = last.runnersAfter.copy();
      outs = last.outsAfter;
    } else {
      runners = BaseRunners();
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
      currentBatterIndex = last.batterIndex;
      _currentCycle = last.cycleIndex;
      _rebuildGameState();
    });
  }

  void _deleteCurrentPlateEvent() {
    final ev = activeEvent;
    if (ev == null) {
      return;
    }

    setState(() {
      _gameEvents.removeWhere((e) => e.eventId == ev.eventId);
      _rebuildGameState();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('打席を削除し、スコアを再計算しました。'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _changeInning() {
    outs = 0;
    runners = BaseRunners();
    if (!isTop) {
      inning++;
      _ensureInningCapacity(inning);
    }
    isTop = !isTop;
    _currentCycle = 0;
    currentBatterIndex = 0;
  }

  void _nextBatter() {
    int nextIdx = currentBatterIndex + 1;
    if (nextIdx >= currentBatters.length) {
      nextIdx = 0;
      _currentCycle++;
    }
    currentBatterIndex = nextIdx;
    _syncCurrentView();
  }

  void _jumpToInning(int targetInn, bool targetIsTop) {
    setState(() {
      inning = targetInn;
      isTop = targetIsTop;
      _ensureInningCapacity(inning);
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

  void _promptDirectionAndRecord(AtBatResult result, {String? errorPlayerId}) {
    if (outs >= 3 && activeEvent == null) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。これ以上アウトになる打席は入力できません。');
      return;
    }

    bool needsDirection = [
      AtBatResult.singleHit,
      AtBatResult.doubleHit,
      AtBatResult.tripleHit,
      AtBatResult.groundOut,
      AtBatResult.flyOut,
      AtBatResult.foulFlyOut,
    ].contains(result);

    if (!needsDirection) {
      String defaultDir = '';
      if (result == AtBatResult.homeRun) {
        defaultDir = '中';
      }
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
                    _recordOrUpdateAtBat(
                      result,
                      direction: dir,
                      errorPlayerId: errorPlayerId,
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
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _recordOrUpdateAtBat(
    AtBatResult result, {
    required String direction,
    String? errorPlayerId,
  }) {
    setState(() {
      final batter = currentBatters[currentBatterIndex];
      final targetEv = activeEvent;
      final pitcher = activePitcher;

      if (targetEv != null) {
        targetEv.result = result;
        targetEv.direction = direction;
        targetEv.errorPlayerId = errorPlayerId;
      } else {
        final newEvent = PlateEvent(
          eventId: _gameEvents.length + 1,
          batterId: batter.id,
          batterIndex: currentBatterIndex,
          pitcherId: pitcher.id,
          inning: inning,
          isTop: isTop,
          cycleIndex: _currentCycle,
          result: result,
          direction: direction,
          rbi: 0,
          runs: 0,
          errorPlayerId: errorPlayerId,
          runnersBefore: runners.copy(),
          outsBefore: outs,
          runnersAfter: runners.copy(),
          outsAfter: outs,
          causedInningEnd: false,
        );
        _gameEvents.add(newEvent);
      }

      _rebuildGameState();

      final currentInnEvents = _gameEvents
          .where((e) => e.inning == inning && e.isTop == isTop)
          .toList();
      if (currentInnEvents.isNotEmpty && currentInnEvents.last.outsAfter >= 3) {
        _changeInning();
      } else if (targetEv == null) {
        _nextBatter();
      }
    });
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
        content: const Text('この三振はアウトになりましたか？それとも振り逃げ等で出塁しましたか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _recordOrUpdateAtBat(AtBatResult.strikeoutSafe, direction: '');
            },
            child: const Text(
              '振り逃げ (出塁/アウトなし)',
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
              onPressed: () => Navigator.pop(ctx),
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
                            _applySacrificeResult(
                              finalResult,
                              dir,
                              new1st,
                              new2nd,
                              new3rd,
                              runs,
                              rbi,
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
          ...defendingPlayers.map(
            (b) => SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                _recordOrUpdateAtBat(
                  AtBatResult.error,
                  direction: b.position,
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
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _recordOrUpdateAtBat(AtBatResult.error, direction: '');
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
      _showRuleWarning('⚠️ 塁上に走者がいないため、牽制死・走塁死は発生しません。');
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
      _applyPickoff(onBase.first.key);
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
              _applyPickoff(entry.key);
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

  void _applyPickoff(String base) {
    if (outs >= 3) {
      _showRuleWarning('⚠️ すでに3アウト（チェンジ）状態です。');
      return;
    }
    setState(() {
      if (base == '1塁') {
        runners.runner1st = null;
      }
      if (base == '2塁') {
        runners.runner2nd = null;
      }
      if (base == '3塁') {
        runners.runner3rd = null;
      }
      outs++;
      if (outs >= 3) {
        _changeInning();
      }
    });
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _applySacrificeResult(
                  AtBatResult.sacrificeHit,
                  '投',
                  new1st,
                  new2nd,
                  new3rd,
                  runs,
                  rbi,
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
              onPressed: () => Navigator.pop(ctx),
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
                          _applySacrificeResult(
                            finalResult,
                            dir,
                            new1st,
                            new2nd,
                            new3rd,
                            runs,
                            rbi,
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
            onSelectionChanged: (selectedSet) => onSelected(selectedSet.first),
          ),
        ],
      ),
    );
  }

  void _applySacrificeResult(
    AtBatResult result,
    String direction,
    String? new1st,
    String? new2nd,
    String? new3rd,
    int runs,
    int rbi,
  ) {
    setState(() {
      final batter = currentBatters[currentBatterIndex];
      final targetEv = activeEvent;
      final pitcher = activePitcher;

      BaseRunners runnersBefore = targetEv != null
          ? targetEv.runnersBefore.copy()
          : runners.copy();
      int outsBefore = targetEv != null ? targetEv.outsBefore : outs;

      int nextOuts = outsBefore + 1;
      bool inningEnded = nextOuts >= 3;

      BaseRunners nextRunners = BaseRunners(
        runner1st: new1st,
        runner2nd: new2nd,
        runner3rd: new3rd,
      );

      if (targetEv != null) {
        targetEv.result = result;
        targetEv.direction = direction;
        targetEv.rbi = rbi;
        targetEv.runs = runs;
        targetEv.runnersAfter = nextRunners;
        targetEv.outsAfter = nextOuts;
        targetEv.causedInningEnd = inningEnded;
      } else {
        _gameEvents.add(
          PlateEvent(
            eventId: _gameEvents.length + 1,
            batterId: batter.id,
            batterIndex: currentBatterIndex,
            pitcherId: pitcher.id,
            inning: inning,
            isTop: isTop,
            cycleIndex: _currentCycle,
            result: result,
            direction: direction,
            rbi: rbi,
            runs: runs,
            runnersBefore: runnersBefore,
            outsBefore: outsBefore,
            runnersAfter: nextRunners,
            outsAfter: nextOuts,
            causedInningEnd: inningEnded,
          ),
        );
      }

      _rebuildGameState();

      final currentInnEvents = _gameEvents
          .where((e) => e.inning == inning && e.isTop == isTop)
          .toList();
      if (currentInnEvents.isNotEmpty && currentInnEvents.last.outsAfter >= 3) {
        _changeInning();
      } else if (targetEv == null) {
        _nextBatter();
      }
    });
  }

  void _handleSteal() {
    if (runners.isEmpty) {
      _showRuleWarning('⚠️ 塁上に走者がいないため、盗塁はできません。');
      return;
    }
    setState(() {
      if (runners.runner3rd != null && runners.runner2nd == null) {
        _addRuns(1);
        final r = _findPlayer(runners.runner3rd);
        if (r != null) {
          r.runsScored++;
        }
        runners.runner3rd = null;
      } else if (runners.runner2nd != null && runners.runner3rd == null) {
        runners.runner3rd = runners.runner2nd;
        runners.runner2nd = null;
      } else if (runners.runner1st != null && runners.runner2nd == null) {
        runners.runner2nd = runners.runner1st;
        runners.runner1st = null;
      } else {
        if (runners.runner3rd != null) {
          _addRuns(1);
          final r = _findPlayer(runners.runner3rd);
          if (r != null) {
            r.runsScored++;
          }
        }
        runners.runner3rd = runners.runner2nd;
        runners.runner2nd = runners.runner1st;
        runners.runner1st = null;
      }
    });
  }

  void _handleAdvanceAll() {
    if (runners.isEmpty) {
      _showRuleWarning('⚠️ 塁上に走者がいないため、進塁（WP/PB）はできません。');
      return;
    }
    setState(() {
      if (runners.runner3rd != null) {
        _addRuns(1);
        final r = _findPlayer(runners.runner3rd);
        if (r != null) {
          r.runsScored++;
        }
      }
      runners.runner3rd = runners.runner2nd;
      runners.runner2nd = runners.runner1st;
      runners.runner1st = null;
    });
  }

  Player? _getPlayerByPosition(String pos) {
    return defendingPlayers.where((p) => p.position == pos).firstOrNull;
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
            icon: const Icon(Icons.undo),
            tooltip: '1手戻す',
            onPressed: _gameEvents.isNotEmpty ? _undo : null,
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
        onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
        indicatorColor: Colors.green.shade200,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_baseball),
            label: '盤面入力',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart),
            label: 'スコア・個人成績',
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
                                onTap: () => _jumpToInning(inn, true),
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
                                onTap: () => _jumpToInning(inn, false),
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
                      '(${activePitcher.pitcherStats.inningsPitched}回 ${activePitcher.pitcherStats.strikeouts}K ${activePitcher.pitcherStats.runsAllowed}失点)',
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
                            backgroundColor: evInThisCycle.result.isHit
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
                    onSelected: (_) => _jumpToBatter(idx),
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
                          setState(() => _changeInning());
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
                          child: _baseNode(
                            '2塁',
                            runners.runner2nd,
                            () => _editRunnerDialog('2塁'),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          child: _baseNode(
                            '3塁',
                            runners.runner3rd,
                            () => _editRunnerDialog('3塁'),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          child: _baseNode(
                            '1塁',
                            runners.runner1st,
                            () => _editRunnerDialog('1塁'),
                          ),
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
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSteal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.teal.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      '盗塁',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleAdvanceAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: runners.isEmpty
                          ? Colors.grey.shade300
                          : Colors.teal.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      'WP / PB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
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
                      '牽制/走塁死',
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
        _categoryHeader('安打（全ポジション・内野安打選択対応）', Colors.blue.shade800),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                '単打 (1H)',
                Colors.blue.shade100,
                () => _promptDirectionAndRecord(AtBatResult.singleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '二塁打 (2B)',
                Colors.blue.shade200,
                () => _promptDirectionAndRecord(AtBatResult.doubleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '三塁打 (3B)',
                Colors.blue.shade300,
                () => _promptDirectionAndRecord(AtBatResult.tripleHit),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '本塁打 (HR)',
                Colors.amber.shade300,
                () => _promptDirectionAndRecord(AtBatResult.homeRun),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _categoryHeader('四死球・相手失策', Colors.teal.shade800),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                '四球 (BB)',
                Colors.teal.shade100,
                () => _promptDirectionAndRecord(AtBatResult.walk),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '死球 (HBP)',
                Colors.teal.shade200,
                () => _promptDirectionAndRecord(AtBatResult.hitByPitch),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                '敵失 (エラー)',
                Colors.orange.shade200,
                _promptErrorDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _categoryHeader('進塁打（バント・犠牲フライ・タッチアップ）', Colors.purple.shade800),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                '犠打 (送りバント)',
                Colors.purple.shade100,
                _promptSacrificeHit,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionBtn(
                runners.runner3rd != null ? '犠飛 (犠牲フライ)' : 'フライ進塁 (タッチアップ)',
                Colors.purple.shade200,
                _promptSacrificeFly,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _categoryHeader('凡退・アウト（ファウルフライ対応）', Colors.red.shade800),
        Row(
          children: [
            Expanded(
              child: _actionBtn('ゴロ凡退', Colors.red.shade100, _handleGroundOut),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn(
                '飛球凡退',
                Colors.red.shade100,
                () => _promptDirectionAndRecord(AtBatResult.flyOut),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn(
                'ファウル邪飛',
                Colors.red.shade100,
                () => _promptDirectionAndRecord(AtBatResult.foulFlyOut),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn(
                '三振 (K/振逃)',
                Colors.red.shade200,
                _promptStrikeoutDialog,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _actionBtn(
                '併殺 (DP)',
                Colors.red.shade300,
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
          final matchEvs = b.appearances
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

  void _editRunnerDialog(String baseName) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('$baseName の走者設定'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                if (baseName == '1塁') {
                  runners.runner1st = null;
                }
                if (baseName == '2塁') {
                  runners.runner2nd = null;
                }
                if (baseName == '3塁') {
                  runners.runner3rd = null;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              '走者なし（空にする / 走塁死）',
              style: TextStyle(color: Colors.red),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              String? currentId = (baseName == '1塁')
                  ? runners.runner1st
                  : (baseName == '2塁')
                  ? runners.runner2nd
                  : runners.runner3rd;

              if (currentId == null) {
                _showRuleWarning('⚠️ 走者がいないため、本塁生還はできません。');
                Navigator.pop(ctx);
                return;
              }

              setState(() {
                _addRuns(1);
                final b = _findPlayer(currentId);
                if (b != null) {
                  b.runsScored++;
                }
                if (baseName == '1塁') {
                  runners.runner1st = null;
                }
                if (baseName == '2塁') {
                  runners.runner2nd = null;
                }
                if (baseName == '3塁') {
                  runners.runner3rd = null;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              '本塁生還（＋1得点）',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '選手を直接配置:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          ...currentBatters.map(
            (b) => SimpleDialogOption(
              onPressed: () {
                setState(() {
                  if (baseName == '1塁') {
                    runners.runner1st = b.id;
                  }
                  if (baseName == '2塁') {
                    runners.runner2nd = b.id;
                  }
                  if (baseName == '3塁') {
                    runners.runner3rd = b.id;
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text('${b.name} (${b.position})'),
            ),
          ),
        ],
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
                      _ensureInningCapacity(val);
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

          // 1. 打席表＆個人打撃成績
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
                '安打計: ${activeBatters.fold(0, (s, b) => s + b.hits)}本',
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
                      _th('四球'),
                      _th('死球'),
                      _th('犠打'),
                      _th('犠飛'),
                      _th('三振'),
                      _th('敵失'),
                      _th('打率', isAccent: true),
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
                          final pas = b.appearances
                              .where((p) => p.inning == currentInn)
                              .toList();
                          if (pas.isEmpty) {
                            return _td('-');
                          }
                          bool hasHit = pas.any((p) => p.result.isHit);
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
                        _td('${b.pa}'),
                        _td('${b.ab}'),
                        _td(
                          '${b.hits}',
                          isBold: true,
                          textColor: Colors.blue.shade900,
                        ),
                        _td('${b.doubles}'),
                        _td('${b.triples}'),
                        _td(
                          '${b.hr}',
                          isBold: b.hr > 0,
                          textColor: b.hr > 0 ? Colors.purple.shade800 : null,
                        ),
                        _td(
                          '${b.rbi}',
                          isBold: b.rbi > 0,
                          textColor: b.rbi > 0 ? Colors.red.shade800 : null,
                        ),
                        _td('${b.runsScored}'),
                        _td('${b.bb}'),
                        _td('${b.hbp}'),
                        _td('${b.sh}'),
                        _td('${b.sf}'),
                        _td('${b.so}'),
                        _td('${b.roe}'),
                        _td(
                          b.battingAverage,
                          isBold: true,
                          textColor: Colors.green.shade900,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. 投手成績テーブル
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
                        (p) => p.pitchingEvents.isNotEmpty || p.position == '投',
                      )
                      .map((p) {
                        final pStats = p.pitcherStats;
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
                              pStats.era,
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

          // 3. 選手詳細カード一覧
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
                          '打率 ${b.battingAverage}',
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
                            _statItem('打席', '${b.pa}'),
                            _statItem('打数', '${b.ab}'),
                            _statItem('安打', '${b.hits}', isBold: true),
                            _statItem('2塁打', '${b.doubles}'),
                            _statItem('3塁打', '${b.triples}'),
                            _statItem('本塁打', '${b.hr}', isBold: true),
                            _statItem(
                              '打点',
                              '${b.rbi}',
                              textColor: Colors.red.shade800,
                            ),
                            _statItem('得点', '${b.runsScored}'),
                            _statItem('四球', '${b.bb}'),
                            _statItem('死球', '${b.hbp}'),
                            _statItem('犠打', '${b.sh}'),
                            _statItem('犠飛', '${b.sf}'),
                            _statItem('三振', '${b.so}'),
                            _statItem('敵失出塁', '${b.roe}'),
                            _statItem(
                              '守備エラー',
                              '${b.errorsCommitted}',
                              textColor: b.errorsCommitted > 0
                                  ? Colors.red
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (b.appearances.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: b.appearances.asMap().entries.map((pEntry) {
                            int paIdx = pEntry.key;
                            PlateEvent pa = pEntry.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ActionChip(
                                avatar: CircleAvatar(
                                  radius: 7,
                                  backgroundColor: pa.result.isHit
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
                                    fontWeight: pa.result.isHit
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: pa.result.isHit
                                        ? Colors.blue.shade900
                                        : Colors.black87,
                                  ),
                                ),
                                backgroundColor: pa.result.isHit
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
                          }).toList(),
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

  void _editBatterInfoDialog(List<Player> list, int index) {
    final nameCtrl = TextEditingController(text: list[index].name);
    final posCtrl = TextEditingController(text: list[index].position);
    int runs = list[index].runsScored;
    int errs = list[index].errorsCommitted;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('得点数:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: runs > 0
                            ? () => setDialogState(() => runs--)
                            : null,
                      ),
                      Text(
                        '$runs',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setDialogState(() => runs++),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('守備エラー数:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: errs > 0
                            ? () => setDialogState(() => errs--)
                            : null,
                      ),
                      Text(
                        '$errs',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setDialogState(() => errs++),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  list[index].name = nameCtrl.text;
                  list[index].position = posCtrl.text;
                  list[index].runsScored = runs;
                  list[index].errorsCommitted = errs;
                });
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
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
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                inning = 1;
                isTop = true;
                _initInnings(totalInningsConfig);
                errorsTop = errorsBottom = outs = 0;
                runners = BaseRunners();
                batterIndexTop = 0;
                batterIndexBottom = 0;
                _currentCycle = 0;
                _gameEvents.clear();
                for (var b in playersTop) {
                  b.appearances.clear();
                  b.pitchingEvents.clear();
                  b.runsScored = 0;
                  b.errorsCommitted = 0;
                }
                for (var b in playersBottom) {
                  b.appearances.clear();
                  b.pitchingEvents.clear();
                  b.runsScored = 0;
                  b.errorsCommitted = 0;
                }
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
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isFilled) {
            outs = targetOut - 1;
          } else {
            outs = targetOut;
            if (outs >= 3) {
              _changeInning();
            }
          }
        });
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isFilled ? Colors.redAccent : Colors.grey.shade300,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
        ),
      ),
    );
  }

  Widget _baseNode(String baseName, String? runnerId, VoidCallback onTap) {
    final runner = _findPlayer(runnerId);
    final isOn = runner != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
