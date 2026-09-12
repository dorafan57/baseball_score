import 'package:baseball_score/main.dart';
import 'package:baseball_score/models/saved_game.dart';
import 'package:baseball_score/services/game_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用のインメモリ実装。実際のFirestoreへは繋がない。
/// 編集キーの照合は行わず、常に編集権限があるものとして振る舞う。
class FakeGameSyncService implements GameSyncService {
  final Map<String, SavedGame> _games = {};

  @override
  Future<List<SavedGame>> loadAll() async => _games.values.toList();

  @override
  Future<void> createGame(SavedGame game, String editKey) async {
    _games[game.gameId] = game;
  }

  @override
  Future<void> saveGameIfVersionMatches(
    SavedGame game,
    int expectedVersion,
  ) async {
    _games[game.gameId] = game;
  }

  @override
  Future<void> deleteGame(String gameId) async {
    _games.remove(gameId);
  }

  @override
  Future<void> reorderGames(List<String> gameIdsInOrder) async {
    final reordered = {
      for (final id in gameIdsInOrder)
        if (_games.containsKey(id)) id: _games[id]!,
    };
    _games
      ..clear()
      ..addAll(reordered);
  }

  @override
  Stream<WatchedGame?> watchGame(String gameId) => const Stream.empty();

  @override
  Future<bool> isEditor(String gameId) async => true;

  @override
  Future<bool> tryUnlockEditor(String gameId, String editKey) async => true;
}

/// テスト用に [FakeGameSyncService] で上書きした [ProviderScope] を返す。
Widget testApp() => ProviderScope(
  overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
  child: const BaseballScoreApp(),
);

/// 「新規試合」ボタン→作成ダイアログの「作成」ボタンの順にタップし、
/// 既定のチーム名でスコア入力画面を開く。
Future<void> startNewGame(WidgetTester tester) async {
  await tester.tap(find.text('新規試合'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, '編集キー'), 'test-key');
  await tester.tap(find.text('作成'));
  await tester.pumpAndSettle();
}

/// 履歴ダイアログに並んでいるイベント件数。
int historyEntryCount(WidgetTester tester) =>
    tester.widgetList(find.byTooltip('このイベントを削除')).length;

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.byTooltip('試合イベント履歴・取消'));
  await tester.pumpAndSettle();
}

Future<void> closeHistory(WidgetTester tester) async {
  await tester.tap(find.text('閉じる'));
  await tester.pumpAndSettle();
}

/// 四球を1つ記録する。四球は追加のダイアログを挟まずに確定できる。
Future<void> recordWalk(WidgetTester tester) async {
  final button = find.text('四球 (BB)');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // 入力タブは縦に長いため、全要素が収まる大きさの画面で描画する。
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('新規試合を作成してスコア入力画面を開ける', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp());
    expect(find.text('草野球スコア - 試合一覧'), findsOneWidget);

    await startNewGame(tester);

    expect(find.text('草野球スコア記録'), findsOneWidget);
    expect(find.text('1回 表 (自チーム (先) 攻)'), findsOneWidget);
  });

  testWidgets('四球を記録すると打者が進み、履歴に残る', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp());
    await startNewGame(tester);

    await recordWalk(tester);

    // 1番打者が1塁に出て、2番打者に移る。
    expect(find.text('2番 [－] 選手名2'), findsOneWidget);

    await openHistory(tester);
    expect(historyEntryCount(tester), 1);
    await closeHistory(tester);
  });

  testWidgets('イベントを削除しても、以降のイベントIDが重複しない', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp());
    await startNewGame(tester);

    for (var i = 0; i < 4; i++) {
      await recordWalk(tester);
    }

    await openHistory(tester);
    expect(historyEntryCount(tester), 4);

    // 2件目を削除する（削除するとダイアログは閉じる）。
    await tester.tap(find.byTooltip('このイベントを削除').at(1));
    await tester.pumpAndSettle();

    await openHistory(tester);
    expect(historyEntryCount(tester), 3);
    await closeHistory(tester);

    // 削除後に追加したイベントが既存のIDと衝突していないことを、
    // 「1件消したら3件残る」ことで確認する。IDが重複していると2件同時に消える。
    await recordWalk(tester);

    await openHistory(tester);
    expect(historyEntryCount(tester), 4);
    await tester.tap(find.byTooltip('このイベントを削除').last);
    await tester.pumpAndSettle();

    await openHistory(tester);
    expect(historyEntryCount(tester), 3);
    await closeHistory(tester);
  });
}
