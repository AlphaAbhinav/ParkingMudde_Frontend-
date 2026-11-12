import 'package:flutter/material.dart';
import 'package:parkingmudde/services/api_service.dart';

class UserStateField extends StatefulWidget {
  const UserStateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.allowClear = true,
    this.label = 'State or union territory (optional)',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool allowClear;
  final String label;

  @override
  State<UserStateField> createState() => _UserStateFieldState();
}

class _UserStateFieldState extends State<UserStateField> {
  late Future<List<String>> _states = ApiService.getIndianStates();

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.location_on_outlined),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );

    return FutureBuilder<List<String>>(
      future: _states,
      builder: (context, snapshot) {
        final states = snapshot.data ?? const <String>[];
        if (states.isEmpty) {
          final loading = snapshot.connectionState != ConnectionState.done;
          return InputDecorator(
            decoration: decoration,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value ??
                        (loading ? 'Loading states…' : 'Could not load states'),
                  ),
                ),
                if (!loading)
                  TextButton(
                    onPressed: widget.enabled
                        ? () => setState(
                            () => _states = ApiService.getIndianStates(),
                          )
                        : null,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: states.contains(widget.value)
              ? widget.value
              : (widget.allowClear ? '' : null),
          isExpanded: true,
          itemHeight: null,
          decoration: decoration,
          items: [
            if (widget.allowClear)
              const DropdownMenuItem(
                value: '',
                child: Text('No state selected'),
              ),
            for (final state in states)
              DropdownMenuItem(
                value: state,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    state,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
          onChanged: widget.enabled
              ? (value) => widget.onChanged(value == '' ? null : value)
              : null,
        );
      },
    );
  }
}
