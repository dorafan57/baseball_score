import 'package:baseball_score/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    await tester.pumpWidget(const BaseballScoreApp());
    expect(find.text('草野球スコア - 試合一覧'), findsOneWidget);

    await tester.tap(find.text('新規試合'));
    await tester.pumpAndSettle();

    expect(find.text('草野球スコア記録'), findsOneWidget);
    expect(find.text('1回 表 (自チーム (先) 攻)'), findsOneWidget);
  });

  testWidgets('四球を記録すると打者が進み、履歴に残る', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BaseballScoreApp());
    await tester.tap(find.text('新規試合'));
    await tester.pumpAndSettle();

    await recordWalk(tester);

    // 1番打者が1塁に出て、2番打者に移る。
    expect(find.text('2番 [中] 鈴木'), findsOneWidget);

    await openHistory(tester);
    expect(historyEntryCount(tester), 1);
    await closeHistory(tester);
  });

  testWidgets('イベントを削除しても、以降のイベントIDが重複しない', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BaseballScoreApp());
    await tester.tap(find.text('新規試合'));
    await tester.pumpAndSettle();

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
