import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrim/services/achievements.dart';

/// `doc/store/achievements.json` is the hand-authored half of the store
/// catalogue — names, descriptions, points, icons. The ids and the ordering are
/// **derived** in `achievements.dart` from the opponent roster and the rung
/// lists (D378, D379). This file is the seam between the two, and it is the
/// only thing stopping them drifting apart.
///
/// **Plain `test`, not `testWidgets`.** `testWidgets` runs in a fake-async zone
/// that never completes real file I/O, which is the same reason
/// `repository_test.dart` proves the on-disk store in plain bodies.
///
/// Nothing here is shipped: the app never renders a store name, so the JSON is
/// build-and-console material rather than an asset. It is validated here anyway
/// because the errors it can carry — a missing Dutch string, a points total over
/// the cap, an icon that does not exist — are all things whose cost is paid in a
/// web console at 3am rather than in a compiler.
void main() {
  final root = Directory.current.path.endsWith('app')
      ? Directory(Directory.current.parent.path)
      : Directory.current;
  final file = File('${root.path}/doc/store/achievements.json');
  final json =
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final items = (json['achievements'] as List).cast<Map<String, Object?>>();
  final leaderboard = json['leaderboard'] as Map<String, Object?>;

  String key(Map<String, Object?> m) => m['key']! as String;

  group('the store catalogue agrees with the code', () {
    /// The load-bearing one. Asserted **in both directions**: an entry naming a
    /// key the code does not have would be typed into a console and then
    /// reported by nothing; a code key missing from the JSON would ship an
    /// achievement with no name at all.
    test('has exactly the keys the derived catalogue has', () {
      final fromJson = items.map(key).toSet();
      final fromCode = achievementCatalogue.map((a) => a.key).toSet();
      expect(fromJson.difference(fromCode), isEmpty,
          reason: 'in achievements.json but not in the code');
      expect(fromCode.difference(fromJson), isEmpty,
          reason: 'in the code but not in achievements.json');
    });

    test('is in the same order as the derived catalogue', () {
      expect(items.map(key).toList(),
          achievementCatalogue.map((a) => a.key).toList());
    });

    /// The Game Center ids are ours and permanent (D213, D365). If the two
    /// disagree the console gets one and the app reports the other, which is an
    /// achievement that can never fire and cannot be renamed afterwards.
    test('carries the same Game Center ids as the code', () {
      for (final a in achievementCatalogue) {
        final entry = items.firstWhere((m) => key(m) == a.key);
        expect(entry['gameCenterId'], a.gameCenterId, reason: a.key);
      }
      expect(leaderboard['gameCenterId'], kRatingLeaderboardGameCenterId);
    });

    /// `playGamesId` is null in the JSON and [kPlayGamesIdUnset] in the code
    /// until the console issues one. **Both must move together**: an id in the
    /// JSON that the code does not have means Android is still silent while the
    /// console is fully set up, which looks like a broken integration.
    test('agrees with the code about whether Play ids exist yet', () {
      final jsonHasIds = items.every((m) => m['playGamesId'] != null) &&
          leaderboard['playGamesId'] != null;
      expect(jsonHasIds, playGamesConfigured,
          reason: 'achievements.json and achievements.dart disagree about '
              'whether the Play Console ids have been filled in');
    });
  });

  group('every entry is complete', () {
    test('has both languages, all three strings, non-empty', () {
      for (final m in items) {
        for (final lang in ['en', 'nl']) {
          final t = m[lang] as Map<String, Object?>?;
          expect(t, isNotNull, reason: '${key(m)} has no $lang');
          for (final field in ['name', 'locked', 'earned']) {
            final v = t![field];
            expect(v, isA<String>(), reason: '${key(m)}.$lang.$field');
            expect((v! as String).trim(), isNotEmpty,
                reason: '${key(m)}.$lang.$field is blank');
          }
        }
      }
    });

    test('the leaderboard has both languages', () {
      for (final lang in ['en', 'nl']) {
        final t = leaderboard[lang]! as Map<String, Object?>;
        expect((t['name']! as String).trim(), isNotEmpty);
        expect((t['description']! as String).trim(), isNotEmpty);
      }
    });

    /// No numerals in a *name* would be wrong — "Five in a day" is fine and
    /// "30 dagen" would be too. What must not happen is a **name that is only a
    /// number**, which is what an untranslated placeholder looks like.
    test('no name is bare punctuation or a lone number', () {
      for (final m in items) {
        for (final lang in ['en', 'nl']) {
          final name = (m[lang]! as Map<String, Object?>)['name']! as String;
          expect(RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(name), isTrue,
              reason: '${key(m)}.$lang.name has no letters in it: "$name"');
        }
      }
    });

    test('every icon exists in doc/designs', () {
      for (final m in items) {
        final icon = m['icon']! as String;
        expect(File('${root.path}/doc/designs/$icon').existsSync(), isTrue,
            reason: '${key(m)} names a missing icon: $icon');
      }
    });

    test('no icon is used twice', () {
      final icons = items.map((m) => m['icon']! as String).toList();
      expect(icons.toSet(), hasLength(icons.length),
          reason: 'two achievements share an icon');
    });
  });

  group('the points budget', () {
    int points(Map<String, Object?> m) => m['points']! as int;

    /// **Game Center caps the *sum* across the app, not each value** — which is
    /// why adding the 1080 rung re-priced the whole streak column (D379). This
    /// is the check that would have caught the 1090 that forced it.
    test('totals no more than 1000', () {
      final total = items.fold<int>(0, (a, m) => a + points(m));
      expect(total, lessThanOrEqualTo(1000),
          reason: 'Game Center rejects the set; re-price rather than trim');
      expect(total, greaterThan(0));
    });

    test('every value is positive', () {
      for (final m in items) {
        expect(points(m), greaterThan(0), reason: key(m));
      }
    });

    /// **The opponent column is exactly 1 to 31, weakest first** (D386). Not
    /// merely ascending: it is a flat step of one per rung, set in the console
    /// and mirrored here, and the fourteen points that re-pricing freed are
    /// what the draw is paid with. An opponent inserted into the roster without
    /// re-pricing would shift every rung above it by one and silently break the
    /// total, so this asserts the shape rather than the direction.
    test('beating an opponent pays its position in the roster', () {
      final beat = items.where((m) => key(m).startsWith('beat:')).toList();
      expect(beat.map(points).toList(),
          List.generate(beat.length, (i) => i + 1),
          reason: 'the opponent column is no longer 1..${beat.length}');
    });

    /// The draw is paid out of what that re-pricing freed, and the set is at
    /// the cap. Written down because the number is not arbitrary: it is
    /// 1000 minus everything else, and anything added later has to come from
    /// somewhere.
    test('the draw carries what the re-pricing freed', () {
      expect(points(items.firstWhere((m) => key(m) == 'draw')), 34);
      expect(items.fold<int>(0, (a, m) => a + points(m)), 1000);
    });

    /// Within a family the reward must not go backwards: a longer streak paying
    /// less than a shorter one is the kind of thing nobody notices until a
    /// player does.
    test('each family ascends', () {
      for (final family in ['games_in_day', 'days_in_row']) {
        final rungs = items.where((m) => key(m).startsWith('$family:')).toList();
        expect(rungs, isNotEmpty, reason: family);
        for (var i = 1; i < rungs.length; i++) {
          expect(points(rungs[i]), greaterThanOrEqualTo(points(rungs[i - 1])),
              reason: '$family goes backwards at ${key(rungs[i])}');
        }
      }
    });
  });
}
