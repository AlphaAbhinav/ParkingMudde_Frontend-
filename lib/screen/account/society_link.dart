import 'package:flutter/material.dart';
import 'package:parkingmudde/services/api_service.dart';

enum SocietyLinkStatus {
  unlinked,
  pending,
  linked;

  static SocietyLinkStatus fromCommunity(Map<String, dynamic> community) {
    if (community['linked'] == true) return linked;
    if (community['pending'] == true ||
        community['resident'] != null ||
        community['society'] != null) {
      return pending;
    }
    return unlinked;
  }
}

class SocietyLinkCard extends StatelessWidget {
  const SocietyLinkCard({super.key, required this.status, required this.onTap});

  final SocietyLinkStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (status == SocietyLinkStatus.linked) return const SizedBox.shrink();

    final isPending = status == SocietyLinkStatus.pending;
    const blue = Color(0xFF184B8C);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(
          isPending ? Icons.schedule_rounded : Icons.apartment_rounded,
          color: blue,
        ),
        title: Text(
          isPending ? 'Society Request Pending' : 'Link My Society',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          isPending
              ? 'Waiting for your society admin to approve your request.'
              : 'Apply for access to your society.',
        ),
        trailing: isPending ? null : const Icon(Icons.chevron_right_rounded),
        onTap: isPending ? null : onTap,
      ),
    );
  }
}

Future<void> showSocietyLinkSheet(
  BuildContext context, {
  VoidCallback? onSocietyNotListed,
}) async {
  final wantsRegistration = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    barrierColor: const Color(0x80102742),
    constraints: const BoxConstraints(maxWidth: 500),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) =>
        _SocietyLinkSheet(canRequestRegistration: onSocietyNotListed != null),
  );
  if (wantsRegistration == true && context.mounted) onSocietyNotListed?.call();
}

class _SocietyLinkSheet extends StatefulWidget {
  const _SocietyLinkSheet({required this.canRequestRegistration});

  final bool canRequestRegistration;

  @override
  State<_SocietyLinkSheet> createState() => _SocietyLinkSheetState();
}

class _SocietyLinkSheetState extends State<_SocietyLinkSheet> {
  static const _navy = Color(0xFF163B6D);
  static const _blue = Color(0xFF2459D4);
  static const _slate = Color(0xFF475569);

  final _formKey = GlobalKey<FormState>();
  final _tower = TextEditingController();
  final _unit = TextEditingController();
  Map<String, dynamic>? _profile;
  List<dynamic> _societies = [];
  String? _societyId;
  String? _loadError;
  String? _submitError;
  bool _isLoading = true;
  bool _isSubmitting = false;
  SocietyLinkStatus _status = SocietyLinkStatus.unlinked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tower.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final profile = await ApiService.refreshCurrentUser();
    if (!mounted) return;
    final userId = profile?['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      _showLoadError('Please log in to request society access.');
      return;
    }

    final community = await ApiService.getMyCommunity(userId);
    if (!mounted) return;
    if (community['success'] == false) {
      _showLoadError('Could not check your society status. Please try again.');
      return;
    }

    final status = SocietyLinkStatus.fromCommunity(community);
    if (status != SocietyLinkStatus.unlinked) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.getSocieties();
    if (!mounted) return;
    if (result['success'] != true) {
      _showLoadError('Could not load societies. Please try again.');
      return;
    }

    setState(() {
      _profile = profile;
      _societies = result['societies'] as List<dynamic>;
      _isLoading = false;
    });
  }

  void _showLoadError(String message) {
    setState(() {
      _loadError = message;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    final profile = _profile!;
    final fullName = (profile['full_name']?.toString() ?? '').trim();
    final mobile = (profile['mobile_number']?.toString() ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final email = (profile['email']?.toString() ?? '').trim().toLowerCase();
    if (fullName.isEmpty ||
        !RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile) ||
        email.isEmpty) {
      setState(() {
        _submitError =
            'Please complete your name, mobile number, and email in My Profile.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final userId = profile['user_id'].toString();
    final result = await ApiService.updateUserProfile(
      userId: userId,
      fullName: fullName,
      mobileNumber: mobile,
      email: email,
      societyId: _societyId,
      tower: _tower.text.trim(),
      unitNumber: _unit.text.trim(),
    );
    if (!mounted) return;

    final sent = result['success'] == true;
    final community = await ApiService.getMyCommunity(userId);
    if (!mounted) return;
    final status = SocietyLinkStatus.fromCommunity(community);
    setState(() {
      _isSubmitting = false;
      _status = sent && status == SocietyLinkStatus.unlinked
          ? SocietyLinkStatus.pending
          : status;
      if (!sent && status == SocietyLinkStatus.unlinked) {
        _submitError =
            result['message']?.toString() ??
            'Could not send your request. Please try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF214FA1)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Link My Society',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
            ),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            color: _blue,
            semanticsLabel: 'Checking society access',
          ),
        ),
      );
    }
    if (_loadError case final error?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildError(context, error),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Try again')),
        ],
      );
    }
    if (_status == SocietyLinkStatus.linked) {
      return _buildNotice(
        icon: Icons.check_circle_outline_rounded,
        message: 'Your society is linked.',
        background: const Color(0xFFECFDF3),
        foreground: const Color(0xFF166534),
      );
    }
    if (_status == SocietyLinkStatus.pending) {
      return _buildNotice(
        icon: Icons.schedule_rounded,
        message: 'Your society access request is waiting for admin approval.',
        background: const Color(0xFFFFF7E6),
        foreground: const Color(0xFF854D0E),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_societies.isEmpty)
          _buildNotice(
            icon: Icons.location_city_rounded,
            message: 'No registered societies are available.',
            background: const Color(0xFFF1F5F9),
            foreground: _slate,
          )
        else
          _buildRequestForm(),
        if (widget.canRequestRegistration) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEDF4FF),
              foregroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_business_rounded, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Society not listed? Apply to register it'),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return _buildNotice(
      icon: Icons.error_outline_rounded,
      message: message,
      background: colors.errorContainer,
      foreground: colors.onErrorContainer,
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String message,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(14));
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _slate),
      prefixIcon: Icon(icon, size: 20),
      prefixIconColor: _navy,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      border: border,
      enabledBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _blue, width: 2),
      ),
      errorMaxLines: 3,
    );
  }

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            borderRadius: BorderRadius.circular(14),
            decoration: _fieldDecoration(
              'Select Society',
              Icons.location_city_rounded,
            ),
            items: _societies.map((society) {
              return DropdownMenuItem<String>(
                value: society['id'].toString(),
                child: Text(
                  society['name'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isSubmitting ? null : (value) => _societyId = value,
            validator: (value) => value == null ? 'Select a society.' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _tower,
            readOnly: _isSubmitting,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              'Tower / Block (optional)',
              Icons.business_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _unit,
            readOnly: _isSubmitting,
            decoration: _fieldDecoration(
              'Flat / Unit',
              Icons.door_front_door_outlined,
            ),
            validator: (value) => value!.trim().isEmpty
                ? 'Enter your flat or unit number.'
                : null,
          ),
          if (_submitError case final error?) ...[
            const SizedBox(height: 12),
            _buildError(context, error),
          ],
          const SizedBox(height: 14),
          const Text(
            'Your society admin will review your request.',
            style: TextStyle(color: _slate, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: _navy,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isSubmitting ? 'Sending…' : 'Send Request'),
          ),
        ],
      ),
    );
  }
}
