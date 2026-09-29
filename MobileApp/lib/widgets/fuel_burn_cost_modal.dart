import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/hardware_theme.dart';
import '../providers/trip_provider.dart';
import '../services/haptic_service.dart';

class FuelBurnCostModal {
  static void show(BuildContext context) {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _FuelBurnCostSheet(),
    );
  }
}

class _FuelBurnCostSheet extends StatelessWidget {
  const _FuelBurnCostSheet();

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);

    final double fuelWasted = trip.fuelWastedInr;
    final double tireWear = trip.tireWearInr;
    final double fuelSaved = trip.fuelSavedInr;
    final double netSavings = trip.netSavingsInr;
    final bool isNetPositive = trip.isNetProfit;
    final int rebatePercent = trip.phydDiscountPercent;
    final double annualRebate = trip.annualInsuranceRebateInr;
    final double netPremium = trip.netAdjustedPremiumInr;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: HardwarePalette.silkscreenSubtle.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Text(
                      "₹",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "REAL-TIME COST BURN METER",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: HardwarePalette.silkscreenDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Driving Physics Converted to Rupee (₹) P&L",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: HardwarePalette.silkscreenSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: HardwarePalette.silkscreenSubtle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Net P&L Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNetPositive
                      ? [const Color(0xFF065F46), const Color(0xFF047857)]
                      : [const Color(0xFF991B1B), const Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isNetPositive ? const Color(0xFF10B981) : Colors.red).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNetPositive ? "NET CRUISE PROFIT" : "NET DRIVING PENALTY",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${isNetPositive ? '+' : ''}₹${netSavings.toStringAsFixed(2)}",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isNetPositive ? "ECO PROFITABLE" : "EXCESS BURN",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3 Economics Breakdown Items
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: "FUEL WASTED",
                    amount: "-₹${fuelWasted.toStringAsFixed(1)}",
                    desc: "${trip.harshBrakingCount} harsh brakes",
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: "TIRE WEAR",
                    amount: "-₹${tireWear.toStringAsFixed(1)}",
                    desc: "Tread penalty",
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: "ECO SAVED",
                    amount: "+₹${fuelSaved.toStringAsFixed(1)}",
                    desc: "Steady cruise",
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // IRDAI Pay-How-You-Drive Scorecard
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HardwarePalette.chalkChassis,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HardwarePalette.matrixBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "IRDAI PHYD SCORECARD",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: HardwarePalette.silkscreenDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "TIER 1 · $rebatePercent% REBATE",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildScoreRow("Annual Base Premium:", "₹18,500 / yr"),
                  const SizedBox(height: 6),
                  _buildScoreRow("Safe Driver Rebate ($rebatePercent%):", "-₹${annualRebate.toInt()} / yr", isGreen: true),
                  const SizedBox(height: 6),
                  const Divider(height: 10),
                  const SizedBox(height: 6),
                  _buildScoreRow("Net Adjusted Annual Premium:", "₹${netPremium.toInt()} / yr", isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String amount,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: HardwarePalette.chalkChassis,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HardwarePalette.matrixBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: HardwarePalette.silkscreenSubtle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: HardwarePalette.silkscreenSubtle,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String value, {bool isGreen = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? HardwarePalette.silkscreenDark : HardwarePalette.silkscreenSubtle,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isGreen
                ? const Color(0xFF059669)
                : (isBold ? HardwarePalette.silkscreenDark : HardwarePalette.silkscreenSubtle),
          ),
        ),
      ],
    );
  }
}
