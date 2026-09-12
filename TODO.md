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
