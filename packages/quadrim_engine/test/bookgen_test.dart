@TestOn('vm')
library;

import 'dart:convert';

import 'package:test/test.dart';

// The generator is under tool/ rather than lib/, because it uses dart:io and
// the purity gate scans lib/ only. Importing it by path is what lets the one
// function that carries a licence obligation be tested.
import '../tool/bookgen.dart';

void main() {
  group('the hash that enforces "moves unchanged"', () {
    // This function is the whole mechanism behind the dictionary's first
    // condition (D172). Without a fixed vector, a silent break in it would
    // make the integrity check accept any file at all.
    test('matches the standard vectors', () {
      expect(sha256Hex(utf8.encode('')),
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(sha256Hex(utf8.encode('abc')),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(
          sha256Hex(utf8.encode(
              'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')),
          '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
    });

    test('crosses a block boundary correctly', () {
      // 64 bytes is exactly one block, so the padding lands in a second one —
      // the case a naive implementation gets wrong.
      expect(sha256Hex(List<int>.filled(64, 0x61)),
          'ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb');
    });
  });
}
