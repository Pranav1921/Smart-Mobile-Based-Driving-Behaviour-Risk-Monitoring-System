import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../core/theme/hardware_theme.dart';
import '../models/order_model.dart';
import '../providers/trip_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../services/haptic_service.dart';
import '../services/map_navigation_service.dart';
import '../services/sound_effect_service.dart';
import '../widgets/mechanical_mission_slider.dart';
import '../widgets/mechanical_lever_switch.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMap;
  const OrdersScreen({super.key, this.onNavigateToMap});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingOrders = false;
  bool _autoDispatch = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshOrders(TripProvider trip) async {
    setState(() => _isLoadingOrders = true);
    HapticService.lightImpact();
    SoundEffectService.playRelayLatch();
    await Future.delayed(const Duration(milliseconds: 500));
    trip.assignRandomOrder();
    if (mounted) setState(() => _isLoadingOrders = false);
  }

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final active = trip.activeOrder;
    final available = trip.availableOrders;

    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      appBar: AppBar(
        backgroundColor: HardwarePalette.milledSurface,
        elevation: 0,
        toolbarHeight: 56,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: HardwarePalette.silkscreenDark, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          "DISPATCH DECK // LOGISTICS",
          style: HardwareTypography.ndotHeader(
            fontSize: 14,
            color: HardwarePalette.silkscreenDark,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Request Sector Mission",
            icon: const Icon(Icons.refresh_rounded, color: HardwarePalette.signalEmerald, size: 22),
            onPressed: () => _refreshOrders(trip),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: HardwarePalette.debossedSlot,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: HardwarePalette.milledSurface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: HardwarePalette.silkscreenDark,
              unselectedLabelColor: HardwarePalette.silkscreenSubtle,
              labelStyle: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w800),
              tabs: [
                Tab(text: "AVAILABLE (${available.length})"),
                Tab(text: active != null ? "ACTIVE (1)" : "ACTIVE (0)"),
                const Tab(text: "AUDIT LOG"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Available Missions
          _buildAvailableOrdersTab(trip, available),

          // TAB 2: Active Dispatch Mission
          _buildActiveOrderTab(trip, active),

          // TAB 3: Audit Log & Payouts
          _buildHistoryTab(trip),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: AVAILABLE MISSIONS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAvailableOrdersTab(TripProvider trip, List<DeliveryOrder> available) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: [
        // Auto-dispatch toggle lever
        MechanicalLeverSwitch(
          value: _autoDispatch,
          label: "AUTO-DISPATCH RADAR",
          activeLabel: "AUTO-ASSIGN ON",
          inactiveLabel: "MANUAL ONLY",
          onChanged: (v) => setState(() => _autoDispatch = v),
        ),
        const SizedBox(height: 14),

        if (available.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HardwarePalette.milledSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HardwarePalette.matrixBorderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, color: Color(0xFF94A3B8), size: 40),
                const SizedBox(height: 10),
                Text(
                  "NO MISSIONS QUEUED",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: HardwarePalette.silkscreenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tap refresh to poll new dispatch packets from sector hub.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 12, color: HardwarePalette.silkscreenMuted),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _refreshOrders(trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HardwarePalette.signalEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: Text("POLL MISSIONS", style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          )
        else
          ...available.map((order) => _buildOrderDispatchCard(trip, order)),
      ],
    );
  }

  Widget _buildOrderDispatchCard(TripProvider trip, DeliveryOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HardwarePalette.debossedSlot,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.id,
                  style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
                ),
              ),
              Text(
                "₹${order.payoutAmount.toInt()}",
                style: HardwareTypography.ndotNumber(fontSize: 22, color: HardwarePalette.signalEmerald),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.dropAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
          ),
          const SizedBox(height: 4),
          Text(
            "FROM: ${order.pickupAddress}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: HardwarePalette.silkscreenMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text("Est. ${order.estimatedTimeMinutes} mins", style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF64748B))),
              const SizedBox(width: 12),
              const Icon(Icons.navigation_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text("${order.distanceKm} km", style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 14),
          MechanicalMissionSlider(
            height: 48,
            label: "SWIPE TO ACCEPT",
            completedLabel: "ACCEPTED",
            onAction: () async {
              trip.acceptOrder(order);
              await Future.delayed(const Duration(milliseconds: 300));
              _tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: ACTIVE ORDER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActiveOrderTab(TripProvider trip, DeliveryOrder? active) {
    if (active == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF94A3B8), size: 48),
            const SizedBox(height: 12),
            Text(
              "NO ACTIVE DISPATCH MISSION",
              style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
            ),
            const SizedBox(height: 6),
            Text(
              "Select and slide the lever on an available mission to engage route.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: HardwarePalette.silkscreenMuted),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: HardwarePalette.milledSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HardwarePalette.signalEmerald.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: HardwarePalette.signalEmerald.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "DISPATCH IN TRANSIT // ${active.id}",
                      style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold, color: HardwarePalette.signalEmerald),
                    ),
                  ),
                  Text(
                    "₹${active.payoutAmount.toInt()}",
                    style: HardwareTypography.ndotNumber(fontSize: 22, color: HardwarePalette.signalEmerald),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Delivery Driver Profile Card with direct Call Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: HardwarePalette.debossedSlot,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HardwarePalette.matrixBorderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HardwarePalette.signalEmerald.withOpacity(0.15),
                        border: Border.all(color: HardwarePalette.signalEmerald, width: 1.5),
                      ),
                      child: Center(
                        child: Icon(Icons.delivery_dining_rounded, color: HardwarePalette.signalEmerald, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active.driverName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: HardwarePalette.silkscreenDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${active.driverPhone} • ${active.driverAddress}",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10.5,
                              color: HardwarePalette.silkscreenMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dedicated Call Button
                    GestureDetector(
                      onTap: () async {
                        final dialed = await active.callDriver();
                        if (!dialed && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Calling driver at ${active.driverPhone}..."),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: HardwarePalette.signalEmerald,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.call_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "CALL",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                active.dropAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
              ),
              const SizedBox(height: 4),
              Text(
                "PICKUP: ${active.pickupAddress}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: HardwarePalette.silkscreenMuted),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "📦 ${active.packageItems} • Cust: ${active.customerName}",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.5,
                        color: HardwarePalette.silkscreenSubtle,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1A73E8), size: 16),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: "Call Customer (${active.customerPhone})",
                    onPressed: () => active.callCustomer(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.map);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HardwarePalette.silkscreenDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("SECTOR MAP", style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        MapNavigationService.openGoogleMaps(
                          order: active,
                          originLat: trip.currentLat,
                          originLng: trip.currentLng,
                          destLat: active.dropLat,
                          destLng: active.dropLng,
                          address: active.dropAddress,
                          context: context,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HardwarePalette.debossedSlot,
                        foregroundColor: HardwarePalette.silkscreenDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("GOOGLE MAPS", style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Complete mission lever
              MechanicalMissionSlider(
                label: "SWIPE TO COMPLETE DELIVERY",
                completedLabel: "DELIVERY CONCLUDED // CREDITED",
                accentColor: HardwarePalette.signalEmerald,
                icon: Icons.check_circle_rounded,
                onAction: () async {
                  final completedTrip = await trip.completeActiveOrder();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Delivered! +₹${(completedTrip.payout ?? 0.0).toInt()} & +${completedTrip.pointsEarned} PTS Added",
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF065F46),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                  await Future.delayed(const Duration(milliseconds: 400));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: AUDIT LOG (DELIVERY HISTORY)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHistoryTab(TripProvider trip) {
    final hasHistory = trip.history.isNotEmpty;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "CONCLUDED DISPATCH AUDIT",
              style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenSubtle),
            ),
            Text(
              "${trip.history.length} DELIVERIES",
              style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold, color: HardwarePalette.signalEmerald),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (hasHistory)
          ...trip.history.map((t) => _buildDeliveryAuditCard(
            id: t.orderId ?? t.id.split('-').take(2).join('-').toUpperCase(),
            whatIsDelivering: t.orderItems ?? 'Emergency Medical Supplies & Medicine',
            fromWho: t.deliveryFrom ?? 'Main Logistics Depot, Puttur',
            toWhere: t.deliveryTo ?? 'St. Philomena Campus, Sector 3',
            fare: "₹${t.earnedPayout.toInt()}",
            score: t.safetyScore.toInt(),
            distanceKm: t.distanceKm,
            time: "${t.startTime.hour.toString().padLeft(2, '0')}:${t.startTime.minute.toString().padLeft(2, '0')}",
            points: t.pointsEarned ?? (t.safetyScore * 0.9).round(),
          ))
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: HardwarePalette.milledSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HardwarePalette.matrixBorderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  "NO DELIVERIES RECORDED YET",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: HardwarePalette.silkscreenDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Completed dispatch assignments will be audited and logged here with verified distance, payout, and safety score.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: HardwarePalette.silkscreenMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryAuditCard({
    required String id,
    required String whatIsDelivering,
    required String fromWho,
    required String toWhere,
    required String fare,
    required int score,
    required double distanceKm,
    required String time,
    int? points,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HardwarePalette.matrixBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID, Time, Fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: HardwarePalette.debossedSlot,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: HardwarePalette.matrixBorderLight),
                    ),
                    child: Text(
                      id,
                      style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$time • ${distanceKm.toStringAsFixed(1)} KM",
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, color: HardwarePalette.silkscreenSubtle, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                fare,
                style: HardwareTypography.ndotNumber(fontSize: 18, color: HardwarePalette.silkscreenDark),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // WHAT HE IS DELIVERING
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, size: 15, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DELIVERING (WHAT)",
                        style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                      ),
                      Text(
                        whatIsDelivering,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: HardwarePalette.silkscreenDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // FROM WHO & TO WHERE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FROM
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF0284C7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FROM (SENDER)",
                            style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7)),
                          ),
                          Text(
                            fromWho,
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: HardwarePalette.silkscreenDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // TO
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFE11D48)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TO (CUSTOMER)",
                            style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFFE11D48)),
                          ),
                          Text(
                            toWhere,
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: HardwarePalette.silkscreenDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bottom Safety Audit Badge & Points Earned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DISPATCH CONCLUDED",
                style: GoogleFonts.jetBrainsMono(fontSize: 8.5, color: HardwarePalette.silkscreenSubtle, fontWeight: FontWeight.w700),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "+${points ?? (score * 0.9).round()} PTS",
                      style: GoogleFonts.jetBrainsMono(fontSize: 8.5, color: const Color(0xFFFF5722), fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (score >= 85
                              ? HardwarePalette.signalEmerald
                              : (score >= 60 ? const Color(0xFFEAB308) : const Color(0xFFEF4444)))
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "$score% SAFE AUDIT",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        color: score >= 85
                            ? HardwarePalette.signalEmerald
                            : (score >= 60 ? const Color(0xFFCA8A04) : const Color(0xFFDC2626)),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
