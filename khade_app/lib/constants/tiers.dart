import 'package:flutter/material.dart';

enum TierName { bronze, silver, gold }

class TierData {
  const TierData({
    required this.name,
    required this.color,
    required this.bgColor,
    required this.textColor,
    required this.icon,
    required this.minBookings,
    required this.maxBookings,
    required this.walletCashback,
    required this.perks,
  });

  final String name;
  final Color color;
  final Color bgColor;
  final Color textColor;
  final String icon;
  final int minBookings;
  final int maxBookings;
  final double walletCashback;
  final List<String> perks;
}

class KhadeTiers {
  KhadeTiers._();

  static const bronze = TierData(
    name: 'Bronze',
    color: Color(0xFFCD7F32),
    bgColor: Color(0xFFFDF0E8),
    textColor: Color(0xFF8B4513),
    icon: '🥉',
    minBookings: 0,
    maxBookings: 4,
    walletCashback: 0,
    perks: ['Access to all providers', 'Cash & Wallet payments', 'Book up to 1 service at a time'],
  );

  static const silver = TierData(
    name: 'Silver',
    color: Color(0xFFA8A9AD),
    bgColor: Color(0xFFF5F5F5),
    textColor: Color(0xFF4A4A4A),
    icon: '🥈',
    minBookings: 5,
    maxBookings: 9,
    walletCashback: 0.03,
    perks: ['Everything in Bronze', '3% cashback on wallet payments', 'Instant booking confirmation', '5% off group bookings'],
  );

  static const gold = TierData(
    name: 'Gold',
    color: Color(0xFFC9A84C),
    bgColor: Color(0xFFFAF5E9),
    textColor: Color(0xFF8B6914),
    icon: '✦',
    minBookings: 10,
    maxBookings: 999999,
    walletCashback: 0.05,
    perks: ['Everything in Silver', '5% cashback on wallet payments', 'Priority customer support', '10% off group bookings'],
  );

  static TierData data(TierName tier) => switch (tier) {
        TierName.bronze => bronze,
        TierName.silver => silver,
        TierName.gold => gold,
      };

  static TierName fromBookings(int totalBookings) {
    if (totalBookings >= 10) return TierName.gold;
    if (totalBookings >= 5) return TierName.silver;
    return TierName.bronze;
  }

  static TierName fromString(String? tier) {
    switch ((tier ?? 'bronze').toLowerCase()) {
      case 'gold':
        return TierName.gold;
      case 'silver':
        return TierName.silver;
      default:
        return TierName.bronze;
    }
  }
}
