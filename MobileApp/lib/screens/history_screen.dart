import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/theme/hardware_theme.dart';
import '../models/trip_model.dart';
import '../models/transaction_model.dart';
import '../providers/trip_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_service.dart';
import '../widgets/upi_qr_scanner_modal.dart';
import '../widgets/upi_payment_modal.dart';

/// Unified model for the Chronological Price & Financial Audit Ledger
class LedgerAuditEntry {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final DateTime timestamp;
  final String category;
  final String? meta;
  final IconData icon;
  final Color color;
  final DriverTrip? tripRef;
  final PaymentTransaction? txnRef;

  const LedgerAuditEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.timestamp,
    required this.category,
    this.meta,
    required this.icon,
    required this.color,
    this.tripRef,
    this.txnRef,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // 0: Price Audit (Chronological Price History), 1: Missions & Fares, 2: Expenses
  int _selectedTab = 0;
  String _priceFilter = 'ALL'; // 'ALL', 'CREDIT', 'DEBIT'

  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);
    final history = tripProv.history;
    final expenses = tripProv.expenses;
    final customIncomes = tripProv.customIncomes;

    final auditEntries = _buildAuditEntries(history, expenses, customIncomes);

    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, tripProv),
            _buildFinancialRibbon(tripProv),
            _buildSegmentedTabs(auditEntries.length, history.length, expenses.length),
            Expanded(
              child: _buildTabContent(context, tripProv, auditEntries, history, expenses),
            ),
          ],
        ),
      ),
    );
  }

  /// Consolidates all earnings, trips, and expenses into a unified chronological price history
  List<LedgerAuditEntry> _buildAuditEntries(
    List<DriverTrip> trips,
    List<PaymentTransaction> expenses,
    List<PaymentTransaction> customIncomes,
  ) {
    final List<LedgerAuditEntry> entries = [];

    // 1. Mission / Trip Fare Credits
    for (final trip in trips) {
      final title = trip.deliveryTo != null && trip.deliveryTo!.isNotEmpty
          ? "Mission Payout: ${trip.deliveryTo}"
          : "Sector Trip Fare // ${trip.id.substring(0, math.min(trip.id.length, 10))}";
      
      final sub = "${trip.distanceKm.toStringAsFixed(1)} KM • Score: ${trip.safetyScore.toInt()}%";

      entries.add(
        LedgerAuditEntry(
          id: trip.id,
          title: title,
          subtitle: sub,
          amount: trip.earnedPayout,
          isIncome: true,
          timestamp: trip.startTime,
          category: "MISSION FARE",
          meta: "Base ₹40 + Dist ₹${(trip.distanceKm * 15.0).toInt()} + Bonus",
          icon: Icons.local_shipping_rounded,
          color: HardwarePalette.signalEmerald,
          tripRef: trip,
        ),
      );
    }

    // 2. Custom Rewards & Incentive Incomes
    for (final inc in customIncomes) {
      entries.add(
        LedgerAuditEntry(
          id: inc.id,
          title: inc.title.isNotEmpty ? inc.title : "Reward Coin Payout",
          subtitle: "UPI: ${inc.upiId ?? 'Direct Account Credit'}",
          amount: inc.amount,
          isIncome: true,
          timestamp: inc.timestamp,
          category: "REWARD CREDIT",
          meta: "UTR: ${inc.utrNumber}",
          icon: Icons.stars_rounded,
          color: const Color(0xFF10B981),
          txnRef: inc,
        ),
      );
    }

    // 3. Fuel & Operation Expenses (Debits)
    for (final exp in expenses) {
      IconData icon = Icons.receipt_long_rounded;
      Color color = HardwarePalette.criticalCrimson;

      switch (exp.category) {
        case PaymentCategory.fuel:
          icon = Icons.local_gas_station_rounded;
          color = HardwarePalette.cautionAmber;
          break;
        case PaymentCategory.food:
          icon = Icons.coffee_rounded;
          color = const Color(0xFF10B981);
          break;
        case PaymentCategory.maintenance:
          icon = Icons.build_circle_rounded;
          color = const Color(0xFF38BDF8);
          break;
        case PaymentCategory.toll:
          icon = Icons.toll_rounded;
          color = const Color(0xFFA78BFA);
          break;
        case PaymentCategory.parking:
          icon = Icons.local_parking_rounded;
          color = const Color(0xFFF59E0B);
          break;
        case PaymentCategory.supplies:
          icon = Icons.inventory_2_rounded;
          color = const Color(0xFF06B6D4);
          break;
        case PaymentCategory.upiTransfer:
          icon = Icons.send_rounded;
          color = const Color(0xFF6366F1);
          break;
        case PaymentCategory.other:
        default:
          icon = Icons.account_balance_wallet_rounded;
          color = const Color(0xFFF43F5E);
          break;
      }

      entries.add(
        LedgerAuditEntry(
          id: exp.id,
          title: exp.title,
          subtitle: "${exp.category.name.toUpperCase()} • ${exp.paymentMethod}",
          amount: exp.amount,
          isIncome: false,
          timestamp: exp.timestamp,
          category: exp.category.name.toUpperCase(),
          meta: "UTR: ${exp.utrNumber}",
          icon: icon,
          color: color,
          txnRef: exp,
        ),
      );
    }

    // Sort newest first
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Widget _buildHeader(BuildContext context, TripProvider trip) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        border: Border(bottom: BorderSide(color: HardwarePalette.matrixBorderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HardwarePalette.debossedSlot,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded, color: HardwarePalette.silkscreenDark, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PRICE & TELEMETRY LEDGER",
                    style: HardwareTypography.ndotHeader(
                      fontSize: 14,
                      color: HardwarePalette.silkscreenDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "FINANCIAL AUDIT & FARE SETTLEMENTS",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: HardwarePalette.silkscreenSubtle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: "Quick Scan & Pay",
                icon: const Icon(Icons.qr_code_scanner_rounded, color: HardwarePalette.signalEmerald, size: 22),
                onPressed: () => UpiQrScannerModal.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// High-Tech Financial Ribbon showing Net Driver Profit & Cashflow
  Widget _buildFinancialRibbon(TripProvider trip) {
    final earned = trip.totalIncome;
    final spent = trip.totalSpending;
    final netProfit = trip.netSavings;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "FINANCIAL RUNNING BALANCE",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: HardwarePalette.silkscreenSubtle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: HardwarePalette.signalEmerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "LIVE AUDIT",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: HardwarePalette.signalEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: "TOTAL EARNINGS",
                  value: "+₹${earned.toInt()}",
                  color: HardwarePalette.signalEmerald,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              Container(width: 1, height: 38, color: HardwarePalette.matrixBorderLight),
              Expanded(
                child: _buildMetricTile(
                  label: "ROAD EXPENSES",
                  value: "-₹${spent.toInt()}",
                  color: HardwarePalette.criticalCrimson,
                  icon: Icons.trending_down_rounded,
                ),
              ),
              Container(width: 1, height: 38, color: HardwarePalette.matrixBorderLight),
              Expanded(
                child: _buildMetricTile(
                  label: "NET MARGIN",
                  value: "₹${netProfit.toInt()}",
                  color: const Color(0xFF38BDF8),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: HardwarePalette.silkscreenSubtle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: HardwareTypography.ndotNumber(
              fontSize: 15,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(int auditCount, int missionsCount, int expensesCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: HardwarePalette.debossedSlot,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HardwarePalette.matrixBorderLight),
      ),
      child: Row(
        children: [
          _buildTabButton(0, "PRICE AUDIT ($auditCount)"),
          _buildTabButton(1, "FARES ($missionsCount)"),
          _buildTabButton(2, "EXPENSES ($expensesCount)"),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? HardwarePalette.milledSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? HardwarePalette.silkscreenDark : HardwarePalette.silkscreenSubtle,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    TripProvider trip,
    List<LedgerAuditEntry> auditEntries,
    List<DriverTrip> history,
    List<PaymentTransaction> expenses,
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildPriceAuditTab(auditEntries);
      case 1:
        return _buildMissionsContent(context, trip, history);
      case 2:
      default:
        return _buildExpensesContent(context, trip, expenses);
    }
  }

  // --------------------------------------------------------------------------
  // TAB 0: CHRONOLOGICAL PRICE AUDIT LEDGER
  // --------------------------------------------------------------------------
  Widget _buildPriceAuditTab(List<LedgerAuditEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              "NO PRICE TRANSACTIONS LOGGED",
              style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
            ),
            const SizedBox(height: 4),
            Text(
              "Complete missions or log fuel expenses to build your ledger.",
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: HardwarePalette.silkscreenSubtle),
            ),
          ],
        ),
      );
    }

    final filtered = entries.where((e) {
      if (_priceFilter == 'CREDIT') return e.isIncome;
      if (_priceFilter == 'DEBIT') return !e.isIncome;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip("ALL", "ALL TRANSACTIONS"),
              const SizedBox(width: 8),
              _buildFilterChip("CREDIT", "CREDITS (+₹)"),
              const SizedBox(width: 8),
              _buildFilterChip("DEBIT", "DEBITS (-₹)"),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final entry = filtered[i];
              return _buildAuditEntryCard(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final active = _priceFilter == key;
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _priceFilter = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? HardwarePalette.silkscreenDark : HardwarePalette.milledSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? HardwarePalette.silkscreenDark : HardwarePalette.matrixBorderLight,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : HardwarePalette.silkscreenSubtle,
          ),
        ),
      ),
    );
  }

  Widget _buildAuditEntryCard(LedgerAuditEntry entry) {
    final dateStr = DateFormat('dd MMM • hh:mm a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: entry.isIncome
                  ? HardwarePalette.signalEmerald.withOpacity(0.12)
                  : entry.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              entry.icon,
              color: entry.isIncome ? HardwarePalette.signalEmerald : entry.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: HardwarePalette.silkscreenDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: HardwarePalette.debossedSlot,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: HardwarePalette.matrixBorderLight),
                      ),
                      child: Text(
                        entry.category,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: entry.isIncome ? HardwarePalette.signalEmerald : entry.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        color: HardwarePalette.silkscreenSubtle,
                      ),
                    ),
                  ],
                ),
                if (entry.meta != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.meta!,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      color: HardwarePalette.silkscreenSubtle.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Price Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.isIncome ? "+ ₹${entry.amount.toInt()}" : "- ₹${entry.amount.toInt()}",
                style: HardwareTypography.ndotNumber(
                  fontSize: 17,
                  color: entry.isIncome ? HardwarePalette.signalEmerald : HardwarePalette.criticalCrimson,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.isIncome ? "SETTLED" : "PAID",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: HardwarePalette.silkscreenSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: MISSIONS & FARE TELEMETRY PUNCH-CARDS
  // --------------------------------------------------------------------------
  Widget _buildMissionsContent(BuildContext context, TripProvider trip, List<DriverTrip> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 42, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              "NO COMPLETED MISSIONS LOGGED",
              style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      itemCount: history.length,
      itemBuilder: (ctx, i) {
        final item = history[i];
        return _buildTripPunchCard(item);
      },
    );
  }

  Widget _buildTripPunchCard(DriverTrip trip) {
    final score = trip.safetyScore;
    final dateStr = DateFormat('dd MMM • hh:mm a').format(trip.startTime);
    final fare = trip.earnedPayout;

    // Price components
    final baseFare = 40.0;
    final distanceRate = trip.distanceKm * 15.0;
    final safetyBonus = score >= 80 ? (score >= 95 ? 35.0 : 20.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Trip ID + Price Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MISSION // ${trip.id.substring(0, math.min(trip.id.length, 12)).toUpperCase()}",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: HardwarePalette.silkscreenSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trip.deliveryTo != null && trip.deliveryTo!.isNotEmpty
                        ? trip.deliveryTo!
                        : "Sector Logistics Mission",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: HardwarePalette.silkscreenDark,
                    ),
                  ),
                ],
              ),
              // Big Price Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HardwarePalette.signalEmerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HardwarePalette.signalEmerald.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee_rounded, size: 14, color: HardwarePalette.signalEmerald),
                    Text(
                      "+₹${fare.toInt()}",
                      style: HardwareTypography.ndotNumber(
                        fontSize: 18,
                        color: HardwarePalette.signalEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Price Breakdown Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HardwarePalette.debossedSlot,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HardwarePalette.matrixBorderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceChip("BASE", "₹${baseFare.toInt()}"),
                Text("•", style: TextStyle(color: HardwarePalette.matrixBorderLight)),
                _buildPriceChip("DIST (₹15/KM)", "₹${distanceRate.toInt()}"),
                Text("•", style: TextStyle(color: HardwarePalette.matrixBorderLight)),
                _buildPriceChip("SCORE BONUS", "+₹${safetyBonus.toInt()}"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Telemetry Row: Date, KM, Score
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(dateStr, style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF64748B))),
              const SizedBox(width: 12),
              const Icon(Icons.navigation_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text("${trip.distanceKm.toStringAsFixed(1)} KM", style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF64748B))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: score >= 80
                      ? HardwarePalette.signalEmerald.withOpacity(0.12)
                      : HardwarePalette.cautionAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${score.toInt()}% SAFETY",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: score >= 80 ? HardwarePalette.signalEmerald : HardwarePalette.cautionAmber,
                  ),
                ),
              ),
            ],
          ),

          if (trip.events.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: trip.events.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    e.type.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(fontSize: 8.5, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            color: HardwarePalette.silkscreenSubtle,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: HardwarePalette.silkscreenDark,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: EXPENSES (DEBIT LOGS)
  // --------------------------------------------------------------------------
  Widget _buildExpensesContent(BuildContext context, TripProvider trip, List<PaymentTransaction> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              "NO EXPENSES LOGGED",
              style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      itemCount: expenses.length,
      itemBuilder: (ctx, i) {
        final exp = expenses[i];
        final dateStr = DateFormat('dd MMM, hh:mm a').format(exp.timestamp);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HardwarePalette.milledSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.title.toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${exp.category.name.toUpperCase()} • ${exp.paymentMethod}",
                      style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: HardwarePalette.silkscreenSubtle),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$dateStr • UTR: ${exp.utrNumber}",
                      style: GoogleFonts.jetBrainsMono(fontSize: 8.5, color: HardwarePalette.silkscreenSubtle.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "- ₹${exp.amount.toInt()}",
                    style: HardwareTypography.ndotNumber(fontSize: 18, color: HardwarePalette.criticalCrimson),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "PAID VIA UPI",
                    style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenSubtle),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
