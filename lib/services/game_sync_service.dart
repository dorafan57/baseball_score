import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_game.dart';
import '../utils/edit_key_hash.dart';

/// [GameSyncService.watchGame] が流す、試合本体と楽観的並行性制御用の
/// バージョン番号の組。
typedef WatchedGame = ({SavedGame game, int docVersion});

/// [GameSyncService.saveGameIfVersionMatches] を呼んだ時点で、
/// サーバー側のドキュメントが自分の知っている版から進んでいた場合に投げる。
///
/// 他の編集者が同時に更新したことを表す。フィールド単位のマージは行わず、
/// 呼び出し側はローカルの入力を諦めて最新のドキュメント（購読中の
/// [GameSyncService.watchGame] が直後に配信する）に委ねる。
class StaleGameStateException implements Exception {}

/// 試合データの保存・読込を行うサービスのインターフェース。
///
/// 実装は [FirestoreGameSyncService]（本番）。ウィジェットテストでは
/// 実際のFirestoreに繋がずに済むよう、[gameSyncServiceProvider] を
/// フェイク実装で上書きする。
abstract class GameSyncService {
  Future<List<SavedGame>> loadAll();

  /// 新しい試合を作成する。[editKey] を知っている端末だけが、以後
  /// この試合の更新・削除を呼べるようになる。
  Future<void> createGame(SavedGame game, String editKey);

  /// [expectedVersion] が現在サーバーに保存されている版と一致する場合のみ
  /// 保存する（楽観的並行性制御）。一致しなければ [StaleGameStateException]
  /// を投げる。[isEditor] が true の端末のみ成功する。
  Future<void> saveGameIfVersionMatches(SavedGame game, int expectedVersion);

  Future<void> deleteGame(String gameId);

  /// 一覧の並び順を [gameIdsInOrder] の順（先頭が一番上）に変更する。
  /// 編集キーは不要（内容そのものは変更しないため）。
  Future<void> reorderGames(List<String> gameIdsInOrder);

  /// 指定した試合のドキュメントをリアルタイムに購読する。
  /// ドキュメントが存在しない場合は `null` を流す。
  Stream<WatchedGame?> watchGame(String gameId);

  /// この端末が、指定した試合の編集権限をすでに持っているか。
  Future<bool> isEditor(String gameId);

  /// [editKey] が正しければ編集権限を取得して true を返す。
  /// 誤っていれば false を返す（例外にはしない）。
  Future<bool> tryUnlockEditor(String gameId, String editKey);
}

/// 試合データを Firestore（`games` コレクション）へ保存・読込するサービス。
///
/// 複数人が同じ試合を共有して編集できるよう、ブラウザローカルの
/// shared_preferences保存に代わってこちらを使う。
///
/// 編集キーは平文のままFirestoreへ送らない。作成時に
/// `games/{gameId}/secret/config`（誰も読めないドキュメント）へ
/// ハッシュ値だけを保存し、以後は `games/{gameId}/editors/{uid}`
/// （本人だけが読める「編集権限」ドキュメント）の有無で判定する。
/// 詳細は `firestore.rules` を参照。
class FirestoreGameSyncService implements GameSyncService {
  static const _collection = 'games';

  CollectionReference<Map<String, dynamic>> get _games =>
      FirebaseFirestore.instance.collection(_collection);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Future<List<SavedGame>> loadAll() async {
    final snap = await _games.orderBy('sortOrder').get();
    return snap.docs.map((d) => SavedGame.fromJson(d.data())).toList();
  }

  @override
  Future<void> createGame(SavedGame game, String editKey) async {
    final hash = hashEditKey(editKey);
    final gameRef = _games.doc(game.gameId);
    // secret → editors → games の順で作成する。ルール側が secret の
    // ハッシュを editors 作成時に参照するため、この順序を守ること。
    await gameRef.collection('secret').doc('config').set({'editKeyHash': hash});
    await gameRef.collection('editors').doc(_uid).set({
      'grantedAt': FieldValue.serverTimestamp(),
      'attemptedHash': hash,
    });
    await gameRef.set({
      ...game.toJson(),
      'docVersion': 0,
      // 新しい試合ほど一覧の先頭に来るよう、負の現在時刻をソートキーにする
      // （sortOrder は昇順で並べるため）。並べ替え操作をすると連番に振り直される。
      'sortOrder': -DateTime.now().millisecondsSinceEpoch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reorderGames(List<String> gameIdsInOrder) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < gameIdsInOrder.length; i++) {
      batch.update(_games.doc(gameIdsInOrder[i]), {
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> saveGameIfVersionMatches(
    SavedGame game,
    int expectedVersion,
  ) async {
    final ref = _games.doc(game.gameId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final currentVersion = (snap.data()?['docVersion'] as int?) ?? 0;
      if (currentVersion != expectedVersion) {
        throw StaleGameStateException();
      }
      // merge: true で更新する。`sortOrder` など SavedGame に含まれない
      // フィールドを消してしまわないようにするため。
      tx.set(ref, {
        ...game.toJson(),
        'docVersion': currentVersion + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _games.doc(gameId).delete();
  }

  @override
  Stream<WatchedGame?> watchGame(String gameId) {
    return _games.doc(gameId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return (
        game: SavedGame.fromJson(data),
        docVersion: (data['docVersion'] as int?) ?? 0,
      );
    });
  }

  @override
  Future<bool> isEditor(String gameId) async {
    final doc = await _games.doc(gameId).collection('editors').doc(_uid).get();
    return doc.exists;
  }

  @override
  Future<bool> tryUnlockEditor(String gameId, String editKey) async {
    try {
      await _games.doc(gameId).collection('editors').doc(_uid).set({
        'grantedAt': FieldValue.serverTimestamp(),
        'attemptedHash': hashEditKey(editKey),
      });
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
  }
}

final gameSyncServiceProvider = Provider<GameSyncService>(
  (ref) => FirestoreGameSyncService(),
);
