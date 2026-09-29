import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/core/theme/framer_motion.dart';
import 'package:mobile_app/models/order_model.dart';
import 'package:mobile_app/providers/trip_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/haptic_service.dart';
import 'package:mobile_app/services/map_navigation_service.dart';

class NavigationChoiceModal {
  static void show(BuildContext context, DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NavigationChoiceSheet(order: order),
    );
  }
}

class _NavigationChoiceSheet extends StatelessWidget {
  final DeliveryOrder order;

  const _NavigationChoiceSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: NeonColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: NeonColors.primaryGreen.withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeonColors.subtext.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NeonColors.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.4)),
                ),
                child: const Icon(Icons.navigation_rounded, color: NeonColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CHOOSE NAVIGATION MODE",
                      style: AppTypography.mono(
                        size: 13,
                        color: NeonColors.text,
                        weight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Order #${order.id} · ₹${order.payoutAmount.toInt()} Payout",
                      style: AppTypography.caption(
                        color: NeonColors.primaryGreen,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: NeonColors.subtext, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Order Destination Preview Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NeonColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeonColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFFF43F5E), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.dropAddress,
                        style: AppTypography.bodySmall(
                          color: NeonColors.text,
                          weight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NeonColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Distance: ${order.distanceKm} km",
                        style: AppTypography.mono(size: 10, color: NeonColors.subtext),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NeonColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Est. Time: ${order.estimatedTimeMinutes} mins",
                        style: AppTypography.mono(size: 10, color: NeonColors.subtext),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Choice 1: In-App Tactical Navigation
          FramerPressable(
            onTap: () {
              HapticService.mediumImpact();
              Navigator.pop(context);

              trip.acceptOrderWithChoice(
                order,
                inAppNavigation: true,
                driverName: auth.profile.name,
                driverId: auth.profile.driverId,
                regionId: auth.profile.regionId,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE05252), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE05252).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "IN-APP TACTICAL MAP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Integrated route, speed HUD & instant hazard alerts",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Choice 2: Google Maps Navigation
          FramerPressable(
            onTap: () async {
              HapticService.mediumImpact();
              Navigator.pop(context);

              trip.acceptOrderWithChoice(
                order,
                inAppNavigation: false,
                driverName: auth.profile.name,
                driverId: auth.profile.driverId,
                regionId: auth.profile.regionId,
              );

              // Launch Google Maps route navigation
              await MapNavigationService.openGoogleMaps(
                originLat: trip.currentLat,
                originLng: trip.currentLng,
                destLat: order.dropLat,
                destLng: order.dropLng,
                address: order.dropAddress,
                context: context,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: NeonColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NeonColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assistant_direction_rounded, color: Color(0xFF4285F4), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "GOOGLE MAPS NAVIGATION",
                          style: AppTypography.mono(
                            size: 13,
                            color: NeonColors.text,
                            weight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "External turn-by-turn with live background telemetry",
                          style: AppTypography.caption(
                            color: NeonColors.subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, color: NeonColors.subtext, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
