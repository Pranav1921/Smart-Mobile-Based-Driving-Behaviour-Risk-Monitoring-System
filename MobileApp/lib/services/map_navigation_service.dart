import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../models/order_model.dart';
import 'notification_service.dart';

/// Robust service to open external Google Maps with turn-by-turn driving route navigation.
class MapNavigationService {
  /// Opens Google Maps in driving navigation / route mode from origin to destination.
  /// Uses official Google Maps directions APIs with `dir_action=navigate` to force route drawing.
  static Future<bool> openGoogleMaps({
    double? lat,
    double? lng,
    double? destLat,
    double? destLng,
    double? originLat,
    double? originLng,
    String? address,
    DeliveryOrder? order,
    BuildContext? context,
  }) async {
    if (order != null) {
      destLat ??= order.dropLat;
      destLng ??= order.dropLng;
      address ??= order.dropAddress;
      originLat ??= order.pickupLat;
      originLng ??= order.pickupLng;
      // Pin order details into Android notification drawer for access in Google Maps
      NotificationService.showActiveOrderNotification(order);
    }

    final double? targetLat = destLat ?? lat;
    final double? targetLng = destLng ?? lng;

    String? destinationQuery;
    if (targetLat != null && targetLng != null) {
      destinationQuery = '$targetLat,$targetLng';
    } else if (address != null && address.trim().isNotEmpty) {
      destinationQuery = Uri.encodeComponent(address.trim());
    }

    final String originQuery = (originLat != null && originLng != null)
        ? '$originLat,$originLng'
        : 'My+Location';

    if (context != null && context.mounted && order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Navigating to ${order.dropAddress}. Order details pinned to status bar!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1A73E8),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      if (destinationQuery != null) {
        // 1. Native Android Navigation Intent (direct turn-by-turn route)
        final navUri = Uri.parse('google.navigation:q=$destinationQuery&mode=d');
        if (await url_launcher.canLaunchUrl(navUri)) {
          final launched = await url_launcher.launchUrl(
            navUri,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          if (launched) return true;
        }

        // 2. Official Google Maps Universal Directions URL with dir_action=navigate
        // This is guaranteed to draw the active driving route on all platforms
        final dirUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$originQuery&destination=$destinationQuery&travelmode=driving&dir_action=navigate',
        );
        if (await url_launcher.canLaunchUrl(dirUri)) {
          final launched = await url_launcher.launchUrl(
            dirUri,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          if (launched) return true;
        }

        // 3. Fallback: Classic Google Maps Directions Route URL (saddr / daddr)
        final legacyRouteUri = Uri.parse(
          'https://maps.google.com/maps?saddr=$originQuery&daddr=$destinationQuery&directionsmode=driving',
        );
        if (await url_launcher.canLaunchUrl(legacyRouteUri)) {
          final launched = await url_launcher.launchUrl(
            legacyRouteUri,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } else {
        // Fallback if no destination was specified: open directions from current position
        final fallbackDirUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$originQuery&travelmode=driving',
        );
        if (await url_launcher.canLaunchUrl(fallbackDirUri)) {
          final launched = await url_launcher.launchUrl(
            fallbackDirUri,
            mode: url_launcher.LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      }
    } catch (e) {
      debugPrint('[MapNavigationService] Error opening Google Maps route: $e');
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps navigation route. Please verify Google Maps is installed.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  /// Opens Google Maps centered at the specified coordinates for location viewing.
  static Future<bool> openGoogleMapsLocation({
    required double lat,
    required double lng,
    BuildContext? context,
  }) async {
    try {
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
      if (await url_launcher.canLaunchUrl(geoUri)) {
        final launched = await url_launcher.launchUrl(
          geoUri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
        if (launched) return true;
      }

      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await url_launcher.canLaunchUrl(webUri)) {
        final launched = await url_launcher.launchUrl(
          webUri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('[MapNavigationService] Error opening Google Maps location: $e');
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps location.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}
