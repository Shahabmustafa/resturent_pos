import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/feature/restaurant/setting/presentation/widget/section_card_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/branch_setting_model.dart';
import '../../data/model/receipt_settings_model.dart';
import '../provider/receipt_settings_provider.dart';
import '../widget/settings_skeleton.dart';
import '../widget/field_widget.dart';

class ReceiptTab extends ConsumerWidget {
  const ReceiptTab({super.key});

  static const _fonts = ['Default', 'Compact', 'Mono', 'Serif'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptSettingsProvider);
    final notifier = ref.read(receiptSettingsProvider.notifier);
    final branchAsync = ref.watch(receiptBranchProvider);

    if (state.loading) {
      return const SettingsSkeleton(preview: true, sections: [
        [SkeletonRow.fields(1), SkeletonRow.toggle()],
        [SkeletonRow.fields(2)],
        [SkeletonRow.toggle(), SkeletonRow.toggle(), SkeletonRow.toggle(), SkeletonRow.toggle()],
      ]);
    }

    if (state.settings == null) {
      return Center(child: Text(state.error ?? 'Error loading settings'));
    }

    final s = state.settings!;
    void patch(ReceiptSettings updated) => notifier.update(updated);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Receipt Customization',
          subtitle: 'Configure the logo, fonts, footer text and layout',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(children: [
                // ── LOGO ──
                SectionCard(title: 'LOGO', children: [
                  GestureDetector(
                    onTap: () async {
                      const typeGroup = XTypeGroup(
                        label: 'images',
                        extensions: ['jpg', 'jpeg', 'png'],
                      );
                      final file =
                      await openFile(acceptedTypeGroups: [typeGroup]);
                      if (file == null) return;

                      final url = await notifier.uploadLogo(File(file.path));
                      if (url == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logo upload failed'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.bg,
                      ),
                      child: s.logoUrl != null
                      // ── Show the uploaded logo ──
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(s.logoUrl!, fit: BoxFit.contain),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => patch(s.copyWith(logoUrl: '')),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SvgIcon(AppIcons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      // ── Upload placeholder ──
                          : state.saving
                          ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                          : const Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgIcon(AppIcons.cloudUploadOutlined,
                                  size: 28, color: AppColors.primary),
                              SizedBox(height: 6),
                              Text('Upload logo',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey)),
                              Text('PNG / JPG — max 2MB',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGrey)),
                            ]),
                      ),
                    ),
                  ),
                ]),

                // ── FONT ──
                SectionCard(title: 'FONT FAMILY', children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                        _fonts.length,
                            (i) => GestureDetector(
                          onTap: () => patch(s.copyWith(fontIndex: i)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: s.fontIndex == i
                                  ? AppColors.primaryLight
                                  : AppColors.bg,
                              border: Border.all(
                                color: s.fontIndex == i
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _fonts[i],
                              style: TextStyle(
                                fontSize: 12,
                                color: s.fontIndex == i
                                    ? AppColors.primary
                                    : AppColors.textGrey,
                                fontWeight: s.fontIndex == i
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        )),
                  ),
                ]),

                // ── CONTENT OPTIONS ──
                SectionCard(title: 'CONTENT OPTIONS', children: [
                  _Toggle(
                    label: 'Show logo on receipt',
                    value: s.showLogo,
                    onChanged: (v) => patch(s.copyWith(showLogo: v)),
                  ),
                  _Toggle(
                    label: 'Show tax breakdown',
                    value: s.showTaxBreakdown,
                    onChanged: (v) => patch(s.copyWith(showTaxBreakdown: v)),
                  ),
                  _Toggle(
                    label: 'Show cashier name',
                    value: s.showCashierName,
                    onChanged: (v) => patch(s.copyWith(showCashierName: v)),
                  ),
                  _Toggle(
                    label: 'FBR QR code print',
                    value: s.showFbrQr,
                    onChanged: (v) => patch(s.copyWith(showFbrQr: v)),
                  ),
                  const AppDivider(),
                  _EditableField(
                    label: 'Footer / Terms text',
                    value: s.footerText,
                    maxLines: 2,
                    onChanged: (v) => patch(s.copyWith(footerText: v)),
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Custom header note',
                    value: s.headerNote,
                    onChanged: (v) => patch(s.copyWith(headerNote: v)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 20),
            // ── Pass branch data to the preview ──
            branchAsync.when(
              data: (branch) => _ReceiptPreview(settings: s, branch: branch),
              loading: () => const ReceiptPreviewSkeleton(),
              error: (_, __) => _ReceiptPreview(settings: s, branch: null),
            ),
          ],
        ),

        // ── ACTIONS ──
        Row(children: [
          OutlineBtn(
            label: 'Discard',
            icon: AppIcons.close,
            onTap: () => notifier.load(),
          ),
          const SizedBox(width: 12),
          PrimaryBtn(
            label: state.saving ? 'Saving...' : 'Save changes',
            icon: AppIcons.check,
            onTap: state.saving
                ? null
                : () async {
              final ok = await notifier.save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Settings saved!' : 'Error: ${state.error}'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textDark)),
        Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary),
      ],
    ),
  );
}

class _EditableField extends StatelessWidget {
  final String label, value;
  final int maxLines;
  final ValueChanged<String> onChanged;
  const _EditableField({
    required this.label,
    required this.value,
    this.maxLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value,
    maxLines: maxLines,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(fontSize: 12, color: AppColors.textGrey),
      border:
      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

// ── Receipt Preview (thermal-safe: black only) ────────────────────────────────

class _ReceiptPreview extends StatelessWidget {
  final ReceiptSettings settings;
  final BranchModel? branch;
  const _ReceiptPreview({required this.settings, required this.branch});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LIVE PREVIEW',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            if (settings.showLogo) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: settings.logoUrl != null &&
                    settings.logoUrl!.isNotEmpty
                    ? Image.network(
                  settings.logoUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SvgIcon(AppIcons.restaurant,
                      size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 6),
            ],
            // ── Dynamic restaurant name ──
            Text(
              branch?.restaurantName.isNotEmpty == true
                  ? branch!.restaurantName
                  : 'Restaurant Name',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black),
            ),
            Text(settings.headerNote,
                style: const TextStyle(
                    fontSize: 10, color: Colors.black54)),
            // ── Dynamic address ──
            Text(
              branch?.address.isNotEmpty == true
                  ? branch!.address
                  : '',
              style: const TextStyle(
                  fontSize: 10, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            // ── Dynamic phone ──
            if (branch?.phone.isNotEmpty == true)
              Text(
                branch!.phone,
                style: const TextStyle(
                    fontSize: 10, color: Colors.black54),
              ),
            const _RDiv(),
            const _RRow(l: 'Order #', r: '#1042'),
            const _RRow(l: 'Table', r: 'T-05'),
            const _RRow(l: 'Date', r: 'Jun 10, 2026'),
            const _RDiv(),
            const _RRow(l: 'Zinger Burger x2', r: '£1,200.00'),
            const _RRow(l: 'Fries x1', r: '£280.00'),
            const _RRow(l: 'Coke x2', r: '£360.00'),
            const _RDiv(),
            const _RRow(l: 'Subtotal', r: '£1,840.00'),
            if (settings.showTaxBreakdown)
              const _RRow(l: 'GST 17%', r: '£312.00'),
            const _RRow(l: 'Total', r: '£2,152.00', bold: true),
            if (settings.showCashierName)
              const _RRow(l: 'Cashier', r: 'Ahmed'),
            const _RDiv(),
            Text(settings.footerText,
                style: const TextStyle(
                    fontSize: 9, color: Colors.black54),
                textAlign: TextAlign.center),
          ]),
        ),
      ],
    ),
  );
}

class _RDiv extends StatelessWidget {
  const _RDiv();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Divider(
        height: 1, thickness: 0.5, color: Color(0xFFCCCCCC)),
  );
}

class _RRow extends StatelessWidget {
  final String l, r;
  final bool bold;
  const _RRow({required this.l, required this.r, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l,
            style: TextStyle(
                fontSize: 10,
                color: Colors.black87,
                fontWeight:
                bold ? FontWeight.w700 : FontWeight.normal)),
        Text(r,
            style: TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight:
                bold ? FontWeight.w700 : FontWeight.normal)),
      ],
    ),
  );
}