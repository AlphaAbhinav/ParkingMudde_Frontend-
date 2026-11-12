import 'package:flutter/material.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/widgets/user_state_field.dart';

Future<String?> showUserStatePicker(BuildContext context, {String? state}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _UserStatePicker(currentState: state),
  );
}

class _UserStatePicker extends StatefulWidget {
  const _UserStatePicker({this.currentState});

  final String? currentState;

  @override
  State<_UserStatePicker> createState() => _UserStatePickerState();
}

class _UserStatePickerState extends State<_UserStatePicker> {
  late String? _selected = widget.currentState;
  String? _error;
  bool _saving = false;

  Future<void> _save() async {
    final state = _selected;
    if (state == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ApiService.saveUserState(state);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, state);
      return;
    }
    setState(() {
      _saving = false;
      _error = result['message']?.toString() ?? 'Could not save your state.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        scrollable: true,
        title: const Text('Select your state'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'See shared coupons available in your state or union territory.',
            ),
            const SizedBox(height: 16),
            UserStateField(
              value: _selected,
              enabled: !_saving,
              allowClear: false,
              label: 'State or union territory',
              onChanged: (value) => setState(() => _selected = value),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving || _selected == null ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save state'),
          ),
        ],
      ),
    );
  }
}
