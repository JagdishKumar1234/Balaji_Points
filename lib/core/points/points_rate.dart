import 'package:intl/intl.dart';

/// How many rupees of approved purchases earn one point, per role.
///
/// Each role carries its own rate (`rupeesPerPoint` on the role record,
/// editable by the super admin). Built-in defaults: carpenters and interior
/// designers earn 1 point per ₹1,000; architects and engineers 1 point per
/// ₹5,000. Bills store the rate used, so old bills keep their value when a
/// rate changes later.
class PointsRate {
  PointsRate._();

  static const int defaultRupeesPerPoint = 1000;
  static const int minRupeesPerPoint = 1;
  static const int maxRupeesPerPoint = 1000000;

  static const Map<String, int> builtIn = {
    'carpenter': 1000,
    'interior_designer': 1000,
    'architect': 5000,
    'engineer': 5000,
  };

  /// The default rate for a role when its record sets none.
  static int defaultFor(String? roleId) =>
      builtIn[(roleId ?? '').trim().toLowerCase()] ?? defaultRupeesPerPoint;

  /// A stored rate, or [fallback] when missing or out of range.
  static int sanitize(Object? value, {required int fallback}) {
    final n = value is num ? value.round() : int.tryParse('$value');
    if (n == null || n < minRupeesPerPoint || n > maxRupeesPerPoint) {
      return fallback;
    }
    return n;
  }

  /// Points for [amount] rupees at [rupeesPerPoint] (decimals kept, so
  /// ₹2,500 at 1,000 → 2.5).
  static double pointsFor(num amount, int rupeesPerPoint) {
    if (amount <= 0 || rupeesPerPoint <= 0) return 0;
    return amount / rupeesPerPoint;
  }

  /// A bill's points: the credited `pointsEarned` once approved, otherwise
  /// the expected points at the bill's own rate (or [rupeesPerPoint], or the
  /// default for bills saved before rates existed).
  static double forBill(Map<String, dynamic> bill, {int? rupeesPerPoint}) {
    final earned = (bill['pointsEarned'] as num?)?.toDouble() ?? 0;
    if (earned > 0) return earned;
    final amount = (bill['amount'] as num?)?.toDouble() ?? 0;
    final rate = sanitize(
      bill['rupeesPerPoint'],
      fallback: rupeesPerPoint ?? defaultRupeesPerPoint,
    );
    return pointsFor(amount, rate);
  }

  /// "1 pt / ₹5,000"
  static String label(int rupeesPerPoint) =>
      '1 pt / ₹${NumberFormat.decimalPattern('en_IN').format(rupeesPerPoint)}';

  /// "₹5,000"
  static String rupees(int rupeesPerPoint) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(rupeesPerPoint)}';
}
