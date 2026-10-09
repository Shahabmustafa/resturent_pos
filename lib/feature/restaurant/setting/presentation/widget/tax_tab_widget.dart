import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/widget/section_card_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/branch_tax_model.dart';
import '../provider/tax_provider.dart';
import '../widget/field_widget.dart';
import 'settings_skeleton.dart';

class TaxTab extends ConsumerStatefulWidget {
  const TaxTab({super.key});

  @override
  ConsumerState<TaxTab> createState() => _TaxTabState();
}

class _TaxTabState extends ConsumerState<TaxTab> {
  // FBR field controllers
  late final TextEditingController _fbrTokenCtrl;
  late final TextEditingController _fbrUrlCtrl;
  bool _controllersInit = false;

  @override
  void dispose() {
    _fbrTokenCtrl.dispose();
    _fbrUrlCtrl.dispose();
    super.dispose();
  }

  void _initControllers(BranchTaxSettings s) {
    if (_controllersInit) return;
    _controllersInit = true;
    _fbrTokenCtrl = TextEditingController(text: s.fbrToken);
    _fbrUrlCtrl   = TextEditingController(text: s.fbrUrl);
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(taxProvider);
    final notifier = ref.read(taxProvider.notifier);

    // Success snackbar
    if (state.saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tax settings saved ✓'),
          backgroundColor: AppColors.success,
        ));
        notifier.clearError();
      });
    }

    if (state.error != null && !state.saving) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.error!),
          backgroundColor: AppColors.danger,
        ));
        notifier.clearError();
      });
    }

    if (state.loading) {
      return const SettingsSkeleton(sections: [
        [SkeletonRow.toggle(), SkeletonRow.toggle(), SkeletonRow.fields(2)],
        [SkeletonRow.fields(2), SkeletonRow.fields(2)],
        [SkeletonRow.toggle(), SkeletonRow.fields(2)],
      ]);
    }

    final s = state.settings;
    if (s == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Could not load data', style: TextStyle(color: AppColors.textGrey)),
        const SizedBox(height: 12),
        TextButton(onPressed: notifier.load, child: const Text('Try again')),
      ]));
    }

    _initControllers(s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Tax Configuration',
          subtitle: 'GST, FBR integration and per-category tax rules',
        ),

        // ── TAX SETTINGS ─────────────────────────────────────────────────
        SectionCard(title: 'TAX SETTINGS', children: [
          _ToggleRow(
            label: 'Enable tax on all orders',
            subtitle: 'Tax is added to every order automatically',
            value: s.enableTax,
            onChanged: (v) => notifier.update(s.copyWith(enableTax: v)),
          ),
          _ToggleRow(
            label: 'Tax inclusive in price',
            subtitle: 'Prices already include tax',
            value: s.taxInclusive,
            onChanged: (v) => notifier.update(s.copyWith(taxInclusive: v)),
          ),
          _ToggleRow(
            label: 'Show tax breakdown on receipt',
            value: s.showOnReceipt,
            onChanged: (v) => notifier.update(s.copyWith(showOnReceipt: v)),
          ),
          // Active tax rate summary
          if (s.enableTax && s.slabs.any((sl) => sl.isActive)) ...[
            const AppDivider(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                const SvgIcon(AppIcons.calculateOutlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Effective tax rate: ${s.activeTaxRate.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  s.slabs.where((sl) => sl.isActive).map((sl) => sl.name).join(' + '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ]),
            ),
          ],
        ]),

        // ── TAX SLABS ─────────────────────────────────────────────────────
        SectionCard(title: 'TAX SLABS', children: [
          if (s.slabs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No tax slabs — add one below',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            ),
          ...s.slabs.asMap().entries.map((e) {
            final i    = e.key;
            final slab = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                // Name field
                Expanded(
                  flex: 3,
                  child: _SlabTextField(
                    value: slab.name,
                    hint: 'Tax name (e.g. GST)',
                    onChanged: (v) => notifier.updateSlab(i, slab.copyWith(name: v)),
                  ),
                ),
                const SizedBox(width: 8),
                // Rate field
                SizedBox(
                  width: 80,
                  child: _SlabTextField(
                    value: slab.rate > 0 ? slab.rate.toString() : '',
                    hint: '0',
                    suffix: '%',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => notifier.updateSlab(i, slab.copyWith(rate: double.tryParse(v) ?? 0)),
                  ),
                ),
                const SizedBox(width: 8),
                // Active toggle chip
                GestureDetector(
                  onTap: () => notifier.updateSlab(i, slab.copyWith(isActive: !slab.isActive)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: slab.isActive ? AppColors.successLight : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: slab.isActive
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.warning.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      slab.isActive ? 'Active' : 'Optional',
                      style: TextStyle(
                        fontSize: 11,
                        color: slab.isActive ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                IconButton(
                  onPressed: () => notifier.removeSlab(i),
                  icon: const SvgIcon(AppIcons.deleteOutline, size: 18, color: AppColors.danger),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            );
          }),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: notifier.addSlab,
            icon: const SvgIcon(AppIcons.add, size: 16, color: AppColors.primary),
            label: const Text('Add tax slab',
                style: TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ]),

        // ── FBR INTEGRATION ───────────────────────────────────────────────
        SectionCard(title: 'FBR INTEGRATION', children: [
          _ToggleRow(
            label: 'FBR POS integration enable',
            subtitle: 'Every transaction is reported to the FBR server',
            value: s.fbrEnabled,
            onChanged: (v) => notifier.update(s.copyWith(fbrEnabled: v)),
          ),
          if (s.fbrEnabled) ...[
            const AppDivider(),
            _LabeledField(
              label: 'FBR POS token',
              ctrl: _fbrTokenCtrl,
              hint: 'FBR-TOKEN-XXXX-2024',
              onChanged: (v) => notifier.update(s.copyWith(fbrToken: v)),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'PRAL API URL',
              ctrl: _fbrUrlCtrl,
              hint: 'https://esp.fbr.gov.pk/api/...',
              onChanged: (v) => notifier.update(s.copyWith(fbrUrl: v)),
            ),
            const SizedBox(height: 14),
            Row(children: [
              // Test connection button
              state.testingFbr
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : OutlineBtn(
                      label: 'Test connection',
                      icon: AppIcons.wifiTethering,
                      onTap: notifier.testFbr,
                    ),
              const SizedBox(width: 12),
              // FBR status chip
              if (state.fbrTestResult != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.fbrTestResult!
                        ? AppColors.successLight
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    SvgIcon(AppIcons.circle, size: 8,
                        color: state.fbrTestResult! ? AppColors.success : AppColors.danger),
                    const SizedBox(width: 6),
                    Text(
                      state.fbrTestResult!
                          ? 'Connected ✓'
                          : 'Connection failed ✗',
                      style: TextStyle(
                        fontSize: 12,
                        color: state.fbrTestResult! ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]),
                ),
            ]),
          ],
        ]),

        // ── ACTIONS ───────────────────────────────────────────────────────
        Row(children: [
          OutlineBtn(
            label: 'Discard',
            icon: AppIcons.close,
            onTap: notifier.load,
          ),
          const SizedBox(width: 12),
          PrimaryBtn(
            label: state.saving ? 'Saving...' : 'Save changes',
            icon: AppIcons.check,
            onTap: state.saving ? null : () async {
              await notifier.save();
            },
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        if (subtitle != null)
          Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      ])),
      Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    ]),
  );
}

class _SlabTextField extends StatefulWidget {
  final String value, hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _SlabTextField({
    required this.value,
    required this.hint,
    this.suffix,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  State<_SlabTextField> createState() => _SlabTextFieldState();
}

class _SlabTextFieldState extends State<_SlabTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _ctrl,
    keyboardType: widget.keyboardType,
    onChanged: widget.onChanged,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: widget.hint,
      suffixText: widget.suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      filled: true,
      fillColor: AppColors.bg,
    ),
  );
}

class _LabeledField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.ctrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
          fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      TextFormField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          filled: true,
          fillColor: AppColors.bg,
        ),
      ),
    ],
  );
}
