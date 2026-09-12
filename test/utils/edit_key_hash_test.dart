import 'package:baseball_score/utils/edit_key_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hashEditKey', () {
    test('同じキーは常に同じハッシュになる', () {
      expect(hashEditKey('himitsu123'), hashEditKey('himitsu123'));
    });

    test('異なるキーは異なるハッシュになる', () {
      expect(hashEditKey('himitsu123'), isNot(hashEditKey('himitsu124')));
    });

    test('SHA-256のため64文字の16進数文字列になる', () {
      final hash = hashEditKey('himitsu123');
      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });
  });
}
