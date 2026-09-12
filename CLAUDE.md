# Baseball Score Web App Rules

- Platform: Flutter Web (Mobile-friendly responsive UI)
- State Management: flutter_riverpod
- Styling: Material 3, optimized for smartphone screens (max-width: 480px on desktop)
- Storage: Web local persistence (shared_preferences)

# Language

- Respond in Japanese.
- Code comments should be in Japanese.

# 現在の構成

```
lib/models/     at_bat_result / base_runners / game_event / resolved_event
                player / player_stats / game_state / saved_game
lib/logic/      advance_calculator.dart  … 標準的な進塁計算（純粋関数）
                game_replay.dart         … replayGame(): イベント列→全成績（純粋関数）
lib/providers/  game_provider.dart       … GameSessionState / GameNotifier
lib/services/   game_storage_service.dart … shared_preferences への保存・読込
lib/app.dart    … BaseballScoreApp（テーマ・ダークテーマ・最大幅480pxの枠）
lib/main.dart   … main() のみ（app.dart を再公開）
lib/screens/    game_list_screen / score_input_screen
lib/widgets/    board/  … 盤面入力タブとその部品
                stats/  … スコア・成績タブとその部品
                dialogs/… 1ダイアログ1ファイル
test/logic/     … ロジックの単体テスト
test/models/    … JSON 変換のテスト
test/widget_test.dart … 画面の回帰テスト
```

## 設計の中心

- **`_gameEvents`（`List<GameEvent>`）だけが試合の「事実」**。スコアも個人成績も
  `replayGame()` で毎回ゼロから再計算する（イベントソーシング）。
- `GameEvent` は **入力された事実のみ**を持ち、全フィールド `final`。
  アウトカウントや直前の走者状況は半イニングを再生しないと確定しないため
  `ResolvedEvent` 側が持つ。
- `Player` は名簿情報のみ。成績は `player.stats`（`PlayerStats`）に再生結果が差し込まれる。
- 集計ロジックを変更するときは `lib/logic/` を直し、`test/logic/` にテストを足すこと。
  UI 層（`lib/screens` / `lib/widgets`）に集計ロジックを書き戻さない。
- 画面の再描画は `ScoreInputScreen.build()` 先頭の `ref.watch(gameProvider)` 1箇所だけ。
  タブ・ダイアログへは `GameSessionState` と `GameNotifier` を引数で渡す
  （個別に `ref.watch` する `ConsumerWidget` を増やさない）。

## 作業前後に必ず実行

```
flutter analyze --no-pub      # 0件を維持すること
flutter test                  # 全件成功を維持すること
```

残作業は [TODO.md](TODO.md) を参照。
