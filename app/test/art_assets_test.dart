import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/design/art.dart';
import 'package:quadrim_engine/quadrim_engine.dart';

/// Ticket 038: the art the app names is the art the app ships.
///
/// `pubspec.yaml` declares `assets/art/` and `assets/art/opponents/` by
/// directory, which is convenient — a new opponent's portrait is a file drop —
/// and silent, because nothing objects to a directory that is missing a file.
/// The generator is deliberately not staleness-checked by `tool/check.sh`
/// (D290): re-encoding an image with a different Pillow build produces
/// different bytes for the same picture, and a gate that fails on a library
/// upgrade is a gate people learn to skip. This is the check that matters
/// instead — every path the code asks for resolves to real bytes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ByteData> load(String key) => rootBundle.load(key);

  test('every opponent in the catalogue has a portrait', () async {
    expect(opponentCatalogue, hasLength(31));
    for (final bot in opponentCatalogue) {
      final bytes = await load(Art.opponent(bot.id));
      expect(bytes.lengthInBytes, greaterThan(1024), reason: bot.id);
    }
  });

  test('the source art is named after the catalogue ids', () async {
    // `peble.png` and `quarts.png` were delivered misspelt and `artgen.py`
    // carried a filename-to-id mapping to paper over it. The files are named
    // after the ids now and the mapping is gone (D332), so what is left to
    // assert is the property the mapping used to buy: every id resolves.
    for (final id in ['pebble', 'quartz', 'osprey']) {
      expect(botById(id), isNotNull, reason: id);
      await expectLater(load(Art.opponent(id)), completes);
    }
  });

  test('the named artwork all resolves', () async {
    for (final asset in [
      Art.background,
      Art.logo,
      Art.cube,
      Art.newGame,
      Art.bannerShort,
      Art.bannerLong,
      Art.tutorial,
      Art.arrowLeft,
      Art.arrowRight,
    ]) {
      final bytes = await load(asset);
      expect(bytes.lengthInBytes, greaterThan(1024), reason: asset);
    }
  });

  test('the fonts and their licences are inside the bundle', () async {
    // The `fonts:` section bundles the faces; only the `assets:` section
    // bundles the licence text beside them, and the OFL requires the two to
    // travel together. Without this, dropping `assets/fonts/` from `assets:`
    // would ship the fonts and leave the licence on a developer's disk.
    for (final asset in [
      'assets/fonts/Cinzel-Regular.ttf',
      'assets/fonts/Cinzel-Bold.ttf',
      'assets/fonts/EBGaramond-Regular.ttf',
      'assets/fonts/EBGaramond-SemiBold.ttf',
    ]) {
      expect((await load(asset)).lengthInBytes, greaterThan(10000),
          reason: asset);
    }
    for (final licence in ['OFL-Cinzel', 'OFL-EBGaramond']) {
      final text = await rootBundle.loadString('assets/fonts/$licence.txt');
      expect(text, contains('SIL OPEN FONT LICENSE'), reason: licence);
    }
  });

  test('the whole shipped art budget stays under three megabytes', () async {
    // A ceiling, not a measurement: thirty-one portraits at a larger size, or the
    // background left at source resolution, would each push this past ten. The
    // number is here so that raising it is a decision somebody makes on
    // purpose rather than a diff nobody looks at.
    var total = 0;
    for (final bot in opponentCatalogue) {
      total += (await load(Art.opponent(bot.id))).lengthInBytes;
    }
    for (final asset in [
      Art.background,
      Art.logo,
      Art.cube,
      Art.newGame,
      Art.bannerShort,
      Art.bannerLong,
      Art.tutorial,
      Art.arrowLeft,
      Art.arrowRight,
      'assets/fonts/Cinzel-Regular.ttf',
      'assets/fonts/Cinzel-Bold.ttf',
      'assets/fonts/EBGaramond-Regular.ttf',
      'assets/fonts/EBGaramond-SemiBold.ttf',
    ]) {
      total += (await load(asset)).lengthInBytes;
    }
    expect(total, lessThan(3 * 1024 * 1024),
        reason: '${(total / 1024 / 1024).toStringAsFixed(2)} MB of art');
  });
}
