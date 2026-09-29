import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/trip_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../core/theme/neon_theme.dart';
import '../services/road_rules_service.dart';
import '../services/haptic_service.dart';
import '../widgets/tactical_sidebar.dart';
import 'package:mobile_app/core/theme/framer_motion.dart';

class RulesRewardsScreen extends StatefulWidget {
  final bool isEmbedded;
  const RulesRewardsScreen({super.key, this.isEmbedded = false});

  @override
  State<RulesRewardsScreen> createState() => _RulesRewardsScreenState();
}

class _RulesRewardsScreenState extends State<RulesRewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconKey) {
    switch (iconKey) {
      case 'speed':
        return Icons.speed_rounded;
      case 'pan_tool_rounded':
        return Icons.pan_tool_rounded;
      case 'turn_right_rounded':
        return Icons.turn_right_rounded;
      case 'school_rounded':
        return Icons.school_rounded;
      case 'local_shipping_rounded':
        return Icons.local_shipping_rounded;
      case 'verified_rounded':
        return Icons.verified_rounded;
      case 'local_gas_station_rounded':
        return Icons.local_gas_station_rounded;
      case 'sports_motorsports_rounded':
        return Icons.sports_motorsports_rounded;
      case 'car_repair_rounded':
      case 'build_circle_rounded':
        return Icons.build_circle_rounded;
      case 'shopping_bag_rounded':
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final p = auth.profile;
    final rules = trip.currentCityRules;

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
          'Rules & Rewards',
          style: TextStyle(
            color: NeonColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NeonColors.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: NeonColors.primaryGreen, size: 15),
                const SizedBox(width: 4),
                Text(
                  '${trip.totalClaimedPoints} pts',
                  style: const TextStyle(
                    color: NeonColors.primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeonColors.primaryGreen,
          indicatorWeight: 3,
          labelColor: NeonColors.primaryGreen,
          unselectedLabelColor: NeonColors.subtext,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Offers & Rewards'),
            Tab(text: 'Ride Points & Rules'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildGoodiesTab(context, trip),
              _buildRulesAndScorecardTab(context, trip, p, rules),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF10B981),
                Color(0xFF00FF9D),
                Colors.amber,
                Colors.blueAccent,
                Colors.purpleAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesAndScorecardTab(
    BuildContext context,
    TripProvider trip,
    dynamic p,
    CityTrafficRegulations rules,
  ) {
    final currentLat = trip.currentLat ?? 0.0;
    final currentLng = trip.currentLng ?? 0.0;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18, 16, 18, widget.isEmbedded ? 150 : 40),
      children: [
        // 0. Points Balance & Safe Driver Status Minimal Banner
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: NeonColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NeonColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeonColors.primaryGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: NeonColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reward Points Balance",
                        style: TextStyle(color: NeonColors.subtext, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            "${trip.totalClaimedPoints}",
                            style: TextStyle(color: NeonColors.text, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "PTS",
                            style: TextStyle(color: NeonColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(≈ ₹${(trip.totalClaimedPoints / 10).toStringAsFixed(0)} UPI Cash)",
                            style: TextStyle(color: NeonColors.subtext, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NeonColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeonColors.border),
                ),
                child: Text(
                  trip.history.isEmpty ? "0 RIDES COMPLETED" : "${trip.history.length} RIDES",
                  style: TextStyle(color: NeonColors.subtext, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ).framerSlideIn(delayMs: 40),

        // 1. Driver Safety Score Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: NeonColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NeonColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: NeonColors.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "Safety Score",
                        style: TextStyle(color: NeonColors.text, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: NeonColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${trip.tripSafetyScore.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: NeonColors.primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _scorecardMetric("Speed", "${trip.speedConsistencyPct.toStringAsFixed(0)}%", NeonColors.primaryGreen),
                  const SizedBox(width: 8),
                  _scorecardMetric("Braking", "${trip.brakingSmoothnessPct.toStringAsFixed(0)}%", const Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  _scorecardMetric("Turns", "${trip.corneringSafetyPct.toStringAsFixed(0)}%", Colors.amber),
                  const SizedBox(width: 8),
                  _scorecardMetric("Zones", "${trip.zoneAdherencePct.toStringAsFixed(0)}%", const Color(0xFFA78BFA)),
                ],
              ),
            ],
          ),
        ).framerSlideIn(delayMs: 60),

        const SizedBox(height: 18),

        // 2. Speed Limits
        Text(
          "Speed Limits (${rules.cityName})",
          style: TextStyle(color: NeonColors.text, fontSize: 14, fontWeight: FontWeight.w800),
        ).framerSlideIn(delayMs: 100),
        const SizedBox(height: 10),
        Row(
          children: [
            _speedCard("School", "${rules.schoolZoneSpeedLimit.toInt()}", "km/h", Colors.amber),
            const SizedBox(width: 8),
            _speedCard("Hospital", "${rules.hospitalZoneSpeedLimit.toInt()}", "km/h", Colors.cyan),
            const SizedBox(width: 8),
            _speedCard("City", "${rules.mainRoadSpeedLimit.toInt()}", "km/h", NeonColors.primaryGreen),
            const SizedBox(width: 8),
            _speedCard("Highway", "${rules.highwaySpeedLimit.toInt()}", "km/h", const Color(0xFF38BDF8)),
          ],
        ).framerSlideIn(delayMs: 140),

        const SizedBox(height: 20),

        // 3. Daily Challenges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Challenges',
              style: TextStyle(color: NeonColors.text, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: NeonColors.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${trip.dailyRules.where((r) => r.isClaimed).length}/${trip.dailyRules.length} Claimed',
                style: const TextStyle(color: NeonColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 🌟 Prominent Daily Streak Bonus Card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NeonColors.card,
                NeonColors.primaryGreen.withOpacity(0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NeonColors.primaryGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: NeonColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DAILY STREAK BONUS",
                      style: TextStyle(color: NeonColors.text, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.canClaimDailyStreak
                          ? "1+ ride completed today: +100 PTS ready!"
                          : (trip.isDailyStreakClaimed
                              ? "Daily streak reward awarded for today"
                              : "Complete 1 ride today to unlock +100 PTS"),
                      style: TextStyle(color: NeonColors.subtext, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (trip.isDailyStreakClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeonColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: NeonColors.primaryGreen, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'CLAIMED',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                )
              else if (trip.canClaimDailyStreak)
                ElevatedButton(
                  onPressed: () {
                    trip.claimDailyStreakBonus();
                    _confettiController.play();
                    HapticService.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🎉 +100 Daily Streak Points Claimed!"),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonColors.primaryGreen,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text(
                    "CLAIM",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeonColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NeonColors.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: NeonColors.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          color: NeonColors.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Rules List with interactive Claiming
        ...trip.dailyRules.map((rule) {
          final isClaimed = rule.isClaimed;
          final isAchieved = rule.isAchieved;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: NeonColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAchieved && !isClaimed ? NeonColors.primaryGreen : NeonColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconData(rule.icon),
                  color: isAchieved ? NeonColors.primaryGreen : NeonColors.subtext,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          rule.title,
                          style: TextStyle(
                            color: NeonColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NeonColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${rule.points} pts',
                          style: const TextStyle(
                            color: NeonColors.primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Claim Button or Locked Badge
                if (isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NeonColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_rounded, color: NeonColors.primaryGreen, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'CLAIMED',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isAchieved)
                  ElevatedButton(
                    onPressed: () {
                      trip.claimRulePoints(rule.id);
                      _confettiController.play();
                      HapticService.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("🎉 Claimed +${rule.points} Points for ${rule.title}!"),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeonColors.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CLAIM',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: NeonColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: NeonColors.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: NeonColors.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOCKED',
                          style: TextStyle(
                            color: NeonColors.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 18),

        // 4. Safety Zones
        if (rules.schools.isNotEmpty || rules.hospitals.isNotEmpty) ...[
          Text(
            'Safety Zones',
            style: TextStyle(color: NeonColors.text, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...rules.schools.take(2).map((s) {
            final distKm = RoadRulesService.calculateDistance(currentLat, currentLng, s.lat, s.lng);
            final distText = distKm < 1.0 ? "${(distKm * 1000).toInt()} m" : "${distKm.toStringAsFixed(1)} km";
            return _zoneTile(
              icon: Icons.school_rounded,
              iconColor: Colors.amber,
              title: s.name,
              badge: distText,
              badgeColor: Colors.amber,
            );
          }),
          ...rules.hospitals.take(2).map((h) {
            final distKm = RoadRulesService.calculateDistance(currentLat, currentLng, h.lat, h.lng);
            final distText = distKm < 1.0 ? "${(distKm * 1000).toInt()} m" : "${distKm.toStringAsFixed(1)} km";
            return _zoneTile(
              icon: Icons.local_hospital_rounded,
              iconColor: Colors.cyan,
              title: h.name,
              badge: distText,
              badgeColor: Colors.cyan,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildGoodiesTab(BuildContext context, TripProvider trip) {
    final filteredStore = _selectedCategory == 'All'
        ? trip.goodiesStore
        : trip.goodiesStore.where((g) => g.category == _selectedCategory).toList();

    final int pts = trip.totalClaimedPoints;
    final int possibleCash = (pts / 10).toInt();
    final bool canRedeemUpi = pts >= 100;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18, 16, 18, widget.isEmbedded ? 150 : 40),
      children: [
        // 1. Sleek, Cohesive Points & UPI Cashout Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: NeonColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NeonColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE REWARD POINTS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: NeonColors.subtext,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$pts',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: NeonColors.text,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PTS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: NeonColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(≈ ₹$possibleCash UPI)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NeonColors.subtext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showMyVouchersSheet(context, trip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: NeonColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: NeonColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: NeonColors.primaryGreen, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'Vouchers (${trip.claimedVouchers.length})',
                            style: GoogleFonts.spaceGrotesk(
                              color: NeonColors.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Instant UPI Cash Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: NeonColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canRedeemUpi ? NeonColors.primaryGreen.withOpacity(0.3) : NeonColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: canRedeemUpi ? NeonColors.primaryGreen.withOpacity(0.15) : NeonColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.currency_rupee_rounded,
                        color: canRedeemUpi ? NeonColors.primaryGreen : NeonColors.subtext,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Instant UPI Cashout",
                            style: GoogleFonts.outfit(
                              color: NeonColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            canRedeemUpi ? "10 PTS = ₹1 · Ready to transfer" : "Unlocks at 100 PTS (Earn via safe rides)",
                            style: GoogleFonts.plusJakartaSans(
                              color: NeonColors.subtext,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (canRedeemUpi)
                      ElevatedButton(
                        onPressed: () => _showUpiRedeemSheet(context, trip),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeonColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          "REDEEM",
                          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NeonColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: NeonColors.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 11,
                              color: NeonColors.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "LOCKED",
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: NeonColors.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ).framerSlideIn(delayMs: 60),

        const SizedBox(height: 18),

        // 2. Clean Catalog Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reward Catalog',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: NeonColors.text),
            ),
            Text(
              '${filteredStore.length} items',
              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: NeonColors.subtext),
            ),
          ],
        ).framerSlideIn(delayMs: 90),
        const SizedBox(height: 10),

        // 3. Clean Categories (Streamlined from 7 to 4)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['All', 'Fuel', 'Vouchers', 'Safety Gear'].map((cat) {
              final isSel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? NeonColors.primaryGreen : NeonColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSel ? NeonColors.primaryGreen : NeonColors.border),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.spaceGrotesk(
                      color: isSel ? Colors.white : NeonColors.subtext,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).framerSlideIn(delayMs: 110),

        const SizedBox(height: 14),

        // 4. Rewards List (Streamlined & Theme Matched)
        ...filteredStore.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final double progress = (trip.totalClaimedPoints / item.pointsCost).clamp(0.0, 1.0);
          final bool isReady = trip.totalClaimedPoints >= item.pointsCost;

          return FramerPressable(
            onTap: () {
              if (isReady) {
                _showClaimConfirmDialog(context, trip, item);
              } else {
                HapticService.lightImpact();
                final needed = item.pointsCost - trip.totalClaimedPoints;
                final tripsNeeded = (needed / 50).ceil();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Need $needed more points! Complete $tripsNeeded more safe rides with 0 rule violations.',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: NeonColors.card,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            scaleFactor: 0.98,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: NeonColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isReady ? NeonColors.primaryGreen.withOpacity(0.5) : NeonColors.border,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isReady
                                ? NeonColors.primaryGreen.withOpacity(0.12)
                                : NeonColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconData(item.icon),
                            color: isReady ? NeonColors.primaryGreen : NeonColors.subtext,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: NeonColors.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: NeonColors.subtext),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.pointsCost} PTS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isReady ? NeonColors.primaryGreen : NeonColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isReady)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: NeonColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CLAIM',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: NeonColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Need ${item.pointsCost - trip.totalClaimedPoints} pts',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w700, color: NeonColors.subtext),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: NeonColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isReady ? NeonColors.primaryGreen : NeonColors.primaryGreen.withOpacity(0.4),
                      ),
                      minHeight: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ).framerSlideIn(delayMs: 120 + (index * 20));
        }),
      ],
    );
  }
  void _showClaimConfirmDialog(BuildContext context, TripProvider trip, GoodieItem item) {
    HapticService.selectionClick();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: NeonColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: NeonColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NeonColors.primaryGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconData(item.icon), color: NeonColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Claim Reward',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: NeonColors.text),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: NeonColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: NeonColors.subtext),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeonColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeonColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Points Cost:', style: GoogleFonts.spaceGrotesk(color: NeonColors.subtext, fontSize: 12)),
                      Text('${item.pointsCost} PTS', style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balance After Claim:', style: GoogleFonts.spaceGrotesk(color: NeonColors.subtext, fontSize: 12)),
                      Text('${trip.totalClaimedPoints - item.pointsCost} PTS', style: GoogleFonts.spaceGrotesk(color: NeonColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.shield_rounded, size: 14, color: NeonColors.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Obtained legitimately through safe driving with zero rule violations.',
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, color: NeonColors.subtext),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: NeonColors.subtext, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NeonColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final voucher = await trip.claimGoodie(item);
              if (voucher != null && context.mounted) {
                _confettiController.play();
                _showVoucherCodeModal(context, voucher);
              }
            },
            child: Text('Confirm & Claim', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showVoucherCodeModal(BuildContext context, ClaimedVoucher voucher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeonColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: NeonColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeonColors.primaryGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_rounded, color: NeonColors.primaryGreen, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              "Reward Successfully Claimed!",
              style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              voucher.title,
              style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 14, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Voucher Tactical Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: NeonColors.surfaceMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NeonColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    "DIGITAL REDEMPTION VOUCHER CODE",
                    style: GoogleFonts.spaceGrotesk(color: NeonColors.subtext, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: NeonColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NeonColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          voucher.voucherCode,
                          style: GoogleFonts.spaceGrotesk(
                            color: NeonColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: NeonColors.primaryGreen, size: 20),
                          tooltip: 'Copy Code',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: voucher.voucherCode));
                            HapticService.selectionClick();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text("Voucher code copied to clipboard!"),
                                backgroundColor: Color(0xFF10B981),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Barcode simulation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      24,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: (i % 3 == 0) ? 3.0 : ((i % 2 == 0) ? 1.5 : 2.0),
                        height: 28,
                        color: NeonColors.subtext.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Show this code or barcode at any authorized partner fuel station or depot counter to redeem.",
                    style: GoogleFonts.plusJakartaSans(color: NeonColors.subtext, fontSize: 10.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text("DONE & SAVE TO VOUCHERS", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyVouchersSheet(BuildContext context, TripProvider trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeonColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: NeonColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: NeonColors.primaryGreen, size: 22),
                    const SizedBox(width: 8),
                    Text("My Claimed Vouchers", style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NeonColors.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${trip.claimedVouchers.length} Total",
                    style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (trip.claimedVouchers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: NeonColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NeonColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: NeonColors.subtext, size: 40),
                    const SizedBox(height: 10),
                    Text("No vouchers claimed yet", style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      "Earn safe ride points and claim fuel cards, safety gear, or service discounts above!",
                      style: GoogleFonts.plusJakartaSans(color: NeonColors.subtext, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: trip.claimedVouchers.length,
                  itemBuilder: (ctx, i) {
                    final v = trip.claimedVouchers[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NeonColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NeonColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: NeonColors.primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getIconData(v.icon), color: NeonColors.primaryGreen, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.title, style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      v.voucherCode,
                                      style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "· ${v.valueText}",
                                      style: GoogleFonts.spaceGrotesk(color: NeonColors.subtext, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_rounded, color: NeonColors.subtext, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: v.voucherCode));
                              HapticService.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Copied ${v.voucherCode}"),
                                  backgroundColor: NeonColors.primaryGreen,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scorecardMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: NeonColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: AppTypography.display(size: 14, color: color, weight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.body(size: 9, color: NeonColors.subtext, weight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _speedCard(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: AppTypography.body(size: 9, color: color, weight: FontWeight.w700)),
            const SizedBox(height: 1),
            Text(value, style: AppTypography.display(size: 14, color: color, weight: FontWeight.w900)),
            Text(unit, style: AppTypography.mono(size: 8, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _zoneTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTypography.title(size: 12, weight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: AppTypography.mono(size: 9, color: badgeColor, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpiRedeemSheet(BuildContext context, TripProvider trip) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String driverUpi = "${auth.profile.name.toLowerCase().replaceAll(' ', '.')}@oksbi";
    int selectedPoints = trip.totalClaimedPoints >= 100 ? 100 : trip.totalClaimedPoints;
    final TextEditingController upiCtrl = TextEditingController(text: driverUpi);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeonColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: NeonColors.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: NeonColors.primaryGreen.withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.currency_rupee_rounded, color: NeonColors.primaryGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text("Redeem to UPI ID", style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
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
                "Select points amount to convert to instant cash deposited into your UPI account.",
                style: GoogleFonts.plusJakartaSans(color: NeonColors.subtext, fontSize: 11.5),
              ),
              const SizedBox(height: 16),

              // Preset amounts
              Row(
                children: [50, 100, 250, 500].map((pts) {
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
                              ? NeonColors.primaryGreen.withOpacity(0.12)
                              : NeonColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? NeonColors.primaryGreen : NeonColors.border,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$pts pts",
                              style: GoogleFonts.spaceGrotesk(
                                color: isAvailable ? NeonColors.text : NeonColors.subtext.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "₹${(pts / 10).toInt()}",
                              style: GoogleFonts.outfit(
                                color: isAvailable ? NeonColors.primaryGreen : NeonColors.subtext.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              Text("Beneficiary UPI ID", style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: NeonColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeonColors.border),
                ),
                child: TextField(
                  controller: upiCtrl,
                  style: GoogleFonts.spaceGrotesk(color: NeonColors.text, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.account_balance_wallet_rounded, color: NeonColors.primaryGreen, size: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
                            _confettiController.play();
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
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: NeonColors.surfaceMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "TRANSFER ₹${(selectedPoints / 10).toInt()} VIA UPI",
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
