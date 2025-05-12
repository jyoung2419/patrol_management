import 'package:flutter/material.dart';

class GlobalProvider {
  static ValueNotifier<bool> patrolInProgress = ValueNotifier(false);
  static ValueNotifier<int?> patrolId = ValueNotifier(null);
}

ValueNotifier<int?> selectedLocationId = ValueNotifier(null);
