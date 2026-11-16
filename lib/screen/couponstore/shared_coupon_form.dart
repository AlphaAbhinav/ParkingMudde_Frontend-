import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkingmudde/services/api_service.dart';

import 'shared_coupon_card.dart';

const _couponBlue = Color(0xFF184B8C);
const _couponNavy = Color(0xFF102A52);

Future<bool?> showShareCouponForm(
  BuildContext context, {
  required String userId,
  required String? state,
  required String? societyName,
  SharedCoupon? coupon,
}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    barrierColor: const Color(0x88102A52),
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => Theme(
      data: theme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _couponBlue,
          brightness: theme.brightness,
        ),
      ),
      child: _ShareCouponForm(
        userId: userId,
        state: state,
        societyName: societyName,
        coupon: coupon,
      ),
    ),
  );
}

class _ShareCouponForm extends StatefulWidget {
  const _ShareCouponForm({
    required this.userId,
    this.state,
    this.societyName,
    this.coupon,
  });

  final String userId;
  final String? state;
  final String? societyName;
  final SharedCoupon? coupon;

  @override
  State<_ShareCouponForm> createState() => _ShareCouponFormState();
}

class _ShareCouponFormState extends State<_ShareCouponForm> {
  static const _maxImageBytes = 5 * 1024 * 1024;
  static const _imageTypes = {'image/jpeg', 'image/png', 'image/webp'};
  final _formKey = GlobalKey<FormState>();
  late final _brand = TextEditingController(text: widget.coupon?.brand);
  late final _title = TextEditingController(text: widget.coupon?.title);
  late final _code = TextEditingController(text: widget.coupon?.code);
  late final _description = TextEditingController(
    text: widget.coupon?.description,
  );
  late final _website = TextEditingController(
    text: widget.coupon?.website?.toString(),
  );
  late Set<String> _states =
      widget.coupon?.states?.toSet() ??
      {if (widget.state case final state?) state};
  late bool _allStates = widget.coupon?.states?.isEmpty == true;
  late bool _societyPriority =
      widget.societyName != null && widget.coupon?.priorityRequested == true;
  ({Uint8List bytes, String filename, String mimeType})? _pickedImage;
  String? _uploadedImageUrl;
  bool _removeImage = false;
  bool _pickingImage = false;
  String? _imageError;
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
    _website.dispose();
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

  Future<void> _chooseImage() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _pickingImage = true;
      _imageError = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (!mounted || file == null) return;
      final type =
          file.mimeType ??
          switch (file.name.split('.').last.toLowerCase()) {
            'jpg' || 'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => '',
          };
      if (!_imageTypes.contains(type)) {
        setState(() => _imageError = 'Choose a JPG, PNG or WEBP image.');
        return;
      }
      final size = await file.length();
      if (!mounted) return;
      if (size == 0 || size > _maxImageBytes) {
        setState(() => _imageError = 'Choose an image up to 5 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImage = (bytes: bytes, filename: file.name, mimeType: type);
        _uploadedImageUrl = null;
        _removeImage = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _imageError = 'Could not read the selected photo.');
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _uploadedImageUrl = null;
      _removeImage = widget.coupon?.imageUrl != null;
      _imageError = null;
    });
  }

  Future<void> _submit() async {
    if (_saving || _pickingImage) return;
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final field = invalid.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!field.mounted) return;
        Scrollable.ensureVisible(
          field.context,
          alignment: 0.12,
          duration: const Duration(milliseconds: 220),
        );
      });
      return;
    }
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
    final image = _pickedImage;
    if (image != null && _uploadedImageUrl == null) {
      final upload = await ApiService.uploadSharedCouponImage(
        userId: widget.userId,
        bytes: image.bytes,
        filename: image.filename,
        mimeType: image.mimeType,
      );
      if (!mounted) return;
      if (upload['success'] != true) {
        setState(() {
          _saving = false;
          _error =
              upload['message']?.toString() ??
              'Could not upload the coupon image.';
        });
        return;
      }
      _uploadedImageUrl = upload['image_url'] as String;
    }
    final result = await ApiService.shareCoupon(
      userId: widget.userId,
      brand: _brand.text.trim(),
      title: _title.text.trim(),
      code: _code.text.trim(),
      description: _description.text.trim(),
      states: _allStates ? [] : (_states.toList()..sort()),
      societyPriority: _societyPriority,
      websiteUrl: sharedCouponWebsiteUri(_website.text)?.toString(),
      couponId: widget.coupon?.id,
      imageUrl: _uploadedImageUrl,
      removeImage: _removeImage,
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
    int maxLength,
    IconData icon, {
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
      decoration: _decoration(label, icon),
      validator: optional
          ? null
          : (value) => (value ?? '').trim().isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      prefixIconColor: colors.onSurfaceVariant,
      filled: true,
      fillColor: theme.brightness == Brightness.light
          ? const Color(0xFFF6F8FC)
          : colors.surfaceContainerLow,
      border: border,
      enabledBorder: border.copyWith(
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: theme.brightness == Brightness.light
              ? _couponBlue
              : colors.primary,
          width: 1.5,
        ),
      ),
      counterText: '',
    );
  }

  Widget _offerFields() {
    return _CouponFormSection(
      title: 'Offer details',
      icon: Icons.local_offer_outlined,
      children: [
        _field(_title, 'Offer title', 160, Icons.sell_outlined),
        LayoutBuilder(
          builder: (context, constraints) {
            final business = _field(
              _brand,
              'Business or brand',
              120,
              Icons.storefront_outlined,
            );
            final code = _field(
              _code,
              'Coupon code',
              120,
              Icons.confirmation_number_outlined,
            );
            return constraints.maxWidth >= 420
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: business),
                      const SizedBox(width: 12),
                      Expanded(child: code),
                    ],
                  )
                : Column(spacing: 12, children: [business, code]);
          },
        ),
        TextFormField(
          controller: _website,
          enabled: !_saving,
          maxLength: 2083,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: _decoration(
            'Website link (optional)',
            Icons.link_rounded,
            hint: 'https://example.com',
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty ||
                sharedCouponWebsiteUri(value) != null) {
              return null;
            }
            return 'Enter a full website URL starting with https:// or http://.';
          },
        ),
        _field(
          _description,
          'Terms or details (optional)',
          600,
          Icons.notes_rounded,
          optional: true,
        ),
      ],
    );
  }

  Widget _imageField(ColorScheme colors) {
    final existingUrl = _removeImage ? null : widget.coupon?.imageUrl;
    final bytes = _pickedImage?.bytes;
    final hasImage = bytes != null || existingUrl != null;
    return _CouponFormSection(
      title: 'Coupon image',
      icon: Icons.image_outlined,
      optional: true,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: colors.surfaceContainerLow,
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: bytes != null
                    ? Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Text('Preview unavailable')),
                      )
                    : SharedCouponImage(url: existingUrl!),
              ),
            ),
          ),
        if (!hasImage)
          Text(
            'JPG, PNG or WEBP up to 5 MB.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _saving || _pickingImage ? null : _chooseImage,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: Text(hasImage ? 'Replace image' : 'Add image'),
            ),
            if (hasImage)
              TextButton(
                onPressed: _saving || _pickingImage ? null : _clearImage,
                child: const Text('Remove image'),
              ),
          ],
        ),
        if (_imageError case final error?)
          Text(error, style: TextStyle(color: colors.error)),
      ],
    );
  }

  Widget _availability(ColorScheme colors) {
    final society = widget.societyName;
    return _CouponFormSection(
      title: 'Availability',
      icon: Icons.location_on_outlined,
      children: [
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
            icon: const Icon(Icons.map_outlined, size: 19),
            label: Text(_stateSelectionLabel),
          ),
        const Divider(height: 1),
        if (society != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.apartment_rounded),
            title: const Text('Priority in My Society'),
            subtitle: Text(
              'Show this coupon first to other residents of $society.',
            ),
            value: _societyPriority,
            onChanged: _saving
                ? null
                : (value) => setState(() => _societyPriority = value),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Society priority is available after your society approves your resident account.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _header(bool editing, bool compact, TextTheme textTheme) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_couponNavy, _couponBlue],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          compact ? 8 : 19,
          12,
          compact ? 8 : 19,
        ),
        child: Row(
          children: [
            if (!compact) ...[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                editing ? 'Edit Coupon' : 'Add Coupon',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: _saving ? null : () => Navigator.pop(context),
              color: Colors.white,
              disabledColor: Colors.white38,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(bool editing, ColorScheme colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: FilledButton.icon(
          onPressed: _saving || _pickingImage ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _couponBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_rounded, size: 20),
          label: Text(
            _saving ? 'Saving…' : (editing ? 'Save changes' : 'Share Coupon'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.coupon != null;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canvas = theme.brightness == Brightness.light
        ? const Color(0xFFF0F4FA)
        : colors.surfaceContainerLow;
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: LayoutBuilder(
            builder: (context, constraints) => ColoredBox(
              color: canvas,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(
                    editing,
                    constraints.maxHeight < 460,
                    theme.textTheme,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          spacing: 14,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _offerFields(),
                            _imageField(colors),
                            _availability(colors),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_error case final error?)
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: colors.errorContainer,
                        child: Text(
                          error,
                          style: TextStyle(color: colors.onErrorContainer),
                        ),
                      ),
                    ),
                  if (constraints.maxHeight >= 180) _footer(editing, colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponFormSection extends StatelessWidget {
  const _CouponFormSection({
    required this.title,
    required this.icon,
    required this.children,
    this.optional = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFE8F1FF)
                      : colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: theme.brightness == Brightness.light
                      ? _couponBlue
                      : colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (optional)
                Text(
                  'Optional',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          ...children,
        ],
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
