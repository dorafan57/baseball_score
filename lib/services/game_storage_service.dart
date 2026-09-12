import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_game.dart';

/// 試合データを shared_preferences（Web ローカルストレージ）へ保存・読込するサービス。
///
/// 全試合を1つの JSON 配列としてまとめて保存する。想定される試合数・データ量は
/// 小さいため、試合ごとに個別キーへ分割する必要はない。
class GameStorageService {
  static const _storageKey = 'saved_games_v1';

  Future<List<SavedGame>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SavedGame.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 同じ `gameId` の試合があれば上書きし、なければ先頭に追加する。
  Future<void> saveGame(SavedGame game) async {
    final games = await loadAll();
    final index = games.indexWhere((g) => g.gameId == game.gameId);
    if (index >= 0) {
      games[index] = game;
    } else {
      games.insert(0, game);
    }
    await _writeAll(games);
  }

  Future<void> deleteGame(String gameId) async {
    final games = await loadAll();
    games.removeWhere((g) => g.gameId == gameId);
    await _writeAll(games);
  }

  Future<void> _writeAll(List<SavedGame> games) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
