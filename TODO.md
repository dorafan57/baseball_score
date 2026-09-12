# 残作業

フェーズ1〜4（ロジック抽出＋テスト／優先度の高いバグ修正／Riverpod化／
永続化／UI分割とレスポンシブ対応）およびリポジトリの整理は完了済み。
以下は未着手の残作業。

## A. 集計ロジックの残バグ（`lib/logic/` と `lib/models/` で完結する）

`PitcherStats.era({regulationInnings})` は引数化済みだが、UI（`main.dart` の
投手成績テーブル）が既定値7のまま呼んでいる。`totalInningsConfig` を渡す。
表示中の「※7回制防御率換算」も連動させる。

## B. その他の小さな不具合

- `_clickableOutLamp` は名前に反してタップできない（`onTap` なし）
  → `OutLamp`（`lib/widgets/board/board_header.dart`）に `onTap` を配線済み。
  ただしアウトカウントはイベントの再生結果から導出される値のため、
  ランプのタップで増減させるには「アウトのみを記録するイベント種別」が必要。
  仕様が決まるまで呼び出し側では `onTap` を渡していない（コードに TODO あり）
- `_baseNode` の `onTap` が空実装
  → `BaseNode`（`lib/widgets/board/diamond_field.dart`）で
  `GestureDetector` に配線済み。塁タップ時の挙動（代走など）は未定のため
  呼び出し側では渡していない（コードに TODO あり）

## C. 実機動作確認で判明した不具合・改善要望（2026-09-13確認分）

### 入力まわりの不具合

- 回替わり時に次の打者が1番打者に戻ってしまう。前回のその半イニングの
  続きの打者から始めたい。
  → `GameNotifier._changeInning`（`lib/providers/game_provider.dart:290-298`）
  が半イニング交代のたびに `batterIndexTop` / `batterIndexBottom` を
  無条件で0にリセットしている。ここを直せば直る想定。
- アウトカウントの強制チェンジ機能は不要なので削除してよい。
  → `forceChangeInning`（`lib/providers/game_provider.dart:642`）と
  呼び出しボタン（`lib/widgets/board/input_tab.dart:503`）を削除する。
- 併殺の際、アウトにならない走者（2塁・3塁走者）が進塁するのかそのまま
  残るのかを他の打席結果と同様に選択できるようにする必要がある。
  → `advance_calculator.dart:136-142` の `AtBatResult.doublePlay` 分岐が
  「打者と1塁走者アウト、2塁・3塁走者はその場に残る」で固定されており、
  進塁するケース（併殺崩れで生還・進塁する場合など）を選べない。
  `hit_with_runners_dialog.dart` 等の他ダイアログのように走者ごとの
  進塁先を選択できるUIをつける。
- 2アウト・3塁走者ありでゴロアウト等を選んだ場合、3塁走者を無条件に
  生還させられてしまう（アウトカウントに関わらず得点が有効になる）。
  → `ground_out_dialog.dart:113-134` の「本塁生還」選択が `runs = 1` を
  無条件にセットしている。野球規則上「打者走者が1塁に達する前に
  アウトになったことで第3アウトが成立した場合、3塁走者が先に本塁を
  踏んでいても得点は認められない」というタイムプレイの例外があるため、
  打者自身のアウトが3アウト目になる通常のゴロアウトでは得点無効が正しい。
  （封殺や本塁憤死など打者以外の走者アウトが3アウト目になるケースでは
  従来通り得点有効でよいので、一律禁止ではなく条件分岐が必要）。
  併殺（`double_play_route_dialog.dart`）や他のアウト系ダイアログにも
  同様の考慮が要るか確認する。

### 配色・見た目の整理（意図不明な色分けをやめて意味のある配色にする）

- 操作ボタンで本塁打・併殺のみ色が付いている。
  → `lib/widgets/board/action_buttons.dart:127-130`（`Colors.green.shade50`）、
  `:245-248`（`Colors.red.shade50`）。他のボタンと同じ白に統一する。
- スコア画面の「現在の回」ハイライトが意図した配色になっていない
  （1回の表裏だけ水色、それ以外がオレンジに見える）。
  → `lib/widgets/board/input_tab.dart:134-220` 付近と
  `lib/widgets/stats/score_stats_tab.dart:123-210` 付近のハイライト条件を
  見直し、一貫した意味を持つ配色にする。
- ダークテーマで併殺の経路選択の文字が見にくい。
  → `lib/widgets/dialogs/double_play_route_dialog.dart:21-36` で選択結果の
  表示欄の背景が `Colors.grey.shade200` 固定なのに対し、文字色は
  `TextStyle` に色指定がなくテーマ依存（ダークテーマだと白文字になり
  明るい背景と衝突する）。背景・文字色を両方明示的に指定する。
- 打者・投手成績で安打／本塁打／打点／盗塁／打率／失策など一部項目のみ
  文字色が付いている。意図が不明なので基準を決めて統一する。
  → `lib/widgets/stats/score_stats_tab.dart` 内の該当 `StatsDataCell` /
  `StatItem` 呼び出し（350行台〜、580行台〜、680行台〜）を確認する。

### テーマ・レイアウト

- ダークテーマ／ライトテーマを設定ボタンから手動で切り替えられるように
  したい。
  → 現状 `lib/app.dart` は `themeMode: ThemeMode.system` でOS設定に
  追従するのみ。選択状態を保持する設定用プロバイダ（永続化含む）を追加し、
  設定画面 or ボタンから切替できるようにする。
- Chromeで開いた際に横幅がアプリ幅に固定されてしまうので広げたい。
  → `lib/app.dart` の `kAppMaxWidth = 480` は「デスクトップでもスマホ幅で
  中央固定表示する」という現行仕様（`CLAUDE.md` に明記された意図的な設計）。
  対応する場合はこの制約自体の見直しが必要で、`CLAUDE.md` の記述も
  合わせて更新すること。
- 設定ボタンから現在のバージョン情報を表示できるようにしたい
  （デプロイされたものがどのバージョンか分かるようにするため）。
  → `showSettingsDialog`（`lib/widgets/dialogs/settings_dialog.dart`）に
  バージョン表示を追加する。`pubspec.yaml` の `version: 1.0.0+1` を
  `package_info_plus` 等で取得して表示する方法と、ビルド時に
  `--dart-define` でコミットハッシュ／ビルド日時を埋め込む方法がある。

### 永続化・保存

- 保存してもアプリ／ブラウザを閉じるとデータが消える。
  → `GameStorageService`（`lib/services/game_storage_service.dart`）は
  shared_preferences（Web版は`localStorage`）に保存しており、通常のブラウザ
  であれば閉じても残るはず。`flutter run -d chrome` は起動のたびに新しい
  Chromeプロファイルを使うため開発中はこの挙動に見える可能性がある。まず
  ビルド済み成果物を通常のブラウザで開いて再現するか切り分けること。

### 複数人同時編集（規模の大きい機能追加）

- 複数人が同じWebページに同時アクセスし、同時にスコア編集・保存できる
  ようにしたい。
  → 現状はブラウザローカルの shared_preferences のみで完結しており、
  共有ストレージ・排他制御・リアルタイム同期の仕組みが存在しない。
  サーバーサイド（Firebase等）導入を伴う大きめの設計検討が必要なため、
  他の項目とは切り離して方針を検討する。
