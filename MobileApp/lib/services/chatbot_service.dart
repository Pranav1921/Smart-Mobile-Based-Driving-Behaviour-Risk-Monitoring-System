import 'dart:math';

class ChatbotService {
  static const List<String> _safetyTips = [
    "Always maintain a 3-second following distance.",
    "Brake gradually to maintain a high safety score.",
    "Your current vehicle is optimized for urban delivery.",
    "Heavy traffic detected on Main Avenue. Consider taking the bypass.",
    "Remember to stay hydrated during your shift."
  ];

  static Future<String> processQuery(String query, {double? safetyScore}) async {
    // Simulate thinking delay
    await Future.delayed(const Duration(seconds: 1));

    String q = query.toLowerCase();

    if (q.contains("safety") || q.contains("score")) {
      return "Your current safety score is ${safetyScore?.toStringAsFixed(1) ?? '98.5'}. You're doing great! Keep it up to earn more bonuses.";
    }

    if (q.contains("next") || q.contains("order") || q.contains("mission") || q.contains("assignment")) {
      return "Current Mission: Deliver Safety Equipment to Puttur School Zone. Distance remaining: 2.5km. Please be careful of the school zone at the destination.";
    }

    if (q.contains("school") || q.contains("zone")) {
      return "There is a school zone detected near your destination at Puttur Public School. Speed limit is reduced to 20 km/h. System will alert you 500m before you enter.";
    }

    if (q.contains("hello") || q.contains("hi")) {
      return "Greetings, Operator. I am your Tactical Assistant. How can I assist with your mission today?";
    }

    if (q.contains("help")) {
      return "I can provide mission details, safety score analysis, and route optimization tips. Just ask!";
    }

    // Default response: random safety tip
    return "Understood. Did you know? ${_safetyTips[Random().nextInt(_safetyTips.length)]}";
  }
}
