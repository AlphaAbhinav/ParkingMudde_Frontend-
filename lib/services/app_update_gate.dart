import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class AppUpdateGate {
  static const String _skippedUpdateTargetKey = 'skipped_update_target';

  static Future<bool> ensureAllowedToContinue(BuildContext context) async {
    final config = await ApiService.checkAppUpdate();
    if (config == null) {
      debugPrint('App update gate: backend config unavailable, allowing launch.');
      return true;
    }

    final installed = await ApiService.getInstalledAppInfo();
    final installedVersion = installed['version']?.toString() ?? '';
    final installedBuild =
        int.tryParse(installed['build']?.toString() ?? '') ?? 0;

    final latestVersion =
        (config['current_app_version'] ?? config['latest_app_version'] ?? '')
            .toString();
    final latestBuild =
        int.tryParse(
          (config['current_app_build'] ?? config['latest_app_build'] ?? 0)
              .toString(),
        ) ??
        0;
    final minVersion = (config['min_supported_app_version'] ?? '').toString();
    final minBuild =
        int.tryParse((config['min_supported_app_build'] ?? 0).toString()) ?? 0;
    final updateUrl = (config['update_url'] ?? '').toString();
    final forceUpdate = config['force_update'] == true;

    debugPrint(
      'App update gate: installed=$installedVersion+$installedBuild, '
      'min=$minVersion+$minBuild, latest=$latestVersion+$latestBuild, '
      'force=$forceUpdate',
    );

    final belowMinimum =
        _isLowerVersion(installedVersion, minVersion) ||
        _isLowerBuild(installedBuild, minBuild);
    final belowLatest =
        _isLowerVersion(installedVersion, latestVersion) ||
        _isLowerBuild(installedBuild, latestBuild);

    if (!belowMinimum && !belowLatest) return true;

    if (belowMinimum || forceUpdate) {
      await _showForceUpdateDialog(
        context,
        updateUrl,
        installedVersion,
        installedBuild,
        minVersion,
        minBuild,
        latestVersion,
        latestBuild,
      );
      return false;
    }

    final target = '$latestVersion+$latestBuild';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_skippedUpdateTargetKey) == target) {
      return true;
    }

    if (!context.mounted) return true;
    final shouldUpdate = await _showOptionalUpdateDialog(
      context,
      updateUrl,
      latestVersion,
      latestBuild,
    );
    if (shouldUpdate == true) {
      await _openUpdateUrl(updateUrl);
    } else {
      await prefs.setString(_skippedUpdateTargetKey, target);
    }
    return true;
  }

  static bool _isLowerBuild(int installedBuild, int targetBuild) {
    return targetBuild > 0 && installedBuild < targetBuild;
  }

  static bool _isLowerVersion(String installed, String target) {
    if (installed.trim().isEmpty || target.trim().isEmpty) return false;
    final installedParts = _versionParts(installed);
    final targetParts = _versionParts(target);
    final length = installedParts.length > targetParts.length
        ? installedParts.length
        : targetParts.length;

    for (var i = 0; i < length; i++) {
      final current = i < installedParts.length ? installedParts[i] : 0;
      final expected = i < targetParts.length ? targetParts[i] : 0;
      if (current < expected) return true;
      if (current > expected) return false;
    }
    return false;
  }

  static List<int> _versionParts(String version) {
    return version
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  static Future<void> _showForceUpdateDialog(
    BuildContext context,
    String updateUrl,
    String installedVersion,
    int installedBuild,
    String minVersion,
    int minBuild,
    String latestVersion,
    int latestBuild,
  ) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Update required'),
          content: Text(
            'Please update the app to continue using ParkingMudde.\n\n'
            'Installed: ${installedVersion.isEmpty ? 'unknown' : installedVersion}+$installedBuild\n'
            'Minimum: $minVersion+$minBuild\n'
            'Latest: $latestVersion+$latestBuild',
          ),
          actions: [
            FilledButton(
              onPressed: () => _openUpdateUrl(updateUrl),
              child: const Text('Update app'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> _showOptionalUpdateDialog(
    BuildContext context,
    String updateUrl,
    String latestVersion,
    int latestBuild,
  ) {
    final versionText = latestVersion.isEmpty
        ? ''
        : ' Version $latestVersion${latestBuild > 0 ? '+$latestBuild' : ''} is available.';
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update available'),
        content: Text(
          'A newer version of ParkingMudde is available.$versionText',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: updateUrl.isEmpty
                ? null
                : () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update now'),
          ),
        ],
      ),
    );
  }

  static Future<void> _openUpdateUrl(String updateUrl) async {
    if (updateUrl.trim().isEmpty) return;
    final uri = Uri.tryParse(updateUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
