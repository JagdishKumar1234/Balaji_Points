import 'package:balaji_points/presentation/screens/carpenter/home/rank_celebration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('rank #1 confetti', () {
    test('plays only for a leader with points', () {
      expect(
        RankCelebration.isRealLeader(
          topUserId: 'me',
          myUserId: 'me',
          topPoints: 12.5,
        ),
        isTrue,
      );
    });

    test('not when everyone has 0 points (e.g. after a reset)', () {
      expect(
        RankCelebration.isRealLeader(
          topUserId: 'me',
          myUserId: 'me',
          topPoints: 0,
        ),
        isFalse,
      );
    });

    test('not for someone who is not the leader', () {
      expect(
        RankCelebration.isRealLeader(
          topUserId: 'other',
          myUserId: 'me',
          topPoints: 50,
        ),
        isFalse,
      );
    });

    test('at most once a day per account', () async {
      SharedPreferences.setMockInitialValues({});
      final day1 = DateTime(2026, 11, 11, 9);
      expect(await RankCelebration.claimToday('me', now: day1), isTrue);
      expect(
        await RankCelebration.claimToday(
          'me',
          now: day1.add(const Duration(hours: 5)),
        ),
        isFalse,
      );
      expect(await RankCelebration.claimToday('other', now: day1), isTrue);
      expect(
        await RankCelebration.claimToday('me', now: DateTime(2026, 11, 12, 8)),
        isTrue,
      );
    });
  });
}
