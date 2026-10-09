import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import 'package:resturent_application/core/constants/currency.dart';

// ─── Toggle Button ────────────────────────────────────────────────────────────

class ToggleBtnWidget extends StatelessWidget {
  final String     label;
  final AppIcon   icon;
  final bool       isSelected;
  final VoidCallback onTap;
  final Color      activeColor;

  const ToggleBtnWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor = kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : kLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.4) : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgIcon(icon, size: 16, color: isSelected ? activeColor : kMuted),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                  color: isSelected ? activeColor : kMuted),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─── Status Button ────────────────────────────────────────────────────────────

class StatusBtnWidget extends StatelessWidget {
  final String     label;
  final Color      color;
  final bool       isSelected;
  final VoidCallback onTap;

  const StatusBtnWidget({
    super.key,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : kLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                  color: isSelected ? color : kMuted)),
        ),
      ),
    );
  }
}

// ─── Info Field ───────────────────────────────────────────────────────────────

class InfoFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final AppIcon              icon;
  final ValueChanged<String>  onChanged;
  final TextInputType?        keyboardType;

  const InfoFieldWidget({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      onChanged:    onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: kText),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: const TextStyle(color: kMuted, fontSize: 12),
        prefixIcon: SvgIcon(icon, size: 15, color: kMuted),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        filled:    true,
        fillColor: kLight,
        isDense:   true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class SectionLabelWidget extends StatelessWidget {
  final String text;
  const SectionLabelWidget(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: kMuted, letterSpacing: 0.5));
  }
}

// ─── Bill Row ─────────────────────────────────────────────────────────────────

class BillRowWidget extends StatelessWidget {
  final String label, value;
  final bool   isGreen;

  const BillRowWidget(this.label, this.value, {super.key, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kSub)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isGreen ? kGreen : kText)),
      ]),
    );
  }
}

// ─── Order Confirm Dialog ─────────────────────────────────────────────────────

class OrderConfirmDialog extends StatelessWidget {
  final String     orderId;
  final double     total;
  final String     paymentStatus;
  final VoidCallback onConfirm;

  const OrderConfirmDialog({
    super.key,
    required this.orderId,
    required this.total,
    required this.paymentStatus,
    required this.onConfirm,
  });

  Color get _statusColor => switch (paymentStatus) {
    'Paid'    => kGreen,
    'Unpaid'  => kRed,
    _         => const Color(0xFFFFAA00),
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kGreen.withOpacity(0.1), shape: BoxShape.circle),
          child: const SvgIcon(AppIcons.receiptLongRounded, color: kGreen, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Confirm Order?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 8),
        Text(orderId, style: const TextStyle(fontSize: 14, color: kPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(color: kSub, fontSize: 13)),
            Text(formatMoney(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary)),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _statusColor.withOpacity(0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgIcon(AppIcons.circle, size: 8, color: _statusColor),
            const SizedBox(width: 6),
            Text(paymentStatus,
                style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 4),
        const Text('The order will appear in Orders',
            style: TextStyle(fontSize: 11, color: kMuted)),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: kMuted)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onConfirm,
          icon: const SvgIcon(AppIcons.sendRounded, size: 16),
          label: const Text('Place Order', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}