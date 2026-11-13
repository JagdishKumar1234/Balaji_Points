import 'dart:io';

import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/branch/daily_winner_scope.dart';
import 'package:flutter_test/flutter_test.dart';

const _erode = 'erode_main';
const _karur = 'karur_branch';

void main() {
  const trade = LeaderboardGroup.trade;
  const pro = LeaderboardGroup.professional;

  test('each branch has its own winner document per group per day', () {
    expect(
      DailyWinnerScope.docId(_erode, trade, '2026-11-11'),
      'erode_main_trade_2026-11-11',
    );
    expect(
      DailyWinnerScope.docId(_erode, pro, '2026-11-11'),
      'erode_main_professional_2026-11-11',
    );
    expect(
      DailyWinnerScope.docId(_karur, trade, '2026-11-11'),
      isNot(DailyWinnerScope.docId(_erode, trade, '2026-11-11')),
    );
  });

  test('a group winner belongs only to that group', () {
    final w = {'branchId': _erode, 'group': 'trade', 'date': '2026-11-13'};
    expect(DailyWinnerScope.belongsTo(w, _erode, group: trade), isTrue);
    expect(DailyWinnerScope.belongsTo(w, _erode, group: pro), isFalse);
    expect(DailyWinnerScope.belongsTo(w, _karur, group: trade), isFalse);
    // Records from before the split match no group.
    final legacy = {'branchId': _erode, 'date': '2026-11-10'};
    expect(DailyWinnerScope.belongsTo(legacy, _erode, group: trade), isFalse);
    expect(DailyWinnerScope.belongsTo(legacy, _erode), isTrue);
    expect(DailyWinnerScope.groupOf(legacy), isNull);
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
    expect(admin, contains('DailySpinService()'));
    expect(
      'group: _group'.allMatches(admin).length,
      greaterThanOrEqualTo(4),
    );
    final service = read('lib/services/spin/daily_spin_service.dart');
    expect(service, contains("'branchId': branchId,"));
    expect(service, contains("'group': group.id,"));
    expect(service, contains('DailyWinnerScope.docId(branchId, group, date)'));
    expect(
      read('lib/presentation/screens/admin/daily_spin_history_screen.dart'),
      contains('DailyWinnerScope.belongsTo('),
    );
    expect(
      read(
        'lib/presentation/screens/carpenter/home/widgets/home_top_carpenters.dart',
      ),
      contains('DailyWinnerScope.docId(branchId, group, _todayKey)'),
    );
  });
}
