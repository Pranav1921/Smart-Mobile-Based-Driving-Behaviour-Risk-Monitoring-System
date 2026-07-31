/// Created on 2026-06-14 — added top-line comment.

import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}