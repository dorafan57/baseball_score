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

- 保存してもアプリ／ブラウザを閉じるとデータが消える、という報告があったが、
  ストレージをFirestoreへ移行したことで解消済みのはず（ブラウザローカルの
  shared_preferencesには依存しなくなった）。念のため実機で再確認すること。

### 複数人同時編集（対応済み・2026-09-13〜14）

Firebase（Firestore + 匿名認証）を導入し、以下を実装済み:

- 保存先をFirestore（`games`コレクション）に変更し、複数人が同じ試合を
  共有・同時編集できるようにした。
- `snapshots()`によるリアルタイム購読で、他の編集者・閲覧者の変更が
  即座に反映される。
- 作成者が設定する編集キー＋匿名認証により編集者／閲覧者を区別し、
  閲覧のみのユーザーは変更系の操作ができない（`firestore.rules`）。
- `docVersion`を使った楽観的排他制御を全ての変更系メソッドに導入し、
  competing writeが発生した場合は書き込みを諦めて
  「他の人が同時に更新しました」を表示する
  （`GameNotifier._commitLocalAndSync` / `conflictMessageProvider`）。
- 試合一覧の並べ替え（ドラッグ）、削除の権限ゲート、`go_router`による
  試合ごとの共有URL（`#/game/:gameId`）・リンクコピーボタンを追加。
- CI（`.github/workflows/deploy.yml`）にFirebase設定値のdart-define注入を追加。

詳細な設計は [CLAUDE.md](CLAUDE.md) の「複数人同時編集（Firebase）」を参照。

#### 残課題（対応保留）

- Firebase Local Emulator Suiteは未導入のため、Firestore連携部分
  （ルール・トランザクション）は自動テスト対象外。実機での手動確認に依存する。
- 編集キーの強度はクライアント側の入力チェックのみで、サーバー側での
  複雑さ強制はない（カジュアルな共有スコアブックとして妥当な水準と判断）。

### 成績拡充・ボックススコア・エクスポート・管理者モード（対応済み）

- `PlayerStats` に出塁率（`onBasePercentage`）・長打率（`sluggingPercentage`）・
  OPS（`ops`）・得点圏打率（`rispBattingAverage`）を追加
  （`lib/models/player_stats.dart` / `lib/models/base_runners.dart`）。
- `lib/logic/box_score_report.dart` に、ラインスコア＋両チームの打者・投手
  成績をまとめた `BoxScoreReport` を組み立てる純粋関数を追加。
  画面表示（`lib/widgets/stats/box_score_view.dart`）とPDF/Excel出力の
  共通データソースとして使う。
- スコア入力画面のAppBarに「ボックススコア・エクスポート」アイコンを追加し、
  `lib/widgets/dialogs/box_score_dialog.dart` からPDF/Excel書き出しができる
  （`lib/services/pdf_export_service.dart` / `excel_export_service.dart`）。
  PDFは`printing`パッケージの`PdfGoogleFonts`でNoto Sans JPを実行時取得
  （初回はネットワーク接続が必要）。書き出しは`share_plus`の
  `Share.shareXFiles`を使い、Web版ブラウザではダウンロードにフォールバックする。
- 管理者モード（全試合共通のマスターキーで、編集キーなしにどの試合も
  編集できる権限）を追加。`firestore.rules` の `isEditor()` に
  `isAdmin()`（`admins/{uid}` の存在確認）をOR条件で追加し、
  試合一覧画面の「管理者キーを入力」アイコン（`admin_key_dialog.dart`）から
  取得できる。

#### 管理者キーのセットアップ手順（初回のみ・手動）

アプリからは `config/adminKey` ドキュメントを書き込めない設計にしている
（「最初にアクセスした人が管理者キーを乗っ取れてしまう」ことを防ぐため）。
そのため、以下の手順で運営者が手動で1回だけ登録する。

1. 管理者キーにしたい文字列を決める。
2. `lib/utils/edit_key_hash.dart` の `hashEditKey()` と同じ
   SHA-256で、そのキーのハッシュ値（16進数64文字）を計算する
   （例: `dart run` で `print(hashEditKey('決めたキー'));` を実行するだけの
   一時スクリプトを書いて実行し、値を確認したら削除する）。
3. Firebaseコンソール → Firestore Database → `config` コレクション →
   ドキュメントID `adminKey` を作成し、フィールド `adminKeyHash`
   （文字列）に2.のハッシュ値を設定する。
4. `firestore.rules` の変更（`isAdmin()` 関数・`config/adminKey` /
   `admins/{uid}` のルール追加）を
   `firebase deploy --only firestore:rules` でデプロイする
   （このコマンドは各自の環境から実行すること。CIには含めていない）。
5. 管理者キーをローテーションしたい場合は、3.の `adminKeyHash` を
   Firebaseコンソールから書き換える（ルールで `update` を禁止しているため、
   一度削除してから作り直す）。既存の `admins/{uid}` は無効化されないため、
   権限を剥奪したい相手がいる場合は該当ドキュメントも合わせて削除する。

#### 残課題（対応保留）

- PDF/Excelのバイト列生成そのものは自動テストが薄い
  （`BoxScoreReport` を組み立てるロジックまではテスト済み）。
  レイアウト崩れ等はWebでの手動確認に依存する。
