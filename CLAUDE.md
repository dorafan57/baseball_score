# Baseball Score Web App Rules

- Platform: Flutter Web (Mobile-friendly responsive UI)
- State Management: flutter_riverpod
- Styling: Material 3, optimized for smartphone screens (max-width: 480px on desktop)
- Storage: Web local persistence (shared_preferences)

# Language

- Respond in Japanese.
- Code comments should be in Japanese.

# 現在の構成

目標構成は `lib/models` `lib/providers` `lib/screens` `lib/widgets`。
現時点では以下まで到達している（providers / screens / widgets は未作成）。

```
lib/models/     at_bat_result / base_runners / game_event / resolved_event
                player / player_stats / game_state
lib/logic/      advance_calculator.dart  … 標準的な進塁計算（純粋関数）
                game_replay.dart         … replayGame(): イベント列→全成績（純粋関数）
lib/main.dart   … 全UI（約4,700行、1ファイル）
test/logic/     … ロジックの単体テスト
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
  `main.dart` に集計ロジックを書き戻さない。

## 作業前後に必ず実行

```
flutter analyze --no-pub      # 0件を維持すること
flutter test                  # 全件成功を維持すること
```

残作業は [TODO.md](TODO.md) を参照。
