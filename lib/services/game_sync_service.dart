import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_game.dart';
import '../utils/edit_key_hash.dart';

/// 試合データの保存・読込を行うサービスのインターフェース。
///
/// 実装は [FirestoreGameSyncService]（本番）。ウィジェットテストでは
/// 実際のFirestoreに繋がずに済むよう、[gameSyncServiceProvider] を
/// フェイク実装で上書きする。
abstract class GameSyncService {
  Future<List<SavedGame>> loadAll();

  /// 新しい試合を作成する。[editKey] を知っている端末だけが、以後
  /// この試合の [saveGame]/[deleteGame] を呼べるようになる。
  Future<void> createGame(SavedGame game, String editKey);

  /// 既存の試合を更新する。[isEditor] が true の端末のみ成功する。
  Future<void> saveGame(SavedGame game);
  Future<void> deleteGame(String gameId);

  /// 指定した試合のドキュメントをリアルタイムに購読する。
  /// ドキュメントが存在しない場合は `null` を流す。
  Stream<SavedGame?> watchGame(String gameId);

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
    final snap = await _games.orderBy('updatedAt', descending: true).get();
    return snap.docs.map((d) => SavedGame.fromJson(d.data())).toList();
  }

  @override
  Future<void> createGame(SavedGame game, String editKey) async {
    final hash = hashEditKey(editKey);
    final gameRef = _games.doc(game.gameId);
    // secret → editors → games の順で作成する。ルール側が secret の
    // ハッシュを editors 作成時に参照するため、この順序を守ること。
    await gameRef.collection('secret').doc('config').set({
      'editKeyHash': hash,
    });
    await gameRef.collection('editors').doc(_uid).set({
      'grantedAt': FieldValue.serverTimestamp(),
      'attemptedHash': hash,
    });
    await gameRef.set({
      ...game.toJson(),
      'docVersion': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveGame(SavedGame game) async {
    final ref = _games.doc(game.gameId);
    final current = await ref.get();
    final currentVersion = (current.data()?['docVersion'] as int?) ?? 0;
    await ref.set({
      ...game.toJson(),
      'docVersion': currentVersion + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _games.doc(gameId).delete();
  }

  @override
  Stream<SavedGame?> watchGame(String gameId) {
    return _games
        .doc(gameId)
        .snapshots()
        .map((doc) => doc.exists ? SavedGame.fromJson(doc.data()!) : null);
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
