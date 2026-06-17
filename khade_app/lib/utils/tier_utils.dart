import '../constants/tiers.dart';

class TierUtils {
  TierUtils._();

  static TierName tierFromBookings(int bookings) => KhadeTiers.fromBookings(bookings);

  static TierName tierFromString(String? tier) => KhadeTiers.fromString(tier);

  static int cashbackPercent(String? tier) =>
      (KhadeTiers.data(KhadeTiers.fromString(tier)).walletCashback * 100).round();

  static String cashbackLabel(String? tier) {
    final t = KhadeTiers.fromString(tier);
    final pct = KhadeTiers.data(t).walletCashback;
    if (pct == 0) return 'Pay with wallet on Silver+ for 3% cashback';
    return '${KhadeTiers.data(t).name} · ${(pct * 100).round()}% cashback on wallet payments';
  }

  static String displayName(String? tier) => KhadeTiers.data(KhadeTiers.fromString(tier)).name;

  static String tierIcon(String? tier) => KhadeTiers.data(KhadeTiers.fromString(tier)).icon;

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static int bookingsToNextTier(int totalBookings) {
    final current = KhadeTiers.fromBookings(totalBookings);
    if (current == TierName.gold) return 0;
    final next = current == TierName.bronze ? KhadeTiers.silver : KhadeTiers.gold;
    return next.minBookings - totalBookings;
  }

  static double tierProgress(int totalBookings) {
    final current = KhadeTiers.fromBookings(totalBookings);
    if (current == TierName.gold) return 1;
    final cur = KhadeTiers.data(current);
    final next = current == TierName.bronze ? KhadeTiers.silver : KhadeTiers.gold;
    return ((totalBookings - cur.minBookings) / (next.minBookings - cur.minBookings)).clamp(0.0, 1.0);
  }
}
