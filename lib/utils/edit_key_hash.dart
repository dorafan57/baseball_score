import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 編集キーをSHA-256でハッシュ化する。
///
/// Firestoreへは平文の編集キーを一切送らず、このハッシュ値だけを送受信する
/// （`firestore.rules` 側で照合する）。
String hashEditKey(String editKey) {
  return sha256.convert(utf8.encode(editKey)).toString();
}
