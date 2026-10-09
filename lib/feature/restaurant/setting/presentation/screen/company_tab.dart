import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/branch_setting_model.dart';
import '../provider/branch_setting_provider.dart';
import '../widget/section_card_widget.dart';
import '../widget/settings_skeleton.dart';

class CompanyTab extends ConsumerStatefulWidget {
  const CompanyTab({super.key});

  @override
  ConsumerState<CompanyTab> createState() => _CompanyTabState();
}

class _CompanyTabState extends ConsumerState<CompanyTab> {
  // Controllers
  final _restaurantName = TextEditingController();
  final _branchName     = TextEditingController();
  final _phone          = TextEditingController();
  final _email          = TextEditingController();
  final _address        = TextEditingController();
  final _city           = TextEditingController();
  final _website        = TextEditingController();
  final _ntn            = TextEditingController();
  final _strn           = TextEditingController();
  final _posId          = TextEditingController();
  final _openingTime    = TextEditingController();
  final _closingTime    = TextEditingController();
  bool _is24Hours = false;
  bool _loaded = false;

  @override
  void dispose() {
    _restaurantName.dispose(); _branchName.dispose();
    _phone.dispose();  _email.dispose();   _address.dispose();
    _city.dispose();   _website.dispose(); _ntn.dispose();
    _strn.dispose();   _posId.dispose();   _openingTime.dispose();
    _closingTime.dispose();
    super.dispose();
  }

  void _populate(BranchModel b) {
    if (_loaded) return;
    _loaded = true;
    _restaurantName.text = b.restaurantName;
    _branchName.text     = b.name;
    _phone.text          = b.phone;
    _email.text          = b.email;
    _address.text        = b.address;
    _city.text           = b.city;
    _website.text        = b.website;
    _ntn.text            = b.ntn;
    _strn.text           = b.strn;
    _posId.text          = b.posId;
    _openingTime.text    = b.openingTime;
    _closingTime.text    = b.closingTime;
    _is24Hours           = b.is24Hours;
  }

  void _discard(BranchModel b) {
    _loaded = false;
    _populate(b);
    setState(() {});
  }

  void _save(BranchModel current) {
    final updated = current.copyWith(
      restaurantName: _restaurantName.text.trim(),
      name:           _branchName.text.trim(),
      phone:          _phone.text.trim(),
      email:          _email.text.trim(),
      address:        _address.text.trim(),
      city:           _city.text.trim(),
      website:        _website.text.trim(),
      ntn:            _ntn.text.trim(),
      strn:           _strn.text.trim(),
      posId:          _posId.text.trim(),
      openingTime:    _openingTime.text.trim(),
      closingTime:    _closingTime.text.trim(),
      is24Hours:      _is24Hours,
    );
    ref.read(branchSettingsProvider.notifier).save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchSettingsProvider);

    // Populate fields when data loads
    if (state.branch != null) _populate(state.branch!);

    // Success snackbar
    if (state.saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Color(0xFF22C55E),
        ));
        ref.read(branchSettingsProvider.notifier).clearError();
      });
    }

    // Error snackbar
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.redAccent,
        ));
        ref.read(branchSettingsProvider.notifier).clearError();
      });
    }

    if (state.loading) {
      return const SettingsSkeleton(sections: [
        [SkeletonRow.fields(1), SkeletonRow.fields(2), SkeletonRow.fields(2), SkeletonRow.fields(1), SkeletonRow.fields(1)],
        [SkeletonRow.fields(2), SkeletonRow.fields(1)],
        [SkeletonRow.fields(2), SkeletonRow.toggle()],
      ]);
    }

    final branch = state.branch;
    if (branch == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Could not load data', style: TextStyle(color: kMuted)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.read(branchSettingsProvider.notifier).load(),
            child: const Text('Try again'),
          ),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader(
        title: 'Company Info',
        subtitle: 'This info appears on invoices and receipts',
      ),

      // ── Basic Info ────────────────────────────────────────────────────
      SectionCard(title: 'BASIC INFO', children: [
        _Field(label: 'Restaurant name', ctrl: _restaurantName),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field(label: 'Branch name', ctrl: _branchName)),
          const SizedBox(width: 12),
          Expanded(child: _Field(label: 'Phone', ctrl: _phone, kt: TextInputType.phone)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field(label: 'Email', ctrl: _email, kt: TextInputType.emailAddress)),
          const SizedBox(width: 12),
          Expanded(child: _Field(label: 'Website', ctrl: _website)),
        ]),
        const SizedBox(height: 12),
        _Field(label: 'Address', ctrl: _address, maxLines: 2),
        const SizedBox(height: 12),
        _Field(label: 'City', ctrl: _city),
      ]),

      // ── Business Identifiers ──────────────────────────────────────────
      SectionCard(title: 'BUSINESS IDENTIFIERS', children: [
        Row(children: [
          Expanded(child: _Field(label: 'NTN Number', ctrl: _ntn)),
          const SizedBox(width: 12),
          Expanded(child: _Field(label: 'STRN (Sales Tax)', ctrl: _strn)),
        ]),
        const SizedBox(height: 12),
        _Field(label: 'POS ID', ctrl: _posId),
      ]),

      // ── Working Hours ─────────────────────────────────────────────────
      SectionCard(title: 'WORKING HOURS', children: [
        StatefulBuilder(builder: (_, ss) => Column(children: [
          Row(children: [
            Expanded(child: _Field(
              label: 'Opening time',
              ctrl: _openingTime,
              enabled: !_is24Hours,
            )),
            const SizedBox(width: 12),
            Expanded(child: _Field(
              label: 'Closing time',
              ctrl: _closingTime,
              enabled: !_is24Hours,
            )),
          ]),
          const SizedBox(height: 12),
          _ToggleRow(
            label: '24 hours open',
            subtitle: 'Opening/closing times are ignored',
            value: _is24Hours,
            onChanged: (v) {
              ss(() => _is24Hours = v);
              setState(() {});
            },
          ),
        ])),
      ]),

      // ── Buttons ───────────────────────────────────────────────────────
      Row(children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: kMuted,
            side: const BorderSide(color: kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _discard(branch),
          icon: const SvgIcon(AppIcons.close, size: 16),
          label: const Text('Discard'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: state.saving ? null : () => _save(branch),
          icon: state.saving
              ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const SvgIcon(AppIcons.check, size: 16),
          label: Text(state.saving ? 'Saving...' : 'Save changes'),
        ),
      ]),
      const SizedBox(height: 24),
    ]);
  }
}

// ── Local Field Widget ────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final TextInputType? kt;
  final int maxLines;
  final bool enabled;

  const _Field({
    required this.label,
    required this.ctrl,
    this.kt,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: kSub)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: kt,
        maxLines: maxLines,
        enabled: enabled,
        style: const TextStyle(fontSize: 13, color: kText),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled ? kLight : const Color(0xFFF0F1F5),
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kPrimary, width: 1.5)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: kBorder.withOpacity(0.5))),
        ),
      ),
    ],
  );
}

// ── Toggle Row ────────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: kMuted)),
      ]),
    ),
    Switch(
      value: value,
      onChanged: onChanged,
      activeColor: kPrimary,
    ),
  ]);
}