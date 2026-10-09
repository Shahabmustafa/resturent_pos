import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class Field extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextInputType keyboardType;
  final int maxLines;

  const Field({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          filled: true,
          fillColor: AppColors.bg,
        ),
      ),
    ],
  );
}

class ToggleRow extends StatefulWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ToggleRow({
    super.key,
    required this.label,
    this.subtitle,
    this.value = false,
    this.onChanged,
  });

  @override
  State<ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<ToggleRow> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
              if (widget.subtitle != null)
                Text(widget.subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ),
        Switch(
          value: _val,
          onChanged: (v) {
            setState(() => _val = v);
            widget.onChanged?.call(v);
          },
          activeColor: AppColors.primary,
        ),
      ],
    ),
  );
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.border, height: 20, thickness: 0.5);
}

class PrimaryBtn extends StatelessWidget {
  final String label;
  final AppIcon? icon;
  final VoidCallback? onTap;

  const PrimaryBtn({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onTap,
    icon: icon != null ? SvgIcon(icon, size: 16) : const SizedBox.shrink(),
    label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
  );
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final AppIcon? icon;
  final VoidCallback? onTap;
  final Color? color;

  const OutlineBtn({super.key, required this.label, this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: icon != null
        ? SvgIcon(icon, size: 15, color: color ?? AppColors.textGrey)
        : const SizedBox.shrink(),
    label: Text(label, style: TextStyle(fontSize: 13, color: color ?? AppColors.textGrey)),
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: color?.withOpacity(0.4) ?? AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
  );
}