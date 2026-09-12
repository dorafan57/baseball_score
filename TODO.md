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
- 打者・投手成績の文字色に基準を設けて統一
  （安打系＝青、得点関連＝赤、盗塁＝ティール、率＝緑、
  それ以外の内訳項目は無色。詳細は `score_stats_tab.dart` 参照）。
- 設定ダイアログからライト／ダーク／端末設定追従を手動切替できるように
  追加（`providers/theme_mode_provider.dart` で shared_preferences に永続化）。
- デスクトップサイズの画面ではアプリの表示幅を480pxから900pxまで
  広げるよう変更（`lib/app.dart` の `kWideScreenBreakpoint` /
  `kAppMaxWidthWide`）。この仕様変更に合わせて `CLAUDE.md` も更新済み。
- 設定ダイアログにバージョン情報を表示（`lib/app_version.dart`）。
  コミットハッシュ等を埋め込みたい場合はビルド時に
  `--dart-define=BUILD_INFO=...` を渡す。

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
