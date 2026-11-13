import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

Future<void> showAadhaarVerification(BuildContext context, int userId) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AadhaarVerificationDialog(userId: userId),
  );
}

class _AadhaarVerificationDialog extends StatefulWidget {
  const _AadhaarVerificationDialog({required this.userId});

  final int userId;

  @override
  State<_AadhaarVerificationDialog> createState() =>
      _AadhaarVerificationDialogState();
}

class _AadhaarVerificationDialogState
    extends State<_AadhaarVerificationDialog> {
  String? _status;
  Uri? _verificationUrl;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _update(ApiService.getAadhaarVerificationState);
  }

  Future<void> _update(
    Future<Map<String, dynamic>> Function(int) request,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final response = await request(widget.userId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (response['success'] == true) {
        _status = response['verification_status']?.toString();
        final url = Uri.tryParse(
          response['verification_url']?.toString() ?? '',
        );
        _verificationUrl = url?.scheme == 'https' ? url : null;
      } else {
        _error = response['message']?.toString() ?? 'Verification unavailable.';
      }
    });
  }

  Future<void> _openVerification(Uri url) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    bool opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Keep the saved link available when the device cannot open it.
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!opened) _error = 'Could not open the Surepass verification link.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _verificationUrl;
    final canStart = const {
      'not_started',
      'expired',
      'failed',
    }.contains(_status);
    final canCheck = const {
      'pending',
      'callback_received',
      'result_pending',
    }.contains(_status);
    final message = switch (_status) {
      'not_started' =>
        'Use the Aadhaar app or a QR code to share your Aadhaar credentials '
        'with Surepass.',
      'pending' =>
        'Open Surepass and follow the Aadhaar app or QR code instructions. '
        'Then return here and tap Check verification.',
      'callback_received' ||
      'result_pending' => 'Surepass is processing your verification.',
      'verified' => 'Your Aadhaar verification is complete.',
      'expired' => 'Your Aadhaar session expired. Start again to get a new link.',
      'failed' =>
        'Surepass could not verify your Aadhaar. You can start again.',
      'checking' =>
        'A verification request is in progress. Refresh to see the saved status.',
      _ => null,
    };
    return AlertDialog(
      scrollable: true,
      title: const Text('Aadhaar verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) Text(message),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_status == 'verified' ? 'Done' : 'Close'),
        ),
        if (url != null)
          OutlinedButton(
            onPressed: _busy ? null : () => _openVerification(url),
            child: const Text('Open Surepass'),
          ),
        if (canStart)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _update(ApiService.startAadhaarVerification),
            child: const Text('Start verification'),
          ),
        if (canCheck)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _update(ApiService.checkAadhaarVerification),
            child: const Text('Check verification'),
          ),
        if (_status == 'checking' || (_status == null && _error != null))
          FilledButton(
            onPressed: _busy
                ? null
                : () => _update(ApiService.getAadhaarVerificationState),
            child: const Text('Refresh'),
          ),
      ],
    );
  }
}
