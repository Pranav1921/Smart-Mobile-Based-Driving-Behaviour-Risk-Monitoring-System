import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/neon_theme.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  StreamSubscription<SafetyNotificationItem>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = NotificationService.alertStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return "JUST NOW";
    if (diff.inMinutes < 60) return "${diff.inMinutes} MIN AGO";
    if (diff.inHours < 24) return "${diff.inHours} HR AGO";
    return DateFormat('dd MMM').format(dt).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = NotificationService.alertHistory;

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        title: const Text("SIGNAL STREAM", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: NeonColors.text),
      ),
      body: SafeArea(
        child: alerts.isEmpty ? _buildEmptyHUD() : _buildNotificationList(alerts),
      ),
    );
  }

  Widget _buildEmptyHUD() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 64, color: NeonColors.subtext.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text("STREAM CLEAR", style: TextStyle(color: NeonColors.subtext, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3)),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<SafetyNotificationItem> alerts) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(28),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final n = alerts[index];
        final type = n.type;
        Color color = NeonColors.neonBlue;
        if (type == "warning") color = NeonColors.neonYellow;
        if (type == "alert") color = NeonColors.neonRed;
        if (type == "success") color = NeonColors.neonGreen;
        if (type == "info") color = NeonColors.primaryGreen;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: NeonTheme.tacticalCard(radius: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40, width: 4,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: NeonColors.text, letterSpacing: 0.5),
                          ),
                        ),
                        Text(
                          _formatTime(n.timestamp),
                          style: TextStyle(fontSize: 8, color: NeonColors.subtext, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.body,
                      style: TextStyle(fontSize: 12, color: NeonColors.subtext, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
