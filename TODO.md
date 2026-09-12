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

以下は2026-09-13時点で対応済み（詳細は各コミット参照）:

- 回替わり時に前回の続きの打者から再開するよう修正
  （`GameNotifier._changeInning`）。
- 不要だったアウトカウント強制チェンジ機能を削除
  （`forceChangeInning` とその呼び出しボタン）。
- 併殺時に2塁・3塁走者の進塁先（そのまま／進塁）を選択できるUIを追加
  （`double_play_route_dialog.dart`）。
- ゴロアウト・併殺で、打者自身や封殺の走者アウトが3アウト目になる
  タイムプレイの場合に得点を無効化するよう修正
  （`ground_out_dialog.dart` / `double_play_route_dialog.dart`）。
- 操作ボタンの本塁打・併殺の色付けをやめ、他のボタンと同じ白に統一。
- スコア画面のラインスコアで、行全体の緑色ハイライトと現在マスの
  オレンジハイライトが二重になっていた配色を整理し、
  「現在の打席のマスだけを強調する」1つの意味に統一。
- ダークテーマで併殺経路選択の文字が見にくかった問題を修正
  （背景・文字色を明示的に指定）。
- 設定ダイアログからライト／ダーク／端末設定追従を手動切替できるように
  追加（`providers/theme_mode_provider.dart` で shared_preferences に永続化）。
- デスクトップサイズの画面ではアプリの表示幅を480pxから900pxまで
  広げるよう変更（`lib/app.dart` の `kWideScreenBreakpoint` /
  `kAppMaxWidthWide`）。この仕様変更に合わせて `CLAUDE.md` も更新済み。
- 設定ダイアログにバージョン情報を表示（`lib/app_version.dart`）。
  当初は手動管理だったが、後述のデプロイ自動化にあわせて
  「年.月.日-その日の何回目のデプロイか」形式へ変更（自動算出）。
- 打者・投手成績表の文字色分け（安打＝青、打点／得点＝赤、盗塁＝ティール、
  率＝緑など）をあまり意味がないため撤廃し、全項目を無地の文字に統一
  （`stat_widgets.dart` の `isAccent`/`textColor` を削除し、
  `score_stats_tab.dart` の全呼び出し箇所を追随）。
- PCのChromeで打者・投手成績表やラインスコアが横スクロールできず
  見切れていた問題を修正。`lib/app.dart` にマウスドラッグでもスクロール
  できる `ScrollBehavior` を追加し、各表に `Scrollbar`
  （`thumbVisibility: true`）を付けて存在が分かるようにした。
- 盤面入力タブの回移動表示を拡大して見やすくし、横スクロールしても
  常に見える位置に「計（合計得点・安打数）」欄を追加
  （`input_tab.dart`）。
- 盤面入力タブに「打順（攻撃中チーム名）」ラベルを追加し、
  打者チップの並びが打順の巡りを表すことが分かるようにした
  （`input_tab.dart`）。既存の打者チップ列自体は打順表示として機能済み。
- 「1手戻す」（undo）はあったが「1手進める」（redo）がなかったため追加。
  `GameSessionState.redoStack` に取り消したイベントを積んでおき、
  新規記録・削除で無効化する方式（`game_provider.dart` /
  `score_input_screen.dart`）。
- main へのプッシュで GitHub Pages へ自動デプロイするワークフローを追加
  （`.github/workflows/deploy.yml`）。`flutter analyze` / `flutter test` を
  通してから `flutter build web` し、`gh-pages` ブランチへ発行する
  （`peaceiris/actions-gh-pages`）。公開URLは
  `https://dorafan57.github.io/baseball_score/`
  （リポジトリ設定で Pages のソースが `gh-pages` ブランチになっていることを
  一度確認すること）。ビルド時に `--dart-define=APP_VERSION=...` /
  `BUILD_INFO=...` を渡し、設定画面のバージョン表示に反映する。

### 未対応・要確認

- 保存してもアプリ／ブラウザを閉じるとデータが消える（未再現・要切り分け）。
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
