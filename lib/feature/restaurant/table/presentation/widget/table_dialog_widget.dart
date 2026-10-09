
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/table_model.dart';


class StatusChangeDialog extends StatefulWidget {
  final TableModel table;
  final ValueChanged<TableStatus> onChanged;
  const StatusChangeDialog(
      {super.key, required this.table, required this.onChanged});

  @override
  State<StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  late TableStatus _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.table.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('${widget.table.tableNumber} — Status',
          style: const TextStyle(
              color: kText, fontWeight: FontWeight.w800, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: TableStatus.values.map((s) {
          final isSelected = _selected == s;
          final color = s.color;
          final desc = s == TableStatus.available
              ? 'Visible and available in POS'
              : s == TableStatus.reserved
              ? 'Reserved — blocked in POS'
              : 'Cleaning in progress';

          return GestureDetector(
            onTap: () => setState(() => _selected = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.08) : kLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color.withOpacity(0.4) : kBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  SvgIcon(s.icon,
                      color: isSelected ? color : kMuted, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? color : kText,
                                fontSize: 14)),
                        Text(desc,
                            style:
                            const TextStyle(fontSize: 11, color: kMuted)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 20,
                      height: 20,
                      decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                      child: const SvgIcon(AppIcons.checkRounded,
                          size: 13, color: Colors.white),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: kMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            widget.onChanged(_selected);
            Navigator.pop(context);
          },
          child: const Text('Save',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Add Table Dialog ──────────────────────────────────────────────────────

class AddTableDialog extends StatefulWidget {
  final int nextNumber;
  final ValueChanged<TableModel> onAdd;
  const AddTableDialog(
      {super.key, required this.nextNumber, required this.onAdd});

  @override
  State<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<AddTableDialog> {
  final _numberCtrl   = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '4');
  TableFloor   _floor   = TableFloor.ground;
  TableSection _section = TableSection.indoor;
  TableStatus  _status  = TableStatus.available;

  @override
  void initState() {
    super.initState();
    _numberCtrl.text =
    'T-${widget.nextNumber.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          SvgIcon(AppIcons.addCircleRounded, color: kPrimary, size: 22),
          SizedBox(width: 8),
          Text('New Table',
              style: TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(label: 'Table Number', controller: _numberCtrl, hint: 'T-13'),
            const SizedBox(height: 14),
            _Field(
              label: 'Capacity',
              controller: _capacityCtrl,
              hint: '4',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _Dropdown<TableFloor>(
              label: 'Floor',
              value: _floor,
              items: TableFloor.values,
              labelOf: (f) => f.label,
              onChanged: (v) => setState(() => _floor = v!),
            ),
            const SizedBox(height: 14),
            _Dropdown<TableSection>(
              label: 'Section',
              value: _section,
              items: TableSection.values,
              labelOf: (s) => s.label,
              onChanged: (v) => setState(() => _section = v!),
            ),
            const SizedBox(height: 14),
            const Text('Initial Status',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kSub)),
            const SizedBox(height: 8),
            Row(
              children: TableStatus.values.map((s) {
                final isSelected = _status == s;
                final color = s.color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.1)
                            : kLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? color.withOpacity(0.4)
                                : kBorder),
                      ),
                      child: Text(s.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? color : kMuted)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_numberCtrl.text.trim().isEmpty) return;
            widget.onAdd(TableModel(
              id:          '',            // Generated by Supabase
              branchId:    '',            // Set in provider
              tableNumber: _numberCtrl.text.trim(),
              capacity:    int.tryParse(_capacityCtrl.text) ?? 4,
              floor:       _floor,
              section:     _section,
              status:      _status,
              isActive:    true,
              createdAt:   DateTime.now(),
            ));
            Navigator.pop(context);
          },
          icon: const SvgIcon(AppIcons.checkRounded, size: 16),
          label: const Text('Add Table',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Form Helpers ─────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _Field(
      {required this.label,
        required this.controller,
        required this.hint,
        this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: kSub)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(color: Color(0xFFBBBDCC), fontSize: 13),
            filled: true,
            fillColor: kLight,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: kPrimary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  const _Dropdown(
      {required this.label,
        required this.value,
        required this.items,
        required this.labelOf,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: kSub)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: kLight,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: kPrimary, width: 1.5)),
          ),
          style: const TextStyle(fontSize: 13, color: kText),
          items: items
              .map((i) =>
              DropdownMenuItem(value: i, child: Text(labelOf(i))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}