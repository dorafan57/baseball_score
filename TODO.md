# 残作業

フェーズ1（ロジック抽出＋テスト）と、優先度の高いバグ3件の修正は完了済み。
以下は未着手。上から順に着手するのが手戻りが少ない。

## A. 集計ロジックの残バグ（`lib/logic/` と `lib/models/` で完結する）

### A-1. 投手の対戦打者数に走塁イベントが混入する
`lib/models/player_stats.dart` の `pitching` ゲッターが `pitchingEvents` を
無条件に数えているため、盗塁・WP・PB・走塁死のたびに対戦打者数が増える。
該当箇所に `NOTE:` コメントあり。打席イベントだけを数えるようにする。
`test/logic/game_replay_test.dart` にテストを追加すること。

### A-2. アウト数の逆算がもろい
`lib/logic/game_replay.dart` の `_estimateAddedOuts()` は、走者数の増減から
アウト数を推定している。走者の行き先を正しく渡さないとアウト数がずれる。
本来は `GameEvent` に明示的な `outsAdded` を持たせるべき。
※ 変更すると既存イベントの互換性に影響するため、永続化（フェーズ3）より前にやること。

### A-3. 防御率のイニング数が画面設定と連動していない
`PitcherStats.era({regulationInnings})` は引数化済みだが、UI（`main.dart` の
投手成績テーブル）が既定値7のまま呼んでいる。`totalInningsConfig` を渡す。
表示中の「※7回制防御率換算」も連動させる。

## B. フェーズ2: Riverpod 化

1. `main()` を `ProviderScope` で包む
2. `lib/providers/game_provider.dart` に `GameNotifier extends Notifier<GameState>` を作る
   - `_gameEvents` / `_nextEventId` / 打順・イニングなどの進行状態をここへ移す
   - `main.dart` の `_ScoreInputScreenState` に残っているイベント記録メソッド
     （`_commitAtBat` `_recordBaserunningEvent` `_deleteEvent` `_undo` など）を移設
3. UI を `ConsumerWidget` / `ConsumerStatefulWidget` に置き換える

## C. フェーズ3: 永続化（shared_preferences）

- `GameEvent` / `BaseRunners` に `toJson` / `fromJson` を実装する
- 試合ごとにイベント列＋名簿＋チーム名を保存する
- `GameListScreen` の「過去試合の読み込み」を実装する
  （現在は SnackBar で「次回以降の実装で対応します」と表示するだけ）
- イベント列さえ復元できれば `replayGame()` で全成績が再現される

## D. フェーズ4: UI 分割とレスポンシブ

- `main.dart`（約4,700行）を `lib/screens/` と `lib/widgets/` に分割する
- 走者の進塁先を選ぶダイアログが5箇所でほぼ同型 → 共通コンポーネント化する
  （`_promptHitWithRunnersDialog` `_promptWalkOrErrorRunnersDialog`
    `_handleGroundOut` `_promptSacrificeHit` `_promptSacrificeFly`）
- `ConstrainedBox(maxWidth: 480)` でデスクトップ表示を制限する（CLAUDE.md の規約）
- ダークテーマ対応

## E. その他の小さな不具合

- `_showSettingsDialog` の `TextEditingController` が dispose されていない
- `_clickableOutLamp` は名前に反してタップできない（`onTap` なし）
- `_baseNode` の `onTap` が空実装
- シェアテキスト（`_generateShareText`）が全角チーム名に `padRight` を使っており桁がずれる
- 3アウト成立後に記録されたイベントが `_gameEvents` に残り続ける
  （集計対象外にはなっており、履歴ダイアログに「※3アウト後のため集計対象外」と表示される）

## F. リポジトリの整理

現在のブランチは `gh-pages`（ビルド成果物用）で、ソースコードがそこに混在している。
ソースは `main` ブランチで管理し、`gh-pages` はデプロイ専用に戻すのが望ましい。
