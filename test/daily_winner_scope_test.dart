import 'dart:io';

import 'package:balaji_points/services/branch/daily_winner_scope.dart';
import 'package:flutter_test/flutter_test.dart';

const _erode = 'erode_main';
const _karur = 'karur_branch';

void main() {
  test('each branch has its own winner document per day', () {
    expect(
      DailyWinnerScope.docId(_erode, '2026-11-11'),
      'erode_main_2026-11-11',
    );
    expect(
      DailyWinnerScope.docId(_karur, '2026-11-11'),
      isNot(DailyWinnerScope.docId(_erode, '2026-11-11')),
    );
  });

  test('a winner belongs only to the branch it was drawn in', () {
    final karurWinner = {'branchId': _karur, 'date': '2026-11-11'};
    expect(DailyWinnerScope.belongsTo(karurWinner, _karur), isTrue);
    expect(DailyWinnerScope.belongsTo(karurWinner, _erode), isFalse);
  });

  test(
    'old winners with no branch, from before Karur opened, are E Road\'s',
    () {
      final old = {'date': '2026-10-20'};
      expect(DailyWinnerScope.belongsTo(old, _erode), isTrue);
      expect(DailyWinnerScope.belongsTo(old, _karur), isFalse);
    },
  );

  test('a recent winner with no branch is shown to no branch', () {
    final unknown = {'date': '2026-11-11'};
    expect(DailyWinnerScope.belongsTo(unknown, _erode), isFalse);
    expect(DailyWinnerScope.belongsTo(unknown, _karur), isFalse);
  });

  test('nothing while the branch is unknown', () {
    expect(DailyWinnerScope.belongsTo({'branchId': _erode}, null), isFalse);
    expect(DailyWinnerScope.belongsTo(null, _erode), isFalse);
  });

  test('every winner screen uses the branch rule', () {
    String read(String p) => File(p).readAsStringSync();
    final admin = read(
      'lib/presentation/widgets/admin/daily_spin_management.dart',
    );
    expect(admin, contains("'branchId': branchId,"));
    expect(admin, contains('DailyWinnerScope.docId(branchId, todayStr)'));
    expect(
      'DailyWinnerScope.belongsTo('.allMatches(admin).length,
      greaterThanOrEqualTo(3),
    );
    expect(
      read('lib/presentation/screens/admin/daily_spin_history_screen.dart'),
      contains('DailyWinnerScope.belongsTo('),
    );
    expect(
      read(
        'lib/presentation/screens/carpenter/home/widgets/home_top_carpenters.dart',
      ),
      contains('DailyWinnerScope.docId(branchId, _todayKey)'),
    );
  });
}
