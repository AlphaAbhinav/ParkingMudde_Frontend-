import 'package:shared_preferences/shared_preferences.dart';

class AlertState {
  AlertState._();

  static const String actionedAlertIdsKey = 'actioned_alert_ids';
  static final Set<int> _activeAlertIds = <int>{};

  static int parseAlertId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool isActive(int alertId) {
    return alertId != 0 && _activeAlertIds.contains(alertId);
  }

  static Future<Set<int>> actionedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(actionedAlertIdsKey) ?? <String>[];
    return list
        .map((value) => int.tryParse(value) ?? 0)
        .where((id) => id != 0)
        .toSet();
  }

  static Future<bool> begin(dynamic rawAlertId) async {
    final alertId = parseAlertId(rawAlertId);
    if (alertId == 0) return true;
    if (_activeAlertIds.contains(alertId)) return false;
    if ((await actionedIds()).contains(alertId)) return false;
    _activeAlertIds.add(alertId);
    return true;
  }

  static Future<void> end(dynamic rawAlertId, {required bool actioned}) async {
    final alertId = parseAlertId(rawAlertId);
    if (alertId == 0) return;
    _activeAlertIds.remove(alertId);
    if (!actioned) return;

    final prefs = await SharedPreferences.getInstance();
    final ids = await actionedIds();
    ids.add(alertId);
    await prefs.setStringList(
      actionedAlertIdsKey,
      ids.map((id) => id.toString()).toList(),
    );
  }
}
