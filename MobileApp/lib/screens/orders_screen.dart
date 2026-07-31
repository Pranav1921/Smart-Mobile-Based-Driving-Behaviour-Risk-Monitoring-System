import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/order_model.dart';
import '../providers/trip_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/glass_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  final Map<String, int> _orderCountdowns = {};

  @override
  void initState() {
    super.initState();
    
    // Fetch orders immediately
    final tripProv = Provider.of<TripProvider>(context, listen: false);
    if (tripProv.isShiftActive) {
      tripProv.fetchBackendOrders();
    }

    // Start periodic polling every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final provider = Provider.of<TripProvider>(context, listen: false);
      if (provider.isShiftActive && provider.activeOrder == null) {
        provider.fetchBackendOrders();
      }
    });

    // Start countdown timer updates
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      final provider = Provider.of<TripProvider>(context, listen: false);
      if (provider.isShiftActive && provider.availableOrders.isNotEmpty) {
        final orders = List.of(provider.availableOrders);
        final toReject = <DeliveryOrder>[];

        for (var order in orders) {
          final currentVal = _orderCountdowns[order.id] ?? 30; // give more time for manual testing
          if (currentVal > 0) {
            _orderCountdowns[order.id] = currentVal - 1;
          } else {
            toReject.add(order);
          }
        }

        for (final order in toReject) {
          provider.rejectOrder(order);
          _orderCountdowns.remove(order.id);
        }

        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);

    if (!tripProv.isShiftActive) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("DISPATCH HUB"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: GlassCard(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sensors_off_outlined,
                    size: 54,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "DISPATCH SYSTEM STANDBY",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You are currently offline. Toggle 'START SHIFT' on the main dashboard to register on the logistics grid and receive orders.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final orders = tripProv.availableOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("DISPATCH QUEUE"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_outlined, color: AppColors.primary),
            onPressed: () {
              tripProv.receiveNewSimulatedOrder();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Simulating Incoming Dispatch Dispatcher Broadcast..."),
                  backgroundColor: AppColors.surface,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            tooltip: "Mock Receive Order",
          ),
        ],
      ),
      body: SafeArea(
        child: orders.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      const SizedBox(height: 24),
                      const Text(
                        "SEARCHING FOR DISPATCH MATCHES...",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Active on company server: ${tripProv.history.length + 1} drivers",
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final secondsLeft = _orderCountdowns[order.id] ?? 20;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildOrderCard(context, order, secondsLeft, tripProv),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, DeliveryOrder order, int secondsLeft, TripProvider provider) {
    double progress = secondsLeft / 20.0;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Countdown progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  order.id,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    "${secondsLeft}S",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Shrinking timer line
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              secondsLeft > 8 ? AppColors.primary : AppColors.error,
            ),
          ),
          const SizedBox(height: 18),

          // Pickup Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.radio_button_checked, color: AppColors.primary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PICKUP ORIGIN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(order.pickupAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Drop Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppColors.error, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DELIVERY DESTINATION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(order.dropAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          // Financial and Travel specs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSpecItem("DISTANCE", "${order.distanceKm} KM"),
              _buildSpecItem("DURATION", "${order.estimatedTimeMinutes} MIN"),
              _buildSpecItem("ESTIMATED PAY", "\$${order.payoutAmount.toStringAsFixed(2)}", isHighlight: true),
            ],
          ),
          const SizedBox(height: 20),

          // Accept / Reject Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.rejectOrder(order);
                  },
                  child: const Text("PASS"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    provider.acceptOrder(order);
                    // Open immersive map navigation fullscreen!
                    Navigator.pushNamed(context, AppRoutes.trip);
                  },
                  child: const Text("ACCEPT"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
