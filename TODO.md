# 残作業

フェーズ1（ロジック抽出＋テスト）、優先度の高いバグ3件の修正、
フェーズ2（Riverpod化）は完了済み。
以下は未着手。上から順に着手するのが手戻りが少ない。

## A. 集計ロジックの残バグ（`lib/logic/` と `lib/models/` で完結する）

### A-3. 防御率のイニング数が画面設定と連動していない
`PitcherStats.era({regulationInnings})` は引数化済みだが、UI（`main.dart` の
投手成績テーブル）が既定値7のまま呼んでいる。`totalInningsConfig` を渡す。
表示中の「※7回制防御率換算」も連動させる。

## C. フェーズ3: 永続化（shared_preferences）— 完了

- `GameEvent` / `BaseRunners` / `Player` に `toJson` / `fromJson` を実装済み
  （成績・スコアは保存せず `replayGame()` で再現する方針を踏襲）
- `lib/models/saved_game.dart`: 試合1件分のスナップショット（イベント列＋名簿＋
  チーム名＋進行状況）を表す `SavedGame` を追加
- `lib/services/game_storage_service.dart`: `SavedGame` の一覧を
  shared_preferences へ JSON でまとめて保存・読込・削除する `GameStorageService`
- `GameNotifier` に `startNewGame` / `loadGame` / `toSavedGame` を追加
- `GameListScreen` で保存済み試合の一覧表示・読込・長押し削除を実装
  （スコアは一覧表示のたびに `SavedGame.replay()` で再計算）
- `test/models/saved_game_test.dart` に JSON 変換の往復テストを追加

## D. フェーズ4: UI 分割とレスポンシブ — 完了

- `lib/main.dart`（約4,450行）を分割し、`main()` と `app.dart` の再公開だけに縮小
  - `lib/app.dart`: `BaseballScoreApp`（テーマ・レスポンシブ枠）
  - `lib/screens/game_list_screen.dart` / `lib/screens/score_input_screen.dart`
  - `lib/widgets/board/`: `board_header.dart`（`BoardTeam` / `OutLamp`）、
    `diamond_field.dart`（`PosTag` / `BaseNode`）、
    `action_buttons.dart`（`CategoryHeader` / `ActionButton` /
    `CategorizedActionButtons`）、`input_tab.dart`（`InputTab`）
  - `lib/widgets/stats/`: `stat_widgets.dart`（`StatsHeaderCell` /
    `StatsDataCell` / `StatItem`）、`score_stats_tab.dart`（`ScoreStatsTab`）
  - `lib/widgets/dialogs/`: 1ダイアログ1ファイル（18ファイル）。
    各ダイアログは State のメソッドではなく
    `showXxxDialog(context, {session, notifier, ...})` というトップレベル関数
- 走者の進塁先を選ぶダイアログの共通部分を
  `lib/widgets/dialogs/runner_advance_section.dart` に切り出し
  （`RunnerChoiceTile` と、走者のいる塁だけ選択肢を並べる `RunnerAdvanceSection`）。
  6箇所（上記5ダイアログ＋暴投／捕逸）から利用する。
  得点・打点・アウト数の計算式は挙動を変えないよう各ダイアログに残した
- `ScoreInputScreen` の再描画粒度は分割前と同じ
  （`build()` 先頭で `ref.watch(gameProvider)` を1回だけ。
  各タブ・ダイアログへはそのスナップショットと `GameNotifier` を引数で渡す）
- `MaterialApp.builder` で `Center(ConstrainedBox(maxWidth: 480))` を適用
  （狭い幅ではみ出していた履歴ダイアログ／ゴロアウトダイアログ／犠飛ダイアログの
  タイトル行は `Flexible` で折り返すよう修正）
- `darkTheme`（`ColorScheme.fromSeed(..., brightness: dark)`）と
  `themeMode: ThemeMode.system` を追加

## E. その他の小さな不具合

- ~~`_editBatterInfoDialog` で選手情報を保存すると
  `A TextEditingController was used after being disposed.` で落ちることがある~~
  → `lib/widgets/dialogs/edit_batter_dialog.dart` でダイアログ自体を
  StatefulWidget にし、`State.dispose()` でコントローラを破棄するよう修正（D で対応）
- ~~`_showSettingsDialog` の `TextEditingController` が dispose されていない~~
  → `lib/widgets/dialogs/settings_dialog.dart` で同様に修正（D で対応）
- `_clickableOutLamp` は名前に反してタップできない（`onTap` なし）
  → `OutLamp`（`lib/widgets/board/board_header.dart`）に `onTap` を配線済み。
  ただしアウトカウントはイベントの再生結果から導出される値のため、
  ランプのタップで増減させるには「アウトのみを記録するイベント種別」が必要。
  仕様が決まるまで呼び出し側では `onTap` を渡していない（コードに TODO あり）
- `_baseNode` の `onTap` が空実装
  → `BaseNode`（`lib/widgets/board/diamond_field.dart`）で
  `GestureDetector` に配線済み。塁タップ時の挙動（代走など）は未定のため
  呼び出し側では渡していない（コードに TODO あり）
- ~~シェアテキスト（`_generateShareText`）が全角チーム名に `padRight` を使っており桁がずれる~~
  → `lib/screens/score_input_screen.dart` に全角文字を2、半角文字を1として
  数える表示幅ベースの切り詰め・パディング処理を追加して対応
- ~~3アウト成立後に記録されたイベントが `_gameEvents` に残り続ける~~
  → ジャンプ機能で3アウト成立済みの半イニングに戻った状態で新規の打席・
  走塁イベントを追加しようとした場合、`GameNotifier.commitAtBat` /
  `recordBaserunningEvent` が記録自体を行わないよう修正（既存イベントの
  上書き更新は従来どおり可能）。修正前に記録済みの「集計対象外」イベントは
  履歴ダイアログから手動削除できる

## F. リポジトリの整理

現在のブランチは `gh-pages`（ビルド成果物用）で、ソースコードがそこに混在している。
ソースは `main` ブランチで管理し、`gh-pages` はデプロイ専用に戻すのが望ましい。
