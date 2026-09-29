import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/neon_theme.dart';
import '../core/theme/framer_motion.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../services/haptic_service.dart';
import '../widgets/upi_qr_scanner_modal.dart';
import '../widgets/upi_payment_modal.dart';
import '../widgets/tactical_sidebar.dart';
import 'history_screen.dart';
import 'rules_rewards_screen.dart';

class PaymentsScreen extends StatefulWidget {
  final bool isEmbedded;
  const PaymentsScreen({super.key, this.isEmbedded = false});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _recentPayees = [
    {
      'name': 'IndianOil Bunk',
      'upiId': 'iocl.puttur@oksbi',
      'icon': Icons.local_gas_station_rounded,
      'color': const Color(0xFFF59E0B),
      'category': PaymentCategory.fuel,
      'amount': 350.0,
    },
    {
      'name': 'Sri Krishna Chai',
      'upiId': 'srikrishna.tea@paytm',
      'icon': Icons.coffee_rounded,
      'color': const Color(0xFF10B981),
      'category': PaymentCategory.food,
      'amount': 30.0,
    },
    {
      'name': 'Star Auto Garage',
      'upiId': 'star.garage@oksbi',
      'icon': Icons.build_circle_rounded,
      'color': const Color(0xFF38BDF8),
      'category': PaymentCategory.maintenance,
      'amount': 650.0,
    },
    {
      'name': 'NH Fastag Toll',
      'upiId': 'fastag.nhai@icici',
      'icon': Icons.toll_rounded,
      'color': const Color(0xFFA78BFA),
      'category': PaymentCategory.toll,
      'amount': 45.0,
    },
    {
      'name': 'EV Charger Hub',
      'upiId': 'evpower.charge@ybl',
      'icon': Icons.ev_station_rounded,
      'color': const Color(0xFF00FF9D),
      'category': PaymentCategory.fuel,
      'amount': 180.0,
    },
  ];

  void _showRedeemCoinsSheet(BuildContext context, TripProvider trip, String driverUpi) {
    int selectedPoints = trip.totalClaimedPoints >= 200 ? 200 : trip.totalClaimedPoints;
    final TextEditingController upiCtrl = TextEditingController(text: driverUpi);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text("Redeem Coins to UPI Cash", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: NeonColors.primaryGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text("${trip.totalClaimedPoints} pts", style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "Convert safe driving reward points directly into instant cash deposited into your UPI account (10 pts = ₹1 INR).",
                style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 11.5),
              ),
              const SizedBox(height: 18),

              // Quick Tier Selector
              Row(
                children: [100, 200, 500, 1000].map((pts) {
                  final bool isSelected = selectedPoints == pts;
                  final bool isAvailable = trip.totalClaimedPoints >= pts;
                  return Expanded(
                    child: FramerPressable(
                      onTap: isAvailable ? () => setSheetState(() => selectedPoints = pts) : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? NeonColors.primaryGreen.withOpacity(0.2)
                              : (isAvailable ? const Color(0xFF161B22) : Colors.white.withOpacity(0.02)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? NeonColors.primaryGreen : (isAvailable ? NeonColors.border : Colors.white10),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text("$pts pts", style: GoogleFonts.spaceGrotesk(color: isAvailable ? Colors.white : Colors.white24, fontSize: 11, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text("₹${(pts / 10).toInt()}", style: GoogleFonts.outfit(color: isAvailable ? NeonColors.primaryGreen : Colors.white24, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Destination UPI ID
              Text("Credited to UPI ID", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeonColors.border),
                ),
                child: TextField(
                  controller: upiCtrl,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.account_balance_wallet_rounded, color: NeonColors.primaryGreen, size: 18),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: trip.totalClaimedPoints >= selectedPoints && selectedPoints > 0
                      ? () async {
                          final destination = upiCtrl.text.trim();
                          if (destination.isEmpty) return;
                          Navigator.pop(ctx);
                          final txn = await trip.redeemRewardCoinsToUpi(pointsToRedeem: selectedPoints, upiId: destination);
                          if (txn != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Redeemed +₹${txn.amount.toInt()} into $destination!"),
                                backgroundColor: NeonColors.primaryGreen,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonColors.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("REDEEM ₹${(selectedPoints / 10).toInt()} CASH VIA UPI", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMyQrModal(BuildContext context, String driverName, String driverUpi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text("My Driver UPI QR Code", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text("Scan to pay customer tips or fuel reimbursements", style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 11.5)),
            const SizedBox(height: 20),

            // QR Card Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: NeonColors.primaryGreen.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(6)),
                        child: Text("BHIM", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                      ),
                      const SizedBox(width: 6),
                      Text("UPI", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tactical QR Matrix representation
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Icon(Icons.qr_code_2_rounded, size: 150, color: Colors.blueGrey.shade900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(driverName, style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(driverUpi, style: GoogleFonts.spaceGrotesk(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: driverUpi));
                      HapticService.lightImpact();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("UPI ID copied to clipboard!"), backgroundColor: NeonColors.primaryGreen),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                    label: Text("Copy UPI ID", style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: NeonColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticService.lightImpact();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("QR Code ready to share!"), backgroundColor: NeonColors.primaryGreen),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 16, color: Colors.black),
                    label: Text("Share QR", style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeonColors.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final p = auth.profile;
    final String driverUpi = "${p.name.toLowerCase().replaceAll(' ', '.')}@oksbi";

    return Scaffold(
      key: _scaffoldKey,
      drawer: widget.isEmbedded ? const TacticalSidebar() : null,
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: NeonColors.card,
        elevation: 0,
        toolbarHeight: 56,
        leading: widget.isEmbedded
            ? IconButton(
                icon: Icon(Icons.menu_rounded, color: NeonColors.text, size: 22),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: NeonColors.text, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          "UPI Payments Hub",
          style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: NeonColors.primaryGreen, size: 22),
            onPressed: () => _showMyQrModal(context, p.name, driverUpi),
          ),
          IconButton(
            icon: Icon(Icons.history_rounded, color: NeonColors.text, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18, 16, 18, widget.isEmbedded ? 150 : 30),
        children: [
          // 1. Driver Account & Quick Balance Card
          _buildBalanceCard(trip, p, driverUpi).framerSlideIn(delayMs: 40),

          const SizedBox(height: 20),

          // 2. Google Pay / PhonePe Quick Transfer Grid
          _buildQuickTransferGrid(context, trip, driverUpi).framerSlideIn(delayMs: 80),

          const SizedBox(height: 22),

          // 3. Recent Payees & Contacts Horizontal List
          _buildRecentPayeesSection(context).framerSlideIn(delayMs: 120),

          const SizedBox(height: 22),

          // 4. Quick Category Presets (Fuel, Chai, Maintenance, Toll)
          _buildCategoryPresetsSection(context).framerSlideIn(delayMs: 160),

          const SizedBox(height: 22),

          // 5. Recent UPI Transactions List
          _buildRecentTransactionsSection(context, trip).framerSlideIn(delayMs: 200),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(TripProvider trip, dynamic p, String driverUpi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: NeonColors.primaryGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: NeonColors.primaryGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "PRIMARY UPI ID",
                    style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "SBI · ****4821",
                  style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            driverUpi,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),

          // Savings vs Spending Mini Matrix
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NET SAVINGS", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      "₹${trip.netSavings.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TODAY'S SPENT", style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF59E0B), fontSize: 9.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      "₹${trip.totalSpending.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("REWARD COINS", style: GoogleFonts.spaceGrotesk(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      "${trip.totalClaimedPoints}",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTransferGrid(BuildContext context, TripProvider trip, String driverUpi) {
    return Row(
      children: [
        _transferButton(
          title: "Scan & Pay",
          icon: Icons.qr_code_scanner_rounded,
          color: NeonColors.primaryGreen,
          onTap: () => UpiQrScannerModal.show(context),
        ),
        const SizedBox(width: 10),
        _transferButton(
          title: "To UPI ID",
          icon: Icons.alternate_email_rounded,
          color: const Color(0xFF38BDF8),
          onTap: () => UpiPaymentModal.show(
            context,
            payeeName: "Direct UPI Recipient",
            payeeUpiId: "recipient@oksbi",
            defaultAmount: 100.0,
            category: PaymentCategory.upiTransfer,
          ),
        ),
        const SizedBox(width: 10),
        _transferButton(
          title: "Redeem Coins",
          icon: Icons.stars_rounded,
          color: Colors.amber,
          onTap: () => _showRedeemCoinsSheet(context, trip, driverUpi),
        ),
        const SizedBox(width: 10),
        _transferButton(
          title: "My QR Code",
          icon: Icons.qr_code_2_rounded,
          color: const Color(0xFFA78BFA),
          onTap: () => _showMyQrModal(context, "Driver", driverUpi),
        ),
      ],
    );
  }

  Widget _transferButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: FramerPressable(
        onTap: () {
          HapticService.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NeonColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPayeesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Payees & Fuel Bunks",
          style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _recentPayees.map((p) {
              final Color col = p['color'] as Color;
              return FramerPressable(
                onTap: () {
                  HapticService.lightImpact();
                  UpiPaymentModal.show(
                    context,
                    payeeName: p['name'],
                    payeeUpiId: p['upiId'],
                    defaultAmount: p['amount'],
                    category: p['category'],
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 85,
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: col.withOpacity(0.4)),
                        ),
                        child: Icon(p['icon'] as IconData, color: col, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p['name'],
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPresetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Payment Presets",
          style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _presetCard(
              context,
              title: "Fuel Refill",
              subtitle: "IndianOil Petrol",
              amount: 500.0,
              icon: Icons.local_gas_station_rounded,
              color: const Color(0xFFF59E0B),
              category: PaymentCategory.fuel,
              upiId: 'iocl.puttur@oksbi',
            ),
            const SizedBox(width: 10),
            _presetCard(
              context,
              title: "Tea & Chai",
              subtitle: "Snacks & Break",
              amount: 30.0,
              icon: Icons.coffee_rounded,
              color: const Color(0xFF10B981),
              category: PaymentCategory.food,
              upiId: 'srikrishna.tea@paytm',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _presetCard(
              context,
              title: "Fastag Toll",
              subtitle: "Highway Corridor",
              amount: 45.0,
              icon: Icons.toll_rounded,
              color: const Color(0xFFA78BFA),
              category: PaymentCategory.toll,
              upiId: 'fastag.nhai@icici',
            ),
            const SizedBox(width: 10),
            _presetCard(
              context,
              title: "Auto Repairs",
              subtitle: "Parts & Service",
              amount: 650.0,
              icon: Icons.build_circle_rounded,
              color: const Color(0xFF38BDF8),
              category: PaymentCategory.maintenance,
              upiId: 'star.garage@oksbi',
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
    required Color color,
    required PaymentCategory category,
    required String upiId,
  }) {
    return Expanded(
      child: FramerPressable(
        onTap: () {
          HapticService.lightImpact();
          UpiPaymentModal.show(
            context,
            payeeName: title,
            payeeUpiId: upiId,
            defaultAmount: amount,
            category: category,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NeonColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800), maxLines: 1),
                    Text("₹${amount.toInt()}", style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context, TripProvider trip) {
    final expenses = trip.expenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent UPI Payments",
              style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              child: Text(
                "View History",
                style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (expenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(18), border: Border.all(color: NeonColors.border)),
            child: Center(
              child: Text("No UPI payments logged yet.", style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12)),
            ),
          )
        else
          ...expenses.take(4).map((txn) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NeonColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.title,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "UPI UTR: ${txn.utrNumber}",
                          style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "- ₹${txn.amount.toStringAsFixed(0)}",
                        style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "SUCCESS",
                          style: GoogleFonts.spaceGrotesk(color: const Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
