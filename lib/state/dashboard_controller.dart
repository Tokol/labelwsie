// lib/state/dashboard_controller.dart
import 'package:flutter/foundation.dart';

class DashboardController extends ChangeNotifier {
  int index = 0;

  void setIndex(int newIndex) {
    if (index == newIndex) return;
    index = newIndex;
    notifyListeners();
  }
}
