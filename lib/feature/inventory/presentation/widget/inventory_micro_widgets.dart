import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/inventory_model.dart';

// ─── Table Header Cell ────────────────────────────────────────────────────────

class HdrWidget extends StatelessWidget {
  final String t;
  final int flex;
  const HdrWidget(this.t, {super.key, this.flex = 1});
  @override
  Widget build(BuildContext context) => Expanded(flex: flex,
      child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted, letterSpacing: 0.2)));
}

// ─── Pill ─────────────────────────────────────────────────────────────────────

class PillWidget extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final Color color;
  const PillWidget(this.icon, this.label, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      SvgIcon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const FilterChipWidget(this.label, this.active, this.color, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : kLight,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: active ? color.withOpacity(0.4) : kBorder)),
      child: Text(label, style: TextStyle(fontSize: 12, color: active ? color : kMuted,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
    ),
  );
}

// ─── Icon Button ──────────────────────────────────────────────────────────────

class IBtnWidget extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final VoidCallback onTap;
  const IBtnWidget(this.icon, this.color, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
      child: SvgIcon(icon, size: 14, color: color),
    ),
  );
}

// ─── Toggle Button ────────────────────────────────────────────────────────────

class TogBtnWidget extends StatelessWidget {
  final String label;
  final AppIcon icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const TogBtnWidget(this.label, this.icon, this.active, this.color, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : kLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color.withOpacity(0.4) : kBorder)),
      child: Column(children: [
        SvgIcon(icon, color: active ? color : kMuted, size: 18),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11, color: active ? color : kMuted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ]),
    ),
  );
}

// ─── Input Decoration ─────────────────────────────────────────────────────────

InputDecoration dec({String hint = ''}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFBBBDCC)),
  filled: true, fillColor: kLight, isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: kBorder)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: kBorder)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
);

// ─── Field ────────────────────────────────────────────────────────────────────

Widget fieldWidget(String label, TextEditingController ctrl, String hint, {TextInputType? kt, ValueChanged<String>? onChange}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kSub)),
      const SizedBox(height: 5),
      TextField(controller: ctrl, keyboardType: kt, onChanged: onChange,
          style: const TextStyle(fontSize: 13, color: kText), decoration: dec(hint: hint)),
    ]);

// ─── Dropdown (String) ────────────────────────────────────────────────────────

Widget dropdownWidget(String label, String? val, List<String> items, ValueChanged<String?> onChanged) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kSub)),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(value: val, decoration: dec(), style: const TextStyle(fontSize: 13, color: kText),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: onChanged),
    ]);

// ─── Dropdown (Supplier int) ──────────────────────────────────────────────────

Widget dropdownIntWidget(String label, int? val, List<Supplier> suppliers, ValueChanged<int?> onChanged) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kSub)),
      const SizedBox(height: 5),
      DropdownButtonFormField<int>(value: val, decoration: dec(), style: const TextStyle(fontSize: 13, color: kText),
          items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(), onChanged: onChanged),
    ]);