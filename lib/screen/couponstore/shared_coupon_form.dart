import 'package:flutter/material.dart';
import 'package:parkingmudde/services/api_service.dart';

Future<bool?> showShareCouponForm(
  BuildContext context, {
  required String userId,
  required String? state,
  required String? societyName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _ShareCouponForm(
      userId: userId,
      state: state,
      societyName: societyName,
    ),
  );
}

class _ShareCouponForm extends StatefulWidget {
  const _ShareCouponForm({required this.userId, this.state, this.societyName});

  final String userId;
  final String? state;
  final String? societyName;

  @override
  State<_ShareCouponForm> createState() => _ShareCouponFormState();
}

class _ShareCouponFormState extends State<_ShareCouponForm> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _title = TextEditingController();
  final _code = TextEditingController();
  final _description = TextEditingController();
  late Set<String> _states = {if (widget.state case final state?) state};
  bool _allStates = false;
  bool _societyPriority = false;
  bool _saving = false;
  String? _error;

  String get _stateSelectionLabel => switch (_states.length) {
    0 => 'Select states and UTs',
    1 => _states.single,
    final count => '$count states and UTs selected',
  };

  @override
  void dispose() {
    _brand.dispose();
    _title.dispose();
    _code.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseStates() async {
    FocusScope.of(context).unfocus();
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _CouponStatePicker(selected: _states),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _states = selected;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (!_allStates && _states.isEmpty) {
      setState(
        () =>
            _error = 'Choose at least one state or select All states and UTs.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ApiService.shareCoupon(
      userId: widget.userId,
      brand: _brand.text.trim(),
      title: _title.text.trim(),
      code: _code.text.trim(),
      description: _description.text.trim(),
      states: _allStates ? [] : (_states.toList()..sort()),
      societyPriority: _societyPriority,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = result['message']?.toString() ?? 'Could not share this coupon.';
    });
  }

  Widget _field(
    TextEditingController controller,
    String label,
    int maxLength, {
    bool optional = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLength: maxLength,
      maxLines: optional ? 2 : 1,
      textInputAction: optional
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      validator: optional
          ? null
          : (value) => value!.trim().isEmpty ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final society = widget.societyName;
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Coupon',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _field(_brand, 'Business or brand', 120),
                  const SizedBox(height: 12),
                  _field(_title, 'Offer title', 160),
                  const SizedBox(height: 12),
                  _field(_code, 'Coupon code', 120),
                  const SizedBox(height: 12),
                  _field(
                    _description,
                    'Terms or details (optional)',
                    600,
                    optional: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Where is the coupon available?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('All states and UTs'),
                    value: _allStates,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                            _allStates = value;
                            _error = null;
                          }),
                  ),
                  if (!_allStates)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _chooseStates,
                      icon: const Icon(Icons.location_on_outlined),
                      label: Text(_stateSelectionLabel),
                    ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Priority in My Society'),
                    subtitle: Text(
                      society == null
                          ? 'Available once your society approves your resident account.'
                          : 'Show this coupon first to other residents of $society.',
                    ),
                    value: _societyPriority,
                    onChanged: _saving || society == null
                        ? null
                        : (value) => setState(() => _societyPriority = value),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.local_offer_outlined),
                    label: Text(_saving ? 'Sharing…' : 'Share Coupon'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponStatePicker extends StatefulWidget {
  const _CouponStatePicker({required this.selected});

  final Set<String> selected;

  @override
  State<_CouponStatePicker> createState() => _CouponStatePickerState();
}

class _CouponStatePickerState extends State<_CouponStatePicker> {
  late final _selected = {...widget.selected};
  late Future<List<String>> _states = ApiService.getIndianStates();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _states,
      builder: (context, snapshot) {
        final states = snapshot.data ?? [];
        return AlertDialog(
          title: const Text('Select states and UTs'),
          content: SizedBox(
            width: 400,
            height: 320,
            child: snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : states.isEmpty
                ? Center(
                    child: TextButton(
                      onPressed: () => setState(
                        () => _states = ApiService.getIndianStates(),
                      ),
                      child: const Text('Could not load states. Try again'),
                    ),
                  )
                : ListView.builder(
                    itemCount: states.length,
                    itemBuilder: (context, index) {
                      final state = states[index];
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(state),
                        value: _selected.contains(state),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(state);
                          } else {
                            _selected.remove(state);
                          }
                        }),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: states.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected),
              child: Text('Done (${_selected.length})'),
            ),
          ],
        );
      },
    );
  }
}
