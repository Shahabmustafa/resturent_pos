import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

// ── Add Table Dialog ──────────────────────────────────────────────────────

class AddTableDialog extends StatefulWidget {
  final int nextNumber;
  final ValueChanged<String> onAdd;
  const AddTableDialog({
    super.key,
    required this.nextNumber,
    required this.onAdd,
  });

  @override
  State<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<AddTableDialog> {
  final _numberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _numberCtrl.text = 'T${widget.nextNumber}';
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_numberCtrl.text.trim().isEmpty) return;
    widget.onAdd(_numberCtrl.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Row(
        children: [
          SvgIcon(AppIcons.addCircleRounded, color: kPrimary, size: 22),
          SizedBox(width: 8),
          Text(
            'New Table',
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: _Field(
          label: 'Table Name',
          controller: _numberCtrl,
          hint: 'T13',
        ),
      ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _submit,
          icon: const SvgIcon(AppIcons.checkRounded, size: 16),
          label: const Text(
            'Add Table',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ── Form Helpers ─────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kSub,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBBDCC), fontSize: 13),
            filled: true,
            fillColor: kLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: kPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
