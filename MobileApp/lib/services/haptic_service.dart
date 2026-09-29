import 'package:flutter/services.dart';

class HapticService {
  static void lightImpact() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void mediumImpact() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static void heavyImpact() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static void selectionClick() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static void selection() => selectionClick();

  static void success() {
    try {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 80), () {
        HapticFeedback.lightImpact();
      });
    } catch (_) {}
  }

  static void warning() {
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.heavyImpact();
      });
    } catch (_) {}
  }

  static void error() {
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
        });
      });
    } catch (_) {}
  }
}
